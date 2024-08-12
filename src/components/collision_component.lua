-- Libs
local component = require("src.core.component")

---- Collision Component

local collision_component = {}
collision_component.__index = collision_component

setmetatable(collision_component, {
    __index = component
})

function collision_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, collision_component)

    self.name = "CollisionComponent"
    self.mass = 1
    self.collision_callbacks = {}
    self.affects_pathfinding = true


    return self
end

function collision_component:on_collision(other)
    for _, callback in ipairs(self.collision_callbacks) do
        callback(self.entity, other)
    end
end

function collision_component:register_collision_callback(callback)
    table.insert(self.collision_callbacks, callback)
end

function collision_component:destroy()

    component.destroy(self)
end

-- Checks if the entity can move to the specified coordinates (x, y) without colliding with other entities.
-- If a collision occurs, the on_collision method is called and false is returned.
-- Otherwise, true is returned.
function collision_component:can_move(x, y)
    local new_x = self.entity.x + x
    local new_y = self.entity.y + y

    for i, entity in ipairs(world.entities) do
        if entity ~= self.entity then
            for j, component in ipairs(entity.components) do
                if component:is_a(collision_component) then
                    if new_x == entity.x and new_y == entity.y then
                        self:on_collision(entity)
                        component:on_collision(self.entity)
                        return false
                    end
                end
            end
        end
    end

    return true
end

return collision_component
