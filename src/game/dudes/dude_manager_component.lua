-- -- Libs
local component = require("src.core.component")

---- AI Mover Component

local dude_manager_component = {}
dude_manager_component.__index = dude_manager_component

setmetatable(dude_manager_component, {
    __index = component
})

function dude_manager_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, dude_manager_component)

    self.name = "Dude Manager"
    self.dudes = {}

    return self
end

function dude_manager_component:refresh_dudes()
    self.dudes = world:find_all_entities_with_component(DudeComponent)

    -- TODO we should probably put our game over state on.
end

function dude_manager_component:is_another_dudes_work(entity)
    for _, dude in ipairs(self.dudes) do
        local dc = dude:find_component_of_type(DudeComponent)
        if dc and dc.work == entity then
            return true
        end
    end

    return false
end

function dude_manager_component:find_free_work()
    local entities = world:find_all_entities_with_component(BuildingComponent)

    -- loop through and find free.
    for _, entity in ipairs(entities) do
        if not self:is_another_dudes_work(entity) then
            return entity
        end
    end

    return nil
end

return dude_manager_component
