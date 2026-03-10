-- -- Libs
local component = require("src.core.component")

local health_component = {}
health_component.__index = health_component

setmetatable(health_component, {
    __index = component
})

---comment
---@param entity entity
---@param health number
---@return component health_component
function health_component:new(entity, health)
    local self = component:new(entity)
    setmetatable(self, health_component)

    local other_heal_comp = entity:find_all_components_of_type(HealthComponent)
    if #other_heal_comp > 1 then
        print("Entity " .. entity.name .. " has more than one health component, removing the new one")
        self:destroy()
    end

    self.name = "Health Component"
    self.death_callbacks = {}
    self.next_death_callback_id = 1
    self.last_damaged_by = nil
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
    local callback_id = self.next_death_callback_id
    self.next_death_callback_id = self.next_death_callback_id + 1

    table.insert(self.death_callbacks, {
        id = callback_id,
        fn = callback,
        ctx = component_calling
    })

    return callback_id
end

function health_component:unregister_death_callback(callback_id)
    if callback_id == nil then
        return false
    end

    for i, callback in ipairs(self.death_callbacks) do
        if callback.id == callback_id then
            table.remove(self.death_callbacks, i)
            return true
        end
    end

    return false
end

function health_component:handle_death()
    local callbacks = self.death_callbacks
    self.death_callbacks = {}

    for i, callback in ipairs(callbacks) do
        if callback.fn and (callback.ctx == nil or is_valid_component(callback.ctx)) then
            callback.fn(callback.ctx)
        end
    end

    self.entity:destroy()
end

function health_component:destroy()
    self.death_callbacks = {}
    component.destroy(self)
end

return health_component
