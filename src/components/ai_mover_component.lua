-- -- Libs
local component = require("src.core.component")

---- AI Mover Component

local ai_mover_component = {}
ai_mover_component.__index = ai_mover_component

setmetatable(ai_mover_component, {
    __index = component
})

function ai_mover_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, ai_mover_component)

    self.name = "AI Mover Component"
    self.goal = nil
    self.should_move = true

    self.move_delay = 0.5
    self.move_timer = love.math.random(0, 1000) / 1000 * self.move_delay

    self.path = nil

    return self
end

function ai_mover_component:tick(dt)
    component.tick(self, dt)

    self.move_timer = self.move_timer + dt

    -- self.path = world.astar:rough_path(self.entity, self.goal, 3)

    if self.move_timer > self.move_delay then
        self.move_timer = 0
        self:attempt_move()
    end
end

function ai_mover_component:attempt_move()
    if not self.should_move then
        return
    end

    if not self.goal then
        return
    end

    if not self.goal.x or not self.goal.y then
        print("goal must have x and y")
        return
    end

    -- path to goal
    self.path = world.astar:path(self.entity, self.goal)

    if not self.path then
        return
    end

    if #self.path < 2 then
        return
    end

    local current = {
        x = self.entity.x,
        y = self.entity.y
    }
    local next = {
        x = self.path[2].x,
        y = self.path[2].y
    }
    local difference = {
        x = next.x - current.x,
        y = next.y - current.y
    }

    self.entity:move(difference.x, difference.y)
end

function ai_mover_component:is_at_goal()
    if not self.goal then
        return false
    end

    return self.entity.x == self.goal.x and self.entity.y == self.goal.y
end

function ai_mover_component:is_at_end_of_path()
    if not self.path then
        return false
    end

    if #self.path < 2 then
        return false
    end

    return self.entity.x == self.path[#self.path].x and self.entity.y == self.path[#self.path].y
end

function ai_mover_component:draw()
    -- if not self.path then
    --     return
    -- end

    -- -- draw a line to the goal
    -- love.graphics.setColor(1, 1, 1, 0.1)
    -- for i = 1, #self.path - 1 do

    --     local current = self.path[i]

    --     local next = self.path[i + 1]

    --     love.graphics.line(current.x * GRID_SIZE_PX, current.y * GRID_SIZE_PX, next.x * GRID_SIZE_PX,
    --         next.y * GRID_SIZE_PX)
    -- end
end

return ai_mover_component
