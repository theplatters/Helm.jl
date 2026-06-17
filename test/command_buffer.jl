using Test
using Helm
using Ark

struct CompA end
struct CompB end

@testset "Command Buffer API" begin
    # Create empty CommandBuffer
    cb = CommandBuffer()
    @test length(cb.data) == 0

    # 1. new_entity! / new_entity
    cb = new_entity(cb)
    @test length(cb.data) == 1
    @test cb.data[1] isa Helm.Spawn
    @test cb.data[1].components == ()

    cb = new_entity!(cb, (CompA(), CompB()))
    @test length(cb.data) == 2
    @test cb.data[2] isa Helm.Spawn
    @test cb.data[2].components == (CompA(), CompB())

    # 2. new_entities! / new_entities
    cb = new_entities(cb, 10, (CompA, CompB))
    @test length(cb.data) == 3
    @test cb.data[3] isa Helm.SpawnMultiple
    @test cb.data[3].count == 10
    @test cb.data[3].components == (CompA, CompB)

    cb = new_entities!(cb, 5, (CompA, CompB)) do (entities, as, bs)
        # generator
    end
    @test length(cb.data) == 4
    @test cb.data[4] isa Helm.SpawnMultipleWithGenerator
    @test cb.data[4].count == 5
    @test cb.data[4].components == (CompA, CompB)

    # 3. copy_entity! / copy_entity
    ent = zero_entity
    cb = copy_entity(cb, ent, add=(CompA(),), remove=(CompB,), mode=:copy)
    @test length(cb.data) == 5
    @test cb.data[5] isa Helm.CopyEntity
    @test cb.data[5].entity == ent
    @test cb.data[5].add == (CompA(),)
    @test cb.data[5].remove == (CompB,)
    @test cb.data[5].mode == :copy

    # 4. remove_entity! / remove_entity
    cb = remove_entity(cb, ent)
    @test length(cb.data) == 6
    @test cb.data[6] isa Helm.Despawn
    @test cb.data[6].entity == ent

    # 5. remove_entities! / remove_entities
    filter = Helm.Filter((CompA,))
    cb = remove_entities(cb, filter)
    @test length(cb.data) == 7
    @test cb.data[7] isa Helm.DespawnMultiple
    @test cb.data[7].filter == filter

    cb = remove_entities!(cb, filter) do entities
        # callback
    end
    @test length(cb.data) == 8
    @test cb.data[8] isa Helm.DespawnMultipleWithCallback
    @test cb.data[8].filter == filter

    # 6. add_components! / add_components
    cb = add_components(cb, ent, (CompA(),))
    @test length(cb.data) == 9
    @test cb.data[9] isa Helm.AddComponents
    @test cb.data[9].entity == ent
    @test cb.data[9].components == (CompA(),)

    cb = add_components!(cb, filter, (CompB,))
    @test length(cb.data) == 10
    @test cb.data[10] isa Helm.AddComponentsMultiple
    @test cb.data[10].filter == filter
    @test cb.data[10].components == (CompB,)

    cb = add_components!(cb, filter, (CompB,)) do (entities, bs)
        # callback
    end
    @test length(cb.data) == 11
    @test cb.data[11] isa Helm.AddComponentsMultipleWithGenerator
    @test cb.data[11].filter == filter
    @test cb.data[11].components == (CompB,)

    # 7. remove_components! / remove_components
    cb = remove_components(cb, ent, (CompA,))
    @test length(cb.data) == 12
    @test cb.data[12] isa Helm.RemoveComponents
    @test cb.data[12].entity == ent
    @test cb.data[12].components == (CompA,)

    cb = remove_components!(cb, filter, (CompB,))
    @test length(cb.data) == 13
    @test cb.data[13] isa Helm.RemoveComponentsMultiple
    @test cb.data[13].filter == filter
    @test cb.data[13].components == (CompB,)

    cb = remove_components!(cb, filter, (CompB,)) do entities
        # callback
    end
    @test length(cb.data) == 14
    @test cb.data[14] isa Helm.RemoveComponentsMultipleWithCallback
    @test cb.data[14].filter == filter
    @test cb.data[14].components == (CompB,)

    # 8. exchange_components! / exchange_components
    cb = exchange_components(cb, ent, add=(CompA(),), remove=(CompB,))
    @test length(cb.data) == 15
    @test cb.data[15] isa Helm.ExchangeComponent
    @test cb.data[15].entity == ent
    @test cb.data[15].add == (CompA(),)
    @test cb.data[15].remove == (CompB,)

    cb = exchange_components!(cb, filter, add=(CompA(),), remove=(CompB,))
    @test length(cb.data) == 16
    @test cb.data[16] isa Helm.ExchangeComponentMultiple
    @test cb.data[16].filter == filter
    @test cb.data[16].add == (CompA(),)
    @test cb.data[16].remove == (CompB,)

    cb = exchange_components!(cb, filter, add=(CompA,), remove=(CompB,)) do (entities, as)
        # callback
    end
    @test length(cb.data) == 17
    @test cb.data[17] isa Helm.ExchangeComponentMultipleWithGenerator
    @test cb.data[17].filter == filter
    @test cb.data[17].add == (CompA,)
    @test cb.data[17].remove == (CompB,)

    # 9. set_relations! / set_relations
    cb = set_relations(cb, filter, (CompA => ent,))
    @test length(cb.data) == 18
    @test cb.data[18] isa Helm.SetRelationsMultiple
    @test cb.data[18].filter == filter
    @test cb.data[18].relations == (CompA => ent,)

    cb = set_relations!(cb, filter, (CompA => ent,)) do entities
        # callback
    end
    @test length(cb.data) == 19
    @test cb.data[19] isa Helm.SetRelationsMultipleWithCallback
    @test cb.data[19].filter == filter
    @test cb.data[19].relations == (CompA => ent,)

    # Concreteness & type stability check
    @test isconcretetype(typeof(cb))
    for cmd in cb.data
        @test isconcretetype(typeof(cmd))
    end
end
