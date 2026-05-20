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
    r_types = R_Tuple.parameters
    w_types = W_Tuple.parameters
    wi_types = WI_Tuple.parameters
    wo_types = WO_Tuple.parameters

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

@inline function fetch_arg(world::Ark.World, q::QueryData)
    return Ark.Query(world, q)
end

@inline function fetch_arg(world::Ark.World, r::ResourceData)
    return Ark.get_resource(world, r._datatype)
end


function (sys::System)(world::Ark.World)
    runtime_args = map(sys._configs) do config
        fetch_arg(world, config)
    end

    return sys._f(runtime_args...)
end

reads(::QueryData{R, W, WI, WO}) where {R, W, WI, WO} = R
writes(::QueryData{R, W, WI, WO}) where {R, W, WI, WO} = W


reads(::ResourceData{T, false}) where {T} = (T,)
writes(::ResourceData{T, false}) where {T} = ()
writes(::ResourceData{T, true}) where {T} = (T,)

reads(::Type{QueryData{R, W, WI, WO}}) where {R, W, WI, WO} = R.parameters
writes(::Type{QueryData{R, W, WI, WO}}) where {R, W, WI, WO} = W.parameters

reads(::Type{ResourceData{D, false}}) where {D} = (D,)
reads(::Type{ResourceData{D, true}}) where {D} = ()

writes(::Type{ResourceData{D, false}}) where {D} = ()
writes(::Type{ResourceData{D, true}}) where {D} = (D,)


@generated function reads(sys::System{T, C}) where {T, C}
    all_reads = DataType[]

    for config_type in C.parameters
        for r_sym in reads(config_type)
            push!(all_reads, r_sym)
        end
    end

    unique_reads = Tuple(unique(all_reads))
    return :($unique_reads)
end


@generated function writes(sys::System{T, C}) where {T, C}
    all_writes = DataType[]

    for config_type in C.parameters
        for w_sym in writes(config_type)
            push!(all_writes, w_sym)
        end
    end

    unique_writes = Tuple(unique(all_writes))
    return :($unique_writes)
end
