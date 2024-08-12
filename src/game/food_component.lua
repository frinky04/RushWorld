-- -- Libs
local component = require("src.core.component")

---- Food Component
-- This component is used to represent food in the game world. It has a name and a value that represents how much hunger it will restore.
local food_component = {}
food_component.__index = food_component

setmetatable(food_component, {
    __index = component
})

function food_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, food_component)

    self.name = "Food Component"
    self.hunger_restored = 100

    return self
end

function food_component:on_eaten(dude)
    self.entity:destroy()
end

return food_component
