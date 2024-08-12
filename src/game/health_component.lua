-- -- Libs
local component = require("src.core.component")

---- Health Component
-- This component is used to manage general health of an entity. On death, the entity is destroyed.
local health_component = {}
health_component.__index = health_component

setmetatable(health_component, {
    __index = component
})

function health_component:new(entity, health)
    local self = component:new(entity)
    setmetatable(self, health_component)

    local other_heal_comp = entity:find_all_components_of_type(HealthComponent)
    if #other_heal_comp > 1 then
        print("Entity " .. entity.name .. " has more than one health component, removing the new one")
        self:destroy()
    end

    self.name = "Health Component"
    -- @param table of functions to call when the entity dies {{function, component_calling}, etc}
    self.death_callbacks = {}
    --- @param the last entity that damaged this entity
    self.last_damaged_by = nil

    --- @param PRIVATE the health of the entity, please avoid changing this directly
    self.health = health or 100

    return self
end

function health_component:change_health(amount)
    self.health = self.health + amount
    if self.health <= 0 then
        self:die()
    end
end

function health_component:take_damage(damage)
    self:change_health(-damage)
end

function health_component:die()
    self.health = 0
    self:handle_death()
end

function health_component:register_death_callback(callback, component_calling)
    table.insert(self.death_callbacks, {callback, component_calling})
end

function health_component:handle_death()
    for i, callback in ipairs(self.death_callbacks) do
        callback[1](callback[2])
    end

    self.entity:destroy()
end

return health_component
