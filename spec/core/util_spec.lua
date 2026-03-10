local test_env = require("spec.support.test_env")

describe("AI utility helpers", function()
    before_each(function()
        test_env.reset_globals()
        test_env.unload_modules({
            "src.core.util",
        })
        require("src.core.util")
    end)

    it("tracks reservations and held state independently", function()
        local reserver = test_env.make_entity({ name = "dude" })
        local other = test_env.make_entity({ name = "other_dude" })
        local item = test_env.make_entity({ name = "stone" })

        assert.is_true(reserve_entity(item, reserver))
        assert.are.equal(reserver, get_entity_reserver(item))
        assert.is_true(is_entity_available(item, reserver))
        assert.is_false(is_entity_available(item, other))

        item.held_by = reserver

        assert.is_true(is_entity_held(item))
        assert.is_false(is_entity_available(item, reserver))

        assert.is_true(release_entity_reservation(item, reserver))
        assert.is_nil(item.reserved_by)
    end)

    it("clears stale reservations from invalid entities", function()
        local item = test_env.make_entity({
            name = "log",
            reserved_by = test_env.make_entity({
                name = "dead_dude",
                is_valid = false,
            }),
        })

        assert.is_nil(get_entity_reserver(item))
        assert.is_nil(item.reserved_by)
    end)

    it("finds the nearest usable interaction tile", function()
        world.astar.is_walkable = function(_, x, y)
            return x == 8 and y == 7
        end

        local actor = test_env.make_entity({ x = 2, y = 2 })
        local target = test_env.make_entity({ x = 8, y = 8 })

        assert.same({ x = 8, y = 7 }, find_best_interaction_position(target, actor, false))
    end)
end)

