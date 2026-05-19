struct Schedule{N, T <: Tuple{Vararg{AbstractSystem, N}}}
    _systems::T
    _dependency_graph::Gr.SimpleDiGraph{Int64}
    _execution_order::Vector{Int}
end

function extract_unique_systems!(sys::System, flat_list, id_map)
    return if !haskey(id_map, sys)
        push!(flat_list, sys)
        id_map[sys] = length(flat_list) # ID is simply its index in the flat list
    end
end

function extract_unique_systems!(chain::SystemChain, flat_list, id_map)
    for s in chain._systems
        extract_unique_systems!(s, flat_list, id_map)
    end
    return
end

function extract_unique_systems!(dep::SystemDependency, flat_list, id_map)
    extract_unique_systems!(dep._before, flat_list, id_map)
    return extract_unique_systems!(dep._after, flat_list, id_map)
end
# Helper to build edges. Returns (entry_nodes, exit_nodes) for any block
function build_edges!(sys::System, graph, id_map)
    id = id_map[sys]
    return ([id], [id])
end

function build_edges!(chain::SystemChain, graph, id_map)
    entries = Int[]
    prev_exits = Int[]

    for (i, s) in enumerate(chain._systems)
        curr_entries, curr_exits = build_edges!(s, graph, id_map)

        if i == 1
            entries = curr_entries
        end

        # Connect all exits of the previous block to all entries of this block
        for u in prev_exits
            for v in curr_entries
                Gr.add_edge!(graph, u, v)
            end
        end
        prev_exits = curr_exits
    end

    return (entries, prev_exits)
end

function build_edges!(dep::SystemDependency, graph, id_map)
    before_entries, before_exits = build_edges!(dep._before, graph, id_map)
    after_entries, after_exits = build_edges!(dep._after, graph, id_map)

    # Wire `before` -> `after`
    for u in before_exits
        for v in after_entries
            Gr.add_edge!(graph, u, v)
        end
    end

    return (before_entries, after_exits)
end

function Schedule(systems::AbstractSystem...)

    flat_list = System[]
    id_map = IdDict{System, Int}()

    # First Pass: Extract all unique leaf systems and assign IDs
    for s in systems
        extract_unique_systems!(s, flat_list, id_map)
    end

    #second pass: construct dependency graph
    graph = Gr.SimpleDiGraph{Int}(length(flat_list))


    for s in systems
        build_edges!(s, graph, id_map)
    end


    sorted_ids = Gr.topological_sort_by_dfs(graph)

    return Schedule(Tuple(flat_list), graph, sorted_ids)
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

function get_execution_order(schedule::Schedule)
    # This reads the graph edges and returns a valid sequence of IDs
    sorted_ids = Gr.topological_sort_by_dfs(schedule._dependency_graph)

    # Map the IDs back to the actual systems using our flat_list
    return [schedule._systems[id] for id in sorted_ids]
end
