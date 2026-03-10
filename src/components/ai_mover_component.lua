-- -- Libs
local component = require("src.core.component")

---- AI Mover Component

local ai_mover_component = {}
ai_mover_component.__index = ai_mover_component

setmetatable(ai_mover_component, {
    __index = component
})

local function get_goal_position(goal)
    if goal == nil or goal.x == nil or goal.y == nil then
        return nil, nil
    end

    if goal.is_valid ~= nil and not is_valid(goal) then
        return nil, nil
    end

    return goal.x, goal.y
end

function ai_mover_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, ai_mover_component)

    self.name = "AI Mover Component"
    self.goal = nil
    self.should_move = true

    self.move_delay = 0.5
    self.move_timer = love.math.random(0, 1000) / 1000 * self.move_delay

    self.path = nil
    self.cached_goal_x = nil
    self.cached_goal_y = nil
    self.cached_nav_version = -1

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

    local goal_x, goal_y = get_goal_position(self.goal)
    if goal_x == nil or goal_y == nil then
        self:clear_path()
        return
    end

    if self:should_recalculate_path(goal_x, goal_y) then
        self:recalculate_path(goal_x, goal_y)
    end

    if not self.path or #self.path < 2 then
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

    if self.entity:move(difference.x, difference.y) then
        table.remove(self.path, 1)
        return
    end

    self:clear_path()
end

function ai_mover_component:is_at_goal()
    local goal_x, goal_y = get_goal_position(self.goal)
    if goal_x == nil or goal_y == nil then
        return false
    end

    return self.entity.x == goal_x and self.entity.y == goal_y
end

function ai_mover_component:is_at_end_of_path()
    if not self.path then
        return false
    end

    if #self.path < 1 then
        return false
    end

    return self.entity.x == self.path[#self.path].x and self.entity.y == self.path[#self.path].y
end

function ai_mover_component:clear_path()
    self.path = nil
    self.cached_goal_x = nil
    self.cached_goal_y = nil
    self.cached_nav_version = -1
end

function ai_mover_component:is_path_aligned()
    return self.path ~= nil
        and #self.path >= 1
        and self.path[1].x == self.entity.x
        and self.path[1].y == self.entity.y
end

function ai_mover_component:should_recalculate_path(goal_x, goal_y)
    if self.path == nil then
        return true
    end

    if self.cached_goal_x ~= goal_x or self.cached_goal_y ~= goal_y then
        return true
    end

    if self.cached_nav_version ~= world.nav_collision_version then
        return true
    end

    if not self:is_path_aligned() then
        return true
    end

    local next_step = self.path[2]
    if next_step and not world.astar:is_walkable(next_step.x, next_step.y) then
        return true
    end

    return false
end

function ai_mover_component:recalculate_path(goal_x, goal_y)
    self.path = world.astar:path(self.entity, { x = goal_x, y = goal_y }) or {}
    self.cached_goal_x = goal_x
    self.cached_goal_y = goal_y
    self.cached_nav_version = world.nav_collision_version
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
