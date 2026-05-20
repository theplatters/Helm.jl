abstract type AbstractSystem <: Function end

abstract type SystemConfig end

struct QueryData{R, W, WI, WO} <: SystemConfig end
struct Mut{T} end

Mut(::Type{T}) where {T} = Mut{T}()

_unwrap_comp(::Type{T}) where {T} = (T, :read)
_unwrap_comp(::Mut{T}) where {T} = (T, :write)

_sort_comps(::Tuple{}, reads::Tuple, writes::Tuple) = (reads, writes)

function _sort_comps(comps::Tuple, reads::Tuple, writes::Tuple)
    head = comps[1]
    tail = Base.tail(comps)

    T, mode = _unwrap_comp(head)

    if mode === :read
        return _sort_comps(tail, (reads..., T), writes)
    else
        return _sort_comps(tail, reads, (writes..., T))
    end
end

function separate_reads_and_writes(comps::Tuple)
    return _sort_comps(comps, (), ())
end

function Query(comps::Tuple; with = (), without = ())
    R, W = separate_reads_and_writes(comps)
    return QueryData{Tuple{R...}, Tuple{W...}, Tuple{with...}, Tuple{without...}}()
end


function Ark.Query(
        w::Ark.World,
        ::QueryData{R_Tuple, W_Tuple, WI_Tuple, WO_Tuple}
    ) where {
        R_Tuple <: Tuple,
        W_Tuple <: Tuple,
        WI_Tuple <: Tuple,
        WO_Tuple <: Tuple,
    }
    # 1. Safely extract the data types from the Tuple type structures
    # .parameters gives us a tuple of the types inside the Tuple{...}
    r_types = R_Tuple.parameters
    w_types = W_Tuple.parameters
    wi_types = WI_Tuple.parameters
    wo_types = WO_Tuple.parameters

    # 2. Re-combine them into standard runtime values for your original Ark.Query
    comp_types = (r_types..., w_types...)

    return Ark.Query(w, comp_types; with = (wi_types...,), without = (wo_types...,))
end

Res(::Type{T}) where {T} = ResourceData{T, false}()
ResMut(::Type{T}) where {T} = ResourceData{T, true}()


struct ResourceData{D, M} <: SystemConfig end

struct System{T, C <: Tuple{Vararg{SystemConfig}}} <: AbstractSystem
    _f::T
    _configs::C
end

# If the configuration is a QueryData, instantiate the live Query object
@inline function fetch_arg(world::Ark.World, q::QueryData)
    return Ark.Query(world, q)
end

# If the configuration is a ResourceData, pull the live resource instance
@inline function fetch_arg(world::Ark.World, r::ResourceData)
    return Ark.get_resource(world, r._datatype)
end


function (sys::System)(world::Ark.World)
    # 1. Map over the configurations in their exact positional order
    runtime_args = map(sys._configs) do config
        fetch_arg(world, config)
    end

    # 2. Safely splat into the user's function
    return sys._f(runtime_args...)
end

reads(::QueryData{R, W, WI, WO}) where {R, W, WI, WO} = R
writes(::QueryData{R, W, WI, WO}) where {R, W, WI, WO} = W


reads(::ResourceData{T, false}) where {T} = (T,)
writes(::ResourceData{T, false}) where {T} = ()
writes(::ResourceData{T, true}) where {T} = (T,)

function reads(sys::System)
    r = Set{Any}()
    for q in sys._configs
        union!(r, reads(q))
    end
    return r
end

function writes(sys::System)
    r = Set{Any}()
    for q in sys._configs
        union!(r, writes(q))
    end
    return r
end
