abstract type AbstractCommand end
struct Spawn{C <: Tuple} <: AbstractCommand
    components::C
end

function Ark.new_entity!(cmd::CommandBuffer, values::Tuple)
    return push_cmd(cmd, Spawn(values))
end

struct SpawnMultiple{C <: Tuple} <: AbstractCommand

    count::Int
    components::C
end

struct SpawnMultipleWithGenerator{F <: Function, C <: Tuple{DataType}} <: AbstractCommand
    count::Int
    components::C
    generator::F
end

Spawn(comps...) = Spawn(comps)

struct Despawn <: AbstractCommand
    entity::Ark.Entity
end

#TODO: Replace with Helm type
struct DespawnMultiple <: AbstractCommand
    filter::Ark.Filter
end

struct CopyEntity{A <: Tuple, R <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    add::A
    remove::R
    mode::Symbol
end


struct AddComponents{C <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    components::C
end

struct RemoveComponents{C <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    components::C
end

struct ExchangeComponent{A <: Tuple, R <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    add::A
    remove::R
end

struct ExchangeComponentMultiple{A <: Tuple, R <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    filter::Ark.Filter
    add::A
    remove::R
end

struct ExchangeComponentMultipleWithGenerator{A <: Tuple, R <: Tuple, F <: Function} <: AbstractCommand
    entity::Ark.Entity
    filter::Ark.Filter
    generator::F
    add::A
    remove::R
end
