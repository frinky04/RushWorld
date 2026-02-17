-- Libs
local component = require("src.core.component")

---- Collision Component

local nav_blocker_component = {}
nav_blocker_component.__index = nav_blocker_component

setmetatable(nav_blocker_component, {
    __index = component
})

function nav_blocker_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, nav_blocker_component)

    self.name = "CollisionComponent"
    self.mass = 1
    self.collision_callbacks = {}
    self.affects_pathfinding = true


    return self
end

return nav_blocker_component