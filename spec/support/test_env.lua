local test_env = {}

function test_env.unload_modules(modules)
    for _, module_name in ipairs(modules) do
        package.loaded[module_name] = nil
    end
end

function test_env.make_component(class, fields)
    local component = fields or {}
    component.__class = class
    if component.is_valid == nil then
        component.is_valid = true
    end
    return component
end

function test_env.make_entity(fields)
    local entity = {}

    if fields then
        for key, value in pairs(fields) do
            entity[key] = value
        end
    end

    entity.name = entity.name or "entity"
    entity.x = entity.x or 0
    entity.y = entity.y or 0
    entity.components = entity.components or {}
    if entity.is_valid == nil then
        entity.is_valid = true
    end

    function entity:add_component(component)
        table.insert(self.components, component)
        return component
    end

    function entity:remove_component(component)
        for index, other in ipairs(self.components) do
            if other == component then
                table.remove(self.components, index)
                break
            end
        end
    end

    function entity:find_component_of_type(class)
        for _, component in ipairs(self.components) do
            if component.is_valid and component.__class == class then
                return component
            end
        end

        return nil
    end

    function entity:destroy()
        self.destroyed = true
        self.is_valid = false
    end

    return entity
end

function test_env.reset_globals()
    _G.GRID_MAX = 63
    _G.ResourceComponent = {}
    _G.BuildingComponent = {}
    _G.DudeManagerComponent = {}
    _G.DudeComponent = {}
    _G.dude_manager = nil

    _G.world = {
        entities = {},
        astar = {
            is_walkable = function(_, x, y)
                return x >= 0 and x <= GRID_MAX and y >= 0 and y <= GRID_MAX
            end
        }
    }

    function world:find_all_entities_with_component(component_type)
        local entities = {}

        for _, entity in ipairs(self.entities) do
            if entity.is_valid and entity:find_component_of_type(component_type) then
                table.insert(entities, entity)
            end
        end

        return entities
    end
end

return test_env
