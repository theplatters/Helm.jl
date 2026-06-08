module Helm
import Ark
import Graphs as Gr

export @system, Schedule, after, before, chain, get_execution_order
export CommandBuffer, Mut, Query, Res, ResMut

include("SystemConfigs/system_configs.jl")
include("SystemConfigs/query.jl")
include("SystemConfigs/resource.jl")
include("SystemConfigs/commands.jl")

include("CommandBuffer/byte_stream.jl")
include("CommandBuffer/buffer.jl")
include("CommandBuffer/commands.jl")

include("systems.jl")
include("schedule.jl")
include("scheduler.jl")


struct ComponentRegistry{T <: Tuple} end

ComponentRegistry(types::DataType...) = ComponentRegistry{Tuple{types...}}()

@generated function get_tag(::ComponentRegistry{T}, ::Type{ComponentType}) where {T, ComponentType}
    # Get the list of types from the registry
    types = T.parameters

    # Find the index of the component (this happens at compile time!)
    idx = findfirst(==(ComponentType), types)

    if idx === nothing
        return :(error("Component type ", ComponentType, " was not registered!"))
    end

    # The index becomes our 1-byte tag. We return it as a constant.
    tag = UInt8(idx)
    return :($tag)
end

struct HelmsWorld{CS, CT, ST, N, M, T}
    world::Ark.World{CS, CT, ST, N, M}
    component_registry::T
end


end # module Helmsman
