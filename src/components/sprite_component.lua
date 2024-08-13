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
    self.tint = tint or { 255, 255, 255, 1 }
    self.pivot = SPRITE_PIVOT.CENTER_CENTER
    self.render_offset_x, self.render_offset_y = 0, 0

    self.flip_x = false
    self.flip_y = false

    -- internal render position
    self.lerped_x = entity.x
    self.lerped_y = entity.y
    self.move_tween_speed = move_tween_speed or -1

    return self
end

function sprite_component:tick(dt)
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

function sprite_component:draw()
    --love.graphics.setShader(shader_solid_white)

    love.graphics.setColor({ 1.0, 1.0, 1.0, 1.0 })
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

    love.graphics.draw(sprite, render_pos_x, render_pos_y, self.entity.rot, scale_x, scale_y, sprite_origin_x,
        sprite_origin_y)

    -- unset shader
    love.graphics.setShader()
end

return sprite_component
