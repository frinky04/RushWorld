local action_work = {
    name = "work",
}

local STAGE_PLAN = "plan"
local STAGE_MOVE_TO_MATERIAL = "move_to_material"
local STAGE_MOVE_TO_HARVEST = "move_to_harvest"
local STAGE_MOVE_TO_DELIVERY = "move_to_delivery"

local function set_stage(dude, state, stage, goal)
    state.stage = stage
    dude.goal = goal
end

local function clear_work_targets(dude, state, keep_held_material)
    local keep_material = keep_held_material == true and state.material == dude.held

    if not keep_material then
        release_entity_reservation(state.material, dude.entity)
        state.material = nil
    end

    release_entity_reservation(state.harvest, dude.entity)
    state.harvest = nil
    state.delivery_pos = nil
end

local function reset_to_planning(dude, state, keep_held_material)
    clear_work_targets(dude, state, keep_held_material)
    set_stage(dude, state, STAGE_PLAN, nil)
end

local function find_delivery_position(dude, work)
    local position = find_best_interaction_position(work, dude.entity, false)
    if position == nil then
        position = find_best_interaction_position(work, dude.entity, true)
    end

    return position
end

local function assign_work_if_needed(dude)
    if is_valid(dude.work) then
        return dude.work
    end

    dude.work = dude_manager:find_component_of_type(DudeManagerComponent):find_free_work()
    return dude.work
end

local function plan_work_step(dude, state, brain)
    local building_component = get_building_component(dude.work)
    local material_needed = building_component:get_next_material()

    if material_needed == nil then
        dude.work = nil
        reset_to_planning(dude, state, false)
        return true
    end

    if is_valid(dude.held) and dude.held.name == material_needed then
        state.material = dude.held
        state.delivery_pos = find_delivery_position(dude, dude.work)
        if state.delivery_pos == nil then
            brain.pause_time = 1
            dude.status = "No delivery position"
            return true
        end

        set_stage(dude, state, STAGE_MOVE_TO_DELIVERY, state.delivery_pos)
        return false
    end

    clear_work_targets(dude, state, false)

    local material = find_nearest_available_entity_by_name(material_needed, dude.entity.x, dude.entity.y, dude.entity)
    if is_valid(material) and reserve_entity(material, dude.entity) then
        state.material = material
        set_stage(dude, state, STAGE_MOVE_TO_MATERIAL, material)
        return false
    end

    local harvest = find_closest_available_resource_that_drops_item(material_needed, dude.entity.x, dude.entity.y,
        dude.entity)
    if is_valid(harvest) and reserve_entity(harvest, dude.entity) then
        state.harvest = harvest
        set_stage(dude, state, STAGE_MOVE_TO_HARVEST, harvest)
        return false
    end

    brain.pause_time = 1
    dude.status = "No resources found"
    return true
end

local function update_move_to_material(dude, state)
    dude.status = "Fetching Material"

    if not is_valid(state.material) or get_entity_reserver(state.material) ~= dude.entity or is_entity_held(state.material) then
        reset_to_planning(dude, state, false)
        return false
    end

    if dude.ai_mover:is_at_goal() then
        dude.held = state.material
        reset_to_planning(dude, state, true)
    end

    return false
end

local function update_move_to_harvest(dude, state, brain)
    dude.status = "Harvesting Resource"

    if not is_valid(state.harvest) or get_entity_reserver(state.harvest) ~= dude.entity then
        reset_to_planning(dude, state, false)
        return false
    end

    if dude.ai_mover:is_at_goal() then
        local harvest_target = state.harvest
        release_entity_reservation(harvest_target, dude.entity)
        state.harvest = nil
        damage_entity(harvest_target, 50)
        reset_to_planning(dude, state, false)
        brain.pause_time = 2
    end

    return false
end

local function update_move_to_delivery(dude, state)
    dude.status = "Delivering Material"

    if not is_valid(dude.work) then
        reset_to_planning(dude, state, false)
        dude.work = nil
        return false
    end

    if not is_valid(dude.held) or dude.held ~= state.material then
        reset_to_planning(dude, state, false)
        return false
    end

    if is_position_at_or_adjacent(dude.entity.x, dude.entity.y, dude.work.x, dude.work.y) then
        local delivered_item = dude.held
        get_building_component(dude.work):add_material(delivered_item)
        dude.held = nil
        delivered_item:destroy()
        reset_to_planning(dude, state, false)
        return false
    end

    state.delivery_pos = find_delivery_position(dude, dude.work)
    if state.delivery_pos == nil then
        dude.goal = nil
        return false
    end

    dude.goal = state.delivery_pos
    return false
end

function action_work:score(dude)
    if is_valid(dude.work) then
        return 0.4
    end

    local work = dude_manager:find_component_of_type(DudeManagerComponent):find_free_work()
    if is_valid(work) then
        return 0.4
    end

    return 0
end

function action_work:start(dude, brain)
    brain.action_state[self.name] = {
        stage = STAGE_PLAN,
        material = nil,
        harvest = nil,
        delivery_pos = nil,
    }
end

function action_work:perform(dude, brain, dt)
    local state = brain.action_state[self.name]

    dude.status = "Working"

    if not is_valid(assign_work_if_needed(dude)) then
        reset_to_planning(dude, state, false)
        brain.pause_time = 1
        return true
    end

    if not is_valid_component(get_building_component(dude.work)) then
        dude.work = nil
        reset_to_planning(dude, state, false)
        brain.pause_time = 1
        return true
    end

    if state.stage == STAGE_PLAN then
        return plan_work_step(dude, state, brain)
    end

    if state.stage == STAGE_MOVE_TO_MATERIAL then
        return update_move_to_material(dude, state)
    end

    if state.stage == STAGE_MOVE_TO_HARVEST then
        return update_move_to_harvest(dude, state, brain)
    end

    if state.stage == STAGE_MOVE_TO_DELIVERY then
        return update_move_to_delivery(dude, state)
    end

    reset_to_planning(dude, state, false)
    return false
end

function action_work:cancel(dude, brain)
    local state = brain.action_state[self.name]
    if state then
        clear_work_targets(dude, state, true)
    end
    dude.goal = nil
end

return action_work
