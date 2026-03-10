local action_idle = {
    name = "idle",
    min_duration = 0,
}

function action_idle:score(dude)
    return 0.05
end

function action_idle:start(dude, brain)
    brain.action_state[self.name] = {}
    dude.status = "Idling"
    dude.goal = nil
end

function action_idle:perform(dude, brain, dt)
    dude.status = "Idling"
    return false
end

function action_idle:cancel(dude, brain)
    -- nothing to clean up
end

return action_idle
