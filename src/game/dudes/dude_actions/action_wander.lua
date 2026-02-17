local action_wander = {
    name = "wander",
}

function action_wander:score(dude)
    return 0.1
end

function action_wander:start(dude, brain)
    brain.action_state[self.name] = { started = false }
end

function action_wander:perform(dude, brain, dt)
    local state = brain.action_state[self.name]
    dude.status = "Wandering"

    if not state.started then
        local x, y = world:get_random_positon_in_radius(dude.entity.x, dude.entity.y, 5)
        dude.goal = {
            x = x,
            y = y
        }
        state.started = true
    end

    if dude.ai_mover:is_at_goal() then
        dude.goal = nil
        brain.pause_time = 5
        return true
    end

    return false
end

function action_wander:cancel(dude, brain)
    dude.goal = nil
end

return action_wander
