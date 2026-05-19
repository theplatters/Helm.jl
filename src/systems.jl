abstract type AbstractSystem <: Function end
s""

struct QueryData{R, W, WI, WO}
    _reads::R
    _writes::W
    _with::WI
    _without::WO
end


struct ResourceData{D}
    _is_mutable::Bool
    _datatype::D
end

# 1. System is fully concrete when T is determined
struct System{T, Q <: Tuple{Vararg{QueryData}}, R <: Tuple{Vararg{ResourceData}}} <: AbstractSystem
    _f::T
    _queries::Q
    _resources::R
    _need_command_bufer::Bool
end


function (sys::System)(world::Ark.World)
    return sys._f(world)
end
