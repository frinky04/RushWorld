local action_work = {
    name = "work",
}

function action_work:score(dude)
    -- if already working on something, keep scoring high
    if is_valid(dude.work) then
        return 0.4
    end

    -- check if there's work available
    local work = dude_manager:find_component_of_type(DudeManagerComponent):find_free_work()
    if is_valid(work) then
        return 0.4
    end

    return 0
end

function action_work:start(dude, brain)
    brain.action_state[self.name] = {
        started = false,
        resource = nil,
        harvest = nil,
        material = nil,
    }
end

function action_work:perform(dude, brain, dt)
    local state = brain.action_state[self.name]

    -- check if building is complete or no longer valid
    if not is_valid(dude.work) or not is_valid_component(get_building_component(dude.work)) then
        dude.goal = nil
        dude.work = nil
        state.harvest = nil
        state.material = nil
        brain.pause_time = 1
        return true
    end

    dude.status = "Working"

    if not state.started then
        if dude.work == nil then
            dude.work = dude_manager:find_component_of_type(DudeManagerComponent):find_free_work()
        end

        if dude.work == nil then
            return false
        end

        local material_needed = get_building_component(dude.work):get_next_material()
        state.material = world:find_nearest_entity_by_name(material_needed, dude.entity.x, dude.entity.y)

        if not is_valid(state.material) then
            state.harvest = find_closest_resource_that_drops_item(material_needed, dude.entity.x, dude.entity.y)
        end

        if not is_valid(state.material) and not is_valid(state.harvest) then
            brain.pause_time = 1
            dude.status = "No resources found"
            return true
        end

        if is_valid(state.material) and state.material == dude.held then
            local close = world.astar:find_closest_valid_position({dude.work.x, dude.work.y}, true)
            dude.goal = close
        elseif is_valid(state.material) then
            dude.goal = state.material
        elseif is_valid(state.harvest) then
            dude.goal = state.harvest
        end

        state.started = true
    end

    if dude.ai_mover:is_at_goal() then
        if is_valid(state.material) and state.material == dude.held then
            print("Delivering... ", state.material.name)
            get_building_component(dude.work):add_material(state.material)
            dude.held:destroy()
            dude.held = nil
            state.started = false
            return false
        end

        if is_valid(state.harvest) then
            print("Harvesting... ", state.harvest.name)
            damage_entity(state.harvest, 50)
            state.started = false
            brain.pause_time = 2
            return false
        end

        if is_valid(state.material) then
            dude.held = state.material
            state.started = false
            return false
        end

        dude.work = nil
        state.harvest = nil
        state.material = nil
        return true
    end

    return false
end

function action_work:cancel(dude, brain)
    dude.goal = nil
    -- don't clear dude.work so it can be resumed
end

return action_work
