local test_env = require("spec.support.test_env")

describe("action_sleep", function()
    local action_sleep

    before_each(function()
        test_env.reset_globals()
        test_env.unload_modules({
            "src.game.dudes.dude_actions.action_sleep",
        })

        action_sleep = require("src.game.dudes.dude_actions.action_sleep")
    end)

    it("scores higher as tiredness gets lower", function()
        assert.are.equal(0, action_sleep:score({ tiredness = 65 }))
        assert.are.equal(0, action_sleep:score({ tiredness = 21 }))
        assert.is_true(action_sleep:score({ tiredness = 20 }) > 0)
        assert.is_true(action_sleep:score({ tiredness = 10 }) > action_sleep:score({ tiredness = 90 }))
        assert.is_true(action_sleep:score({ tiredness = 0 }) > 0.9)
        assert.is_true(action_sleep:score({ tiredness = 10 }) > action_sleep:score({ tiredness = 20 }))
    end)

    it("sleeps in place until enough tiredness is recovered", function()
        local dude = {
            tiredness = 60,
            goal = { x = 10, y = 10 },
            status = nil,
            sleep = function(self, dt)
                self.tiredness = math.min(100, self.tiredness + (dt * 20))
            end,
        }

        local brain = {
            action_state = {},
        }

        action_sleep:start(dude, brain)
        assert.is_nil(dude.goal)

        assert.is_false(action_sleep:perform(dude, brain, 0.2))
        assert.are.equal("Sleeping", dude.status)
        assert.is_nil(dude.goal)

        assert.is_false(action_sleep:perform(dude, brain, 0.6))
        assert.is_true(dude.tiredness > 60)

        assert.is_true(action_sleep:perform(dude, brain, 0.8))
    end)

    it("only allows interruption early for extremely urgent actions", function()
        local dude = {
            tiredness = 40,
        }

        assert.is_false(action_sleep:can_interrupt(dude, {}, {}, 0.8, 0.7))
        assert.is_true(action_sleep:can_interrupt(dude, {}, {}, 0.95, 0.7))

        dude.tiredness = 90
        assert.is_true(action_sleep:can_interrupt(dude, {}, {}, 0.2, 0.1))
    end)
end)
