-- Libs
local component = require("src.core.component")


-- Sprite Pivot Enum
SPRITE_PIVOT = {
    CENTER_CENTER = 1,
    CENTER_BOTTOM = 2
}

---- Sprite Component

local sprite_component = {}
sprite_component.__index = sprite_component

setmetatable(sprite_component, {
    __index = component
})

function sprite_component:new(entity, sprite, tint, move_tween_speed)
    local self = component:new(entity)
    setmetatable(self, sprite_component)

    self.name = "SpriteComponent"
    self.sprite = sprite
    self.tint = tint or { 1, 1, 1, 1 }
    self.pivot = SPRITE_PIVOT.CENTER_CENTER
    self.render_offset_x, self.render_offset_y = 0, 0

    self.flip_x = false
    self.flip_y = false

    self.white = false

    -- blink
    self.blink = false
    self.blink_min = 0.1
    self.blink_max = 0.5
    self.blink_speed = 5
    self.blink_alpha = 0.0

    -- internal render position
    self.lerped_x = entity.x
    self.lerped_y = entity.y
    self.move_tween_speed = move_tween_speed or -1


    return self
end

function sprite_component:tick(dt)
    -- update blink
    if self.blink then
        self.blink_alpha = map_to_range(math.sin(love.timer.getTime() * self.blink_speed), -1, 1,
            self.blink_min, self.blink_max)
    end

    if self.move_tween_speed == -1 then
        self.lerped_x = self.entity.x
        self.lerped_y = self.entity.y
        return
    end
    if self.entity.x == self.lerped_x and self.entity.y == self.lerped_y then
        return
    end

    self.lerped_x = interp_to(self.lerped_x, self.entity.x, dt, self.move_tween_speed)
    self.lerped_y = interp_to(self.lerped_y, self.entity.y, dt, self.move_tween_speed)
end

function sprite_component:get_render_position()
    return self.lerped_x * GRID_SIZE_PX + self.render_offset_x, self.lerped_y * GRID_SIZE_PX + self.render_offset_y
end

function sprite_component:get_tint()
    local tint = self.tint

    if self.blink then
        tint = { tint[1], tint[2], tint[3], self.blink_alpha }
    end

    return tint
end

function sprite_component:draw()
    if self.white then
        love.graphics.setShader(shader_solid_white)
    end

    love.graphics.setColor(self:get_tint())
    local sprite = self.sprite

    local scale_x = 1
    local scale_y = 1

    local sprite_width = sprite:getWidth()
    local sprite_height = sprite:getHeight()

    local sprite_origin_x = sprite_width / 2
    local sprite_origin_y = sprite_height / 2

    local render_pos_x, render_pos_y = self:get_render_position()

    if self.pivot == SPRITE_PIVOT.CENTER_BOTTOM then
        -- sprite_origin_y = sprite_height - GRID_SIZE_HALF_PX -- align bottom, tad hacky
        sprite_origin_y = sprite_height
        render_pos_y = render_pos_y + GRID_SIZE_HALF_PX
    end

    if self.flip_x then
        scale_x = -1
        render_pos_x = render_pos_x + sprite_width
    end

    if self.flip_y then
        scale_y = -1
        render_pos_y = render_pos_y + sprite_height
    end

    love.graphics.draw(sprite, render_pos_x, render_pos_y, self.entity.rot,
        scale_x, scale_y, sprite_origin_x, sprite_origin_y)

    -- unset shader
    love.graphics.setShader()
end

return sprite_component
