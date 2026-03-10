local action_sleep = {
    name = "sleep",
    min_duration = 1.5,
}

local MIN_SLEEP_DURATION = 1.5
local SLEEP_START_THRESHOLD = 20
local SLEEP_END_THRESHOLD = 80

local function urgency_curve(value, threshold)
    if value < threshold then
        return value * 0.3
    end

    return 0.3 + (value - threshold) / (1 - threshold) * 0.7
end

function action_sleep:score(dude)
    if dude.tiredness > SLEEP_START_THRESHOLD then
        return 0
    end

    local need = 1 - dude.tiredness / 100
    return urgency_curve(need, 0.9)
end

function action_sleep:start(dude, brain)
    brain.action_state[self.name] = {
        sleep_time = 0,
    }
    dude.goal = nil
end

function action_sleep:perform(dude, brain, dt)
    local state = brain.action_state[self.name]
    dude.status = "Sleeping"
    dude.goal = nil

    state.sleep_time = state.sleep_time + dt
    dude:sleep(dt)

    if state.sleep_time >= MIN_SLEEP_DURATION and dude.tiredness >= SLEEP_END_THRESHOLD then
        return true
    end

    return false
end

function action_sleep:can_interrupt(dude, brain, new_action, new_score, current_score)
    if dude.tiredness >= SLEEP_END_THRESHOLD then
        return true
    end

    return new_score >= 0.95
end

function action_sleep:cancel(dude, brain)
    dude.goal = nil
end

return action_sleep
