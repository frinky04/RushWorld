local test_env = require("spec.support.test_env")

describe("action_work", function()
    local action_work

    before_each(function()
        test_env.reset_globals()
        test_env.unload_modules({
            "src.core.util",
            "src.game.dudes.dude_actions.action_work",
        })

        require("src.core.util")
        action_work = require("src.game.dudes.dude_actions.action_work")
    end)

    it("plans, reserves, picks up, and delivers a material", function()
        local required_material = "stone"
        local delivered = {}

        local building_component = test_env.make_component(BuildingComponent, {
            get_next_material = function()
                return required_material
            end,
            add_material = function(_, resource)
                table.insert(delivered, resource.name)
                required_material = nil
            end,
        })

        local work = test_env.make_entity({
            name = "wall",
            x = 10,
            y = 10,
            components = { building_component },
        })

        local material = test_env.make_entity({
            name = "stone",
            x = 4,
            y = 4,
        })

        world.entities = { work, material }

        _G.dude_manager = {
            find_component_of_type = function()
                return {
                    find_free_work = function()
                        return work
                    end
                }
            end
        }

        local mover_at_goal = false
        local dude = {
            entity = test_env.make_entity({
                name = "dude",
                x = 1,
                y = 1,
            }),
            ai_mover = {
                is_at_goal = function()
                    return mover_at_goal
                end
            },
            work = nil,
            goal = nil,
            held = nil,
            status = nil,
        }

        local brain = { action_state = {} }

        action_work:start(dude, brain)

        assert.is_false(action_work:perform(dude, brain, 0.2))
        assert.are.equal("move_to_material", brain.action_state[action_work.name].stage)
        assert.are.equal(material, brain.action_state[action_work.name].material)
        assert.are.equal(dude.entity, material.reserved_by)
        assert.are.equal(material, dude.goal)

        mover_at_goal = true
        assert.is_false(action_work:perform(dude, brain, 0.2))
        assert.are.equal(material, dude.held)
        assert.are.equal("plan", brain.action_state[action_work.name].stage)
        assert.are.equal(material, brain.action_state[action_work.name].material)
        assert.is_nil(dude.goal)

        mover_at_goal = false
        assert.is_false(action_work:perform(dude, brain, 0.2))
        assert.are.equal("move_to_delivery", brain.action_state[action_work.name].stage)
        assert.are_not.equal(nil, brain.action_state[action_work.name].delivery_pos)

        dude.entity.x = 10
        dude.entity.y = 9
        assert.is_false(action_work:perform(dude, brain, 0.2))
        assert.is_nil(dude.held)
        assert.is_true(material.destroyed)
        assert.same({ "stone" }, delivered)
        assert.are.equal("plan", brain.action_state[action_work.name].stage)
    end)
end)
