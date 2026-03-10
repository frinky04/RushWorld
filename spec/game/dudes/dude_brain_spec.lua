local test_env = require("spec.support.test_env")

describe("dude_brain_component", function()
    local DudeBrainComponent

    before_each(function()
        test_env.reset_globals()
        test_env.unload_modules({
            "src.core.component",
            "src.game.dudes.dude_brain_component",
        })

        DudeBrainComponent = require("src.game.dudes.dude_brain_component")
    end)

    local function make_brain()
        local entity = test_env.make_entity()
        local brain = DudeBrainComponent:new(entity)
        brain.dude = {
            ai_mover = {
                should_move = true,
            }
        }
        return brain
    end

    local function make_action(name, options)
        local action = {
            name = name,
            min_duration = options.min_duration or 0,
            start_calls = 0,
            cancel_calls = 0,
            perform_calls = 0,
        }

        function action:score(dude)
            return options.score()
        end

        function action:start(dude, brain)
            self.start_calls = self.start_calls + 1
        end

        function action:perform(dude, brain, dt)
            self.perform_calls = self.perform_calls + 1
            return false
        end

        function action:cancel(dude, brain)
            self.cancel_calls = self.cancel_calls + 1
        end

        if options.can_interrupt then
            function action:can_interrupt(dude, brain, new_action, new_score, current_score)
                return options.can_interrupt(new_action, new_score, current_score)
            end
        end

        return action
    end

    it("respects min_duration before switching away from the current action", function()
        local scores = {
            committed = 0.8,
            challenger = 0.1,
        }

        local committed = make_action("committed", {
            min_duration = 1.0,
            score = function()
                return scores.committed
            end,
        })

        local challenger = make_action("challenger", {
            score = function()
                return scores.challenger
            end,
        })

        local brain = make_brain()
        brain.actions = { committed, challenger }

        brain:update(0.2)
        assert.are.equal(committed, brain.current_action)

        scores.committed = 0.1
        scores.challenger = 0.9

        brain:update(0.2)
        assert.are.equal(committed, brain.current_action)

        brain:update(0.6)
        assert.are.equal(committed, brain.current_action)

        brain:update(0.2)
        assert.are.equal(challenger, brain.current_action)
        assert.are.equal(1, committed.cancel_calls)
    end)

    it("lets actions veto interruption even after their minimum commitment has elapsed", function()
        local scores = {
            protected = 0.6,
            challenger = 0.5,
        }

        local protected = make_action("protected", {
            min_duration = 0.2,
            score = function()
                return scores.protected
            end,
            can_interrupt = function(new_action, new_score, current_score)
                return (new_score - current_score) >= 0.5
            end,
        })

        local challenger = make_action("challenger", {
            score = function()
                return scores.challenger
            end,
        })

        local brain = make_brain()
        brain.actions = { protected, challenger }

        brain:update(0.2)
        assert.are.equal(protected, brain.current_action)

        scores.protected = 0.4
        scores.challenger = 0.7

        brain:update(0.2)
        assert.are.equal(protected, brain.current_action)

        scores.protected = 0.1
        scores.challenger = 1.0

        brain:update(0.2)
        assert.are.equal(challenger, brain.current_action)
        assert.are.equal(1, protected.cancel_calls)
    end)
end)
