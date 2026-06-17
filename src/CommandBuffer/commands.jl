import Ark: new_entity!, new_entities!, remove_entity!, remove_entities!, copy_entity!,
            add_components!, remove_components!, exchange_components!, set_relations!

# Export the functions (both with and without !)
export new_entity!, new_entities!, remove_entity!, remove_entities!, copy_entity!,
       add_components!, remove_components!, exchange_components!, set_relations!
export new_entity, new_entities, remove_entity, remove_entities, copy_entity,
       add_components, remove_components, exchange_components, set_relations
export Filter

# Custom Filter type mirroring Ark.Filter
struct Filter{CT <: Tuple, W <: Tuple, WO <: Tuple, O <: Tuple}
    comp_types::CT
    with::W
    without::WO
    optional::O
    exclusive::Bool
end

function Filter(
    comp_types::Tuple;
    with::Tuple=(),
    without::Tuple=(),
    optional::Tuple=(),
    exclusive::Bool=false,
)
    return Filter(comp_types, with, without, optional, exclusive)
end

function Filter(
    world,
    comp_types::Tuple;
    with::Tuple=(),
    without::Tuple=(),
    optional::Tuple=(),
    exclusive::Bool=false,
    register::Bool=false,
)
    return Filter(comp_types, with, without, optional, exclusive)
end

# Command structs

struct Spawn{C <: Tuple} <: AbstractCommand
    components::C
end
Spawn(comps...) = Spawn(comps)

struct SpawnMultiple{C <: Tuple} <: AbstractCommand
    count::Int
    components::C
end

struct SpawnMultipleWithGenerator{F, C <: Tuple} <: AbstractCommand
    count::Int
    components::C
    generator::F
end

struct Despawn <: AbstractCommand
    entity::Ark.Entity
end

struct DespawnMultiple{F} <: AbstractCommand
    filter::F
end

struct DespawnMultipleWithCallback{F, Fn} <: AbstractCommand
    filter::F
    callback::Fn
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

struct AddComponentsMultiple{F, C <: Tuple} <: AbstractCommand
    filter::F
    components::C
end

struct AddComponentsMultipleWithGenerator{F, C <: Tuple, Fn} <: AbstractCommand
    filter::F
    components::C
    generator::Fn
end

struct RemoveComponents{C <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    components::C
end

struct RemoveComponentsMultiple{F, C <: Tuple} <: AbstractCommand
    filter::F
    components::C
end

struct RemoveComponentsMultipleWithCallback{F, C <: Tuple, Fn} <: AbstractCommand
    filter::F
    components::C
    callback::Fn
end

struct ExchangeComponent{A <: Tuple, R <: Tuple} <: AbstractCommand
    entity::Ark.Entity
    add::A
    remove::R
end

struct ExchangeComponentMultiple{F, A <: Tuple, R <: Tuple} <: AbstractCommand
    filter::F
    add::A
    remove::R
end

struct ExchangeComponentMultipleWithGenerator{F, A <: Tuple, R <: Tuple, Fn} <: AbstractCommand
    filter::F
    add::A
    remove::R
    generator::Fn
end

struct SetRelationsMultiple{F, R <: Tuple} <: AbstractCommand
    filter::F
    relations::R
end

struct SetRelationsMultipleWithCallback{F, R <: Tuple, Fn} <: AbstractCommand
    filter::F
    relations::R
    callback::Fn
end

# API implementation for CommandBuffer

# 1. new_entity!
function Ark.new_entity!(cmd::CommandBuffer, values::Tuple=())
    return push_cmd(cmd, Spawn(values))
end

# 2. new_entities!
function Ark.new_entities!(cmd::CommandBuffer, n::Int, components::Tuple)
    return push_cmd(cmd, SpawnMultiple(n, components))
end

function Ark.new_entities!(fn::Fn, cmd::CommandBuffer, n::Int, components::Tuple) where {Fn}
    return push_cmd(cmd, SpawnMultipleWithGenerator(n, components, fn))
end

# 3. copy_entity!
function Ark.copy_entity!(cmd::CommandBuffer, entity::Ark.Entity; add::Tuple=(), remove::Tuple=(), mode::Symbol=:copy)
    return push_cmd(cmd, CopyEntity(entity, add, remove, mode))
end

# 4. remove_entity!
function Ark.remove_entity!(cmd::CommandBuffer, entity::Ark.Entity)
    return push_cmd(cmd, Despawn(entity))
end

# 5. remove_entities!
function Ark.remove_entities!(cmd::CommandBuffer, filter)
    return push_cmd(cmd, DespawnMultiple(filter))
end

function Ark.remove_entities!(fn::Fn, cmd::CommandBuffer, filter) where {Fn}
    return push_cmd(cmd, DespawnMultipleWithCallback(filter, fn))
end

# 6. add_components!
function Ark.add_components!(cmd::CommandBuffer, entity::Ark.Entity, values::Tuple)
    return push_cmd(cmd, AddComponents(entity, values))
end

function Ark.add_components!(cmd::CommandBuffer, filter, add::Tuple)
    return push_cmd(cmd, AddComponentsMultiple(filter, add))
end

function Ark.add_components!(fn::Fn, cmd::CommandBuffer, filter, add::Tuple) where {Fn}
    return push_cmd(cmd, AddComponentsMultipleWithGenerator(filter, add, fn))
end

# 7. remove_components!
function Ark.remove_components!(cmd::CommandBuffer, entity::Ark.Entity, comp_types::Tuple)
    return push_cmd(cmd, RemoveComponents(entity, comp_types))
end

function Ark.remove_components!(cmd::CommandBuffer, filter, remove::Tuple)
    return push_cmd(cmd, RemoveComponentsMultiple(filter, remove))
end

function Ark.remove_components!(fn::Fn, cmd::CommandBuffer, filter, remove::Tuple) where {Fn}
    return push_cmd(cmd, RemoveComponentsMultipleWithCallback(filter, remove, fn))
end

# 8. exchange_components!
function Ark.exchange_components!(cmd::CommandBuffer, entity::Ark.Entity; add::Tuple=(), remove::Tuple=())
    return push_cmd(cmd, ExchangeComponent(entity, add, remove))
end

function Ark.exchange_components!(cmd::CommandBuffer, filter; add::Tuple=(), remove::Tuple=())
    return push_cmd(cmd, ExchangeComponentMultiple(filter, add, remove))
end

function Ark.exchange_components!(fn::Fn, cmd::CommandBuffer, filter; add::Tuple=(), remove::Tuple=()) where {Fn}
    return push_cmd(cmd, ExchangeComponentMultipleWithGenerator(filter, add, remove, fn))
end

# 9. set_relations!
function Ark.set_relations!(cmd::CommandBuffer, filter, relations::Tuple)
    return push_cmd(cmd, SetRelationsMultiple(filter, relations))
end

function Ark.set_relations!(fn::Fn, cmd::CommandBuffer, filter, relations::Tuple) where {Fn}
    return push_cmd(cmd, SetRelationsMultipleWithCallback(filter, relations, fn))
end

# Aliases without !
const new_entity = new_entity!
const new_entities = new_entities!
const remove_entity = remove_entity!
const remove_entities = remove_entities!
const copy_entity = copy_entity!
const add_components = add_components!
const remove_components = remove_components!
const exchange_components = exchange_components!
const set_relations = set_relations!
