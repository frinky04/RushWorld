-- -- Libs
local component = require("src.core.component")

---- Resource Component

local resource_component = {}
resource_component.__index = resource_component

setmetatable(resource_component, {
    __index = component
})


---Creates a new resource component
---@param entity entity The entity this component is attached to
---@param resource_name string|nil The name of the resource, so when looking for it in the world we can find it
---@param harvested_resources table<string>|nil A table of resources that can be harvested from this resource. Just an info table for dudes to plan their actions.
---@param dropped_items_setup_functions table<function>|nil A table of functions that will be called to setup the dropped items when this resource is destroyed.
---@return table|nil
function resource_component:new(entity, resource_name, harvested_resources, dropped_items_setup_functions)
    local self = component:new(entity)
    setmetatable(self, resource_component)

    self.health_component = entity:find_component_of_type(HealthComponent)
    if self.health_component == nil and harvested_resources then
        error("Resource Component that can be harvested requires a Health Component")
        return nil
    end

    if (self.health_component) then
        self.health_callback_id = self.health_component:register_death_callback(self.on_death, self)
    end

    self.name = "Resource Component"
    self.resource_name = resource_name or "none"
    self.harvested_resources = harvested_resources or {}
    self.dropped_resources_setup_functions = dropped_items_setup_functions or {}
    self.min_drop = 1
    self.max_drop = 1

    return self
end

function resource_component:on_death()
    if self.dropped_resources_setup_functions and #self.dropped_resources_setup_functions > 0 then
        local num_drops = love.math.random(self.min_drop, self.max_drop)
        for i = 1, num_drops do

            local setup_function = self.dropped_resources_setup_functions [love.math.random(1, #self.dropped_resources_setup_functions)]

            if setup_function then
                Entity:new(self.entity.x, self.entity.y, "entity", setup_function)
            end
        end
    end
end

function resource_component:destroy()
    if is_valid_component(self.health_component) and self.health_callback_id then
        self.health_component:unregister_death_callback(self.health_callback_id)
        self.health_callback_id = nil
    end
    component.destroy(self)
end

return resource_component
