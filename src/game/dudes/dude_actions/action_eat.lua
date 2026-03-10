local action_eat = {
    name = "eat",
    min_duration = 1.0,
}

local STAGE_PLAN = "plan"
local STAGE_MOVE_TO_FOOD = "move_to_food"
local STAGE_EAT = "eat"

local function urgency_curve(value, threshold)
    if value < threshold then
        return value * 0.3
    end

    return 0.3 + (value - threshold) / (1 - threshold) * 0.7
end

local function set_stage(dude, state, stage, goal)
    state.stage = stage
    dude.goal = goal
end

local function clear_food_target(dude, state)
    release_entity_reservation(state.food, dude.entity)
    state.food = nil
end

local function reset_to_planning(dude, state)
    clear_food_target(dude, state)
    set_stage(dude, state, STAGE_PLAN, nil)
end

function action_eat:score(dude)
    local need = 1 - dude.hunger / 100
    return urgency_curve(need, 0.6)
end

function action_eat:start(dude, brain)
    brain.action_state[self.name] = {
        stage = STAGE_PLAN,
        food = nil,
    }
end

function action_eat:perform(dude, brain, dt)
    local state = brain.action_state[self.name]

    if state.stage == STAGE_PLAN then
        dude.status = "Finding Food"

        local food = find_nearest_available_entity_by_name("berry_bush", dude.entity.x, dude.entity.y, dude.entity)
        if not is_valid(food) or not reserve_entity(food, dude.entity) then
            brain.pause_time = 1
            return true
        end

        state.food = food
        set_stage(dude, state, STAGE_MOVE_TO_FOOD, food)
        return false
    end

    if state.stage == STAGE_MOVE_TO_FOOD then
        dude.status = "Moving to food"

        if not is_valid(state.food) or get_entity_reserver(state.food) ~= dude.entity then
            reset_to_planning(dude, state)
            brain.pause_time = 1
            return true
        end

        if dude.ai_mover:is_at_goal() then
            set_stage(dude, state, STAGE_EAT, nil)
        end

        return false
    end

    if state.stage == STAGE_EAT then
        dude.status = "Eating"

        if not is_valid(state.food) or get_entity_reserver(state.food) ~= dude.entity then
            reset_to_planning(dude, state)
            brain.pause_time = 1
            return true
        end

        local food = state.food
        dude:eat(food)
        clear_food_target(dude, state)
        set_stage(dude, state, STAGE_PLAN, nil)
        brain.pause_time = 2
        return true
    end

    reset_to_planning(dude, state)
    return false
end

function action_eat:cancel(dude, brain)
    local state = brain.action_state[self.name]
    if state then
        clear_food_target(dude, state)
    end
    dude.goal = nil
end

return action_eat
