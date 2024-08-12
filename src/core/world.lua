-- Libs
local world = {}
world.__index = world

function world:new(x_size, y_size)
    local self = setmetatable({}, world)
    print("World Initialized...")

    self.entities = {}
    self.x_size = x_size
    self.y_size = y_size

    self.astar = AStar:new(x_size, y_size)

    self.time_scale = 1
    self.world_time = 0

    self.target_zoom = 4
    --- @DONT USE! USE ZOOM_BY INSTEAD OR SET TARGET_ZOOM
    self.zoom = 4
    self.target_camera_pos = {
        x = x_size * GRID_SIZE_PX / 2,
        y = y_size * GRID_SIZE_PX / 2
    }
    --- @DONT USE! USE MOVE_BY INSTEAD OR SET TARGET_CAMERA_POS
    self.camera_pos = {
        x = x_size * GRID_SIZE_PX / 2,
        y = y_size * GRID_SIZE_PX / 2
    }

    return self
end

---adds an entity
---@param entity any  entity to add
---@return any entity entity added
function world:add_entity(entity)
    -- print("Entity " .. tostring(entity) .. " added to world (" .. entity.x .. ", " .. entity.y .. ")")

    table.insert(self.entities, entity)
    return entity
end

---gets an entity by name
---@param name string name of entity
---@return any entity entity found
function world:find_entity_by_name(name)
    for i, entity in ipairs(self.entities) do
        if entity.name == name then
            return entity
        end
    end
end

-- gets the closest entity with a name
--- @param name string name of entity
--- @param x number x position
--- @param y number y position
--- @return any entity entity found
function world:find_nearest_entity_by_name(name, x, y)
    local closest_entity = nil
    local closest_distance = 999999999
    for i, entity in ipairs(self.entities) do
        if entity.name == name then
            local distance = math.abs(entity.x - x) + math.abs(entity.y - y)
            if distance < closest_distance then
                closest_entity = entity
                closest_distance = distance
            end
        end
    end

    return closest_entity
end

function world:find_entity_at(x, y)
    for i, entity in ipairs(self.entities) do
        if round(entity.x) == x and round(entity.y) == y then
            return entity
        end
    end
end

function world:find_entity_at_mouse()
    local x, y = self:get_current_mouse_grid_position()
    return self:find_entity_at(x, y)
end

---removes an entity
---@param entity any entity to remove
function world:remove_entity(entity)
    -- print("Entity " .. tostring(entity) .. " removed from world")

    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            setmetatable(entity, nil)
            entity.is_valid = false
            entity = nil
            return
        end
    end
end

function world:y_sort()
    table.sort(self.entities, function(a, b)
        if a.y == b.y then
            if a.draw_priority == b.draw_priority then
                -- use the length of their name + their component list length as a tiebreaker
                return #a.name + #a.components < #b.name + #b.components
            end
            return a.draw_priority < b.draw_priority
        end
        return a.y < b.y
    end)
end

function world:update(dt)
    self:refresh_nav_collision()

    for i, entity in ipairs(self.entities) do
        entity:update(dt)
    end
end

function world:tick(dt)
    self.world_time = self.world_time + dt

    for i, entity in ipairs(self.entities) do
        entity:tick(dt)
    end

    -- lerp camera
    self.camera_pos.x = interp_to(self.camera_pos.x, self.target_camera_pos.x, dt, 35)
    self.camera_pos.y = interp_to(self.camera_pos.y, self.target_camera_pos.y, dt, 35)
    self.zoom = interp_to(self.zoom, self.target_zoom, dt, 35)
end

function world:draw()
    self:y_sort(self.entities)

    love.graphics.push()

    -- handle matrix transformations
    local width, height = love.graphics.getDimensions()
    local centerX, centerY = width / 2, height / 2

    love.graphics.translate(centerX, centerY)
    love.graphics.scale(self.zoom)
    love.graphics.translate(-self.camera_pos.x, -self.camera_pos.y)

    for x = 0, self.x_size - 1 do
        for y = 0, self.y_size - 1 do
            if (x + y) % 2 == 0 then
                love.graphics.setColor(BACKGROUND_A)
            else
                love.graphics.setColor(BACKGROUND_B)
            end

            love.graphics.rectangle("fill", ((x - 1) * GRID_SIZE_PX) + GRID_SIZE_HALF_PX, ((y - 1) * GRID_SIZE_PX) + GRID_SIZE_HALF_PX, GRID_SIZE_PX, GRID_SIZE_PX)
        end
    end

    for i, entity in ipairs(self.entities) do
        entity:draw()
    end
end

function world:draw_end()
    love.graphics.pop()
end

function world:keypressed(key, scancode, isrepeat)
    for i, entity in ipairs(self.entities) do
        entity:key_input(key, scancode, isrepeat, true)
    end
end

function world:keyreleased(key, scancode)
    for i, entity in ipairs(self.entities) do
        entity:key_input(key, scancode, false, false)
    end
end

function world:zoom_by(amount)
    self.target_zoom = self.target_zoom * amount
    -- clamp zoom
    self.target_zoom = math.max(0.75, math.min(self.target_zoom, 16))
end

function world:move_by(x, y)
    self.target_camera_pos.x = self.target_camera_pos.x + x / self.target_zoom
    self.target_camera_pos.y = self.target_camera_pos.y + y / self.target_zoom
end

function world:refresh_nav_collision()
    -- this will go through all entities, if they have a collision component, we'll mark that cell as unwalkable
    if not self.astar.grid then
        return
    end

    -- mark all cells as walkable
    for y, row in ipairs(self.astar.grid) do
        for x, cell in ipairs(row) do
            self.astar:set_walkable(x, y, true)
        end
    end

    -- Get all entities with collision components
    for i, entity in ipairs(self.entities) do
        for j, component in ipairs(entity.components) do
            if component:is_a(CollisionComponent) then
                if component.affects_pathfinding then
                    self.astar:set_walkable(entity.x, entity.y, false)
                end
            end
        end
    end

end

--- @return number x, number y
function world:get_current_mouse_world_position()
    local x, y = love.mouse.getPosition()
    x = x - love.graphics.getWidth() / 2
    y = y - love.graphics.getHeight() / 2
    x = x / self.zoom + self.camera_pos.x
    y = y / self.zoom + self.camera_pos.y

    return x, y
end

--- @return int x, int y
function world:get_current_mouse_grid_position()
    local x, y = self:get_current_mouse_world_position()
    x = round(x / GRID_SIZE_PX)
    y = round(y / GRID_SIZE_PX)
    return x, y
end

function world:get_random_position()
    return love.math.random(0, self.x_size - 1), love.math.random(0, self.y_size - 1)
end

function world:get_random_positon_in_radius(x, y, radius)
    local new_x = x + love.math.random(-radius, radius)
    local new_y = y + love.math.random(-radius, radius)

    new_x = math.max(0, math.min(self.x_size - 1, new_x))
    new_y = math.max(0, math.min(self.y_size - 1, new_y))

    return new_x, new_y
end

return world
