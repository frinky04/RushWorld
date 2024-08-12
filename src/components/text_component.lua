-- Libs
local component = require("src.core.component")

---- Text Component

local text_component = {}
text_component.__index = text_component

setmetatable(text_component, {
    __index = component
})

function text_component:new(entity, font, text, color)
    local self = component:new(entity)
    setmetatable(self, text_component)

    self.name = "TextComponent"
    self.font = font
    self.text = text
    self.color = color
    self.scale = 1
    self.render_offset_x, self.render_offset_y = 0, 0

    return self
end

function text_component:draw()
    component.draw(self)
    love.graphics.setColor(self.color)
    local font = self.font

    local scale_x = 0.25 * self.scale
    local scale_y = 0.25 * self.scale
    local sprite_width = font:getWidth(self.text) * scale_x
    local sprite_height = font:getHeight() * scale_y
    local render_pos_x, render_pos_y = self.entity:get_render_position()
    render_pos_x = render_pos_x + self.render_offset_x
    render_pos_y = render_pos_y + self.render_offset_y
    render_pos_x = render_pos_x - sprite_width / 2 -- align center
    render_pos_y = render_pos_y - sprite_height / 2 -- align center

    love.graphics.setFont(font)
    love.graphics.printf(self.text, render_pos_x, render_pos_y, font:getWidth(self.text), "center", 0, scale_x, scale_y)
    -- love.graphics.printf(text(string), x(number), y(number), limit(number), align(AlignMode), r(number), sx(number), sy(number), ox(number), oy(number), kx(number), ky(number))
end

return text_component
