local action_eat = {
    name = "eat",
}

local function urgency_curve(value, threshold)
    if value < threshold then return value * 0.3 end
    return 0.3 + (value - threshold) / (1 - threshold) * 0.7
end

function action_eat:score(dude)
    -- hunger goes from 100 (full) to 0 (starving)
    -- urgency rises as hunger drops below 40
    local need = 1 - dude.hunger / 100
    return urgency_curve(need, 0.6)
end

function action_eat:start(dude, brain)
    brain.action_state[self.name] = { started = false }
end

function action_eat:perform(dude, brain, dt)
    local state = brain.action_state[self.name]
    dude.status = "Finding Food"

    if not state.started then
        local food = world:find_nearest_entity_by_name("berry_bush", dude.entity.x, dude.entity.y)
        if is_valid(food) then
            dude.goal = food
            state.started = true
        else
            brain.pause_time = 1
            return true
        end
    end

    dude.status = "Moving to food"

    if not is_valid(dude.goal) then
        dude.goal = nil
        brain.pause_time = 1
        return true
    end

    if dude.ai_mover:is_at_goal() then
        dude:eat(dude.goal)
        brain.pause_time = 2
        return true
    end

    return false
end

function action_eat:cancel(dude, brain)
    dude.goal = nil
end

return action_eat
