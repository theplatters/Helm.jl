struct Schedule{N, T <: Tuple{Vararg{AbstractSystem, N}}}
    _systems::T
    _dependency_graph::Gr.SimpleDiGraph{Int64}

end

function Schedule(systems::AbstractSystem...)

    #first pass: add ids and systems

    #second pass: construct dependency graph

end

struct SystemChain{N, T <: Tuple{Vararg{AbstractSystem, N}}} <: AbstractSystem
    _systems::T
end

function chain(systems::AbstractSystem...)
    return SystemChain(systems)
end

struct SystemDependency{T <: AbstractSystem, U <: AbstractSystem} <: AbstractSystem
    _before::T
    _after::U
end

function after(s::AbstractSystem, u::AbstractSystem)
    return SystemDependency(u, s)
end

function before(s::AbstractSystem, u::AbstractSystem)
    return SystemDependency(s, u)
end

Base.length(s::SystemChain{N, T}) where {N, T} = N
Base.length(s::SystemDependency) = 1
Base.length(s::System) = 1
