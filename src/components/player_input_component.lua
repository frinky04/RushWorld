-- Libs
local component = require("src.core.component")

---- Player input Component
-- Just listens for WASD or Arrow keys and moves the entity accordingly (using the move method from the entity)

local player_input_component = {}
player_input_component.__index = player_input_component

setmetatable(player_input_component, {
    __index = component
})

function player_input_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, player_input_component)

    self.name = "PlayerInputComponent"
    self.desired_direction = {0, 0}
    self.time_since_last_move = 0
    self.move_cooldown = 0.5
    self.move_queued = true

    return self
end

function player_input_component:attempt_move()
    if self.time_since_last_move > self.move_cooldown then
        self.entity:move(self.desired_direction[1], self.desired_direction[2])
        self.time_since_last_move = 0
    end

end

function player_input_component:key_input(key, scancode, isrepeat, ispressed)

end

function player_input_component:tick(dt)

    -- is input key pressed

    self.desired_direction = {0, 0}

    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.desired_direction = {0, -1}
    elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.desired_direction = {0, 1}
    elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.desired_direction = {-1, 0}
    elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.desired_direction = {1, 0}
    end

    if self.desired_direction[1] ~= 0 or self.desired_direction[2] ~= 0 then
        self.move_queued = true
    else
        self.move_queued = false
    end

    self.time_since_last_move = self.time_since_last_move + dt

    if self.move_queued then
        self:attempt_move()
    end

end

return player_input_component
