--- @class entity
--- @field name string name of entity
--- @field x number x_pos
--- @field y number y_pos
--- @field rot number rotation
--- @field draw_priority number draw_priority
--- @field is_valid boolean is_valid
--- @field components table list of components
local entity = {}
entity.__index = entity

--- new entity, adds to the default world
---@param x number x_pos
---@param y number y_pos
---@param name string|nil name of entity
---@param setup_function function|nil setup function
function entity:new(x, y, name, setup_function)
    local self = setmetatable({}, entity)

    self.name = name or "Entity"

    self.x = x
    self.y = y
    self.rot = 0

    self.draw_priority = 0
    self.is_valid = true
    self.components = {}
    self.render_ontop = false
    self.entity_creation_time = love.timer.getTime()


    -- Add the entity to the world
    world:add_entity(self)

    -- Call the setup function
    if setup_function then
        setup_function(self)
    end

    return self
end

function entity:add_component(component)
    -- print("Component " .. tostring(component) .. " added to entity " .. tostring(self))
    table.insert(self.components, component)
    return component
end

--- func to find all components of a type
---@param class component
---@return table components
function entity:find_all_components_of_type(class)
    local components = {}
    for i, component in ipairs(self.components) do
        if component:is_a(class) then
            table.insert(components, component)
        end
    end
    return components
end

--- func to find the first component of a type
---@param class component
---@return table|nil components
function entity:find_component_of_type(class)
    for i, component in ipairs(self.components) do
        if component:is_a(class) then
            return component
        end
    end

    return nil
end

function entity:find_component(name)
    for i, component in ipairs(self.components) do
        if component.name == name then
            return component
        end
    end
end

function entity:__tostring()
    return self.name
end

function entity:draw()
    for i, component in ipairs(self.components) do
        if component.enabled then
            component:draw()
        end
    end
end

-- Called every game update
function entity:update(dt)
    for i, component in ipairs(self.components) do
        if component.enabled then
            component:update(dt)
        end
    end
end

-- Called every game tick (usually per frame)
function entity:tick(dt)
    for i, component in ipairs(self.components) do
        if component.enabled then
            component:tick(dt)
        end
    end
end

function entity:destroy()
    world:remove_entity(self)

    for i, component in ipairs(self.components) do
        component:destroy()
    end
end

function entity:is_a(class)
    return getmetatable(self) == class
end

---Key input
---@param key string key pressed
---@param scancode string scancode pressed
---@param isrepeat boolean is repeat
---@param ispressed boolean is pressed
---@return nil
function entity:key_input(key, scancode, isrepeat, ispressed)
    for i, component in ipairs(self.components) do
        if component.enabled then
            component:key_input(key, scancode, isrepeat, ispressed)
        end
    end
end

-- moves the entity, taking into account collision
function entity:move(x, y)
    -- if we have a collision component, check if we can move (sweep test)
    for i, component in ipairs(self.components) do
        if component:is_a(CollisionComponent) then
            if component:can_move(x, y) then
                self.x = self.x + x
                self.y = self.y + y

                self.x = math.max(0, math.min(self.x, GRID_MAX))
                self.y = math.max(0, math.min(self.y, GRID_MAX))

                -- world:refresh_nav_collision()
            end
            return
        end
    end

    self.x = self.x + x
    self.y = self.y + y

    -- clamp to world bounds
end

-- teleports the entity to a new position
function entity:teleport(x, y)
    self.x = x
    self.y = y
end

function entity:get_render_position()
    -- first find the sprite component
    local sprite_comp = self:find_component_of_type(SpriteComponent)
    if sprite_comp then
        return sprite_comp:get_render_position()
    end

    -- if no sprite component, return the entity position
    return self.x * GRID_SIZE_PX, self.y * GRID_SIZE_PX
end

function entity:get_time_since_creation()
    return love.timer.getTime() - self.entity_creation_time
end

return entity
