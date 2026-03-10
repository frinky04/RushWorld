--- @class component
--- @field entity entity owner of the component
--- @field name string name of the component
--- @field enabled boolean whether or not the component is enabled
local component = {}
component.__index = component

function component:new(entity)
    local self = setmetatable({}, component)
    self.entity = entity
    self.name = "Component"
    self.enabled = true

    self.is_valid = true

    entity:add_component(self)
    return self
end

function component:destroy()
    if not self.is_valid then
        return
    end

    -- remove from list of components
    for i, component in ipairs(self.entity.components) do
        if component == self then
            table.remove(self.entity.components, i)
            break
        end
    end

    self.is_valid = false
    -- remove the component from the entity
end

function component:__tostring()
    return self.name
end

function component:draw()
    -- implement this
end

function component:update(dt)
    -- implement this
end

function component:tick(dt)
    -- implement this
end

function component:key_input(key, scancode, isrepeat, ispressed)
    -- implement this
end

function component:is_a(class)
    return getmetatable(self) == class
end

return component
