-- -- Libs
local component = require("src.core.component")

---- Sway Component
-- for swaying objects (like trees)
-- will override the entities rotation

local sway_component = {}
sway_component.__index = sway_component

setmetatable(sway_component, {
    __index = component
})

--- new Sway Component
---@param entity entity to apply
---@param rotation_max number|nil to 0.1
---@param rotation_speed number|nil to 1
function sway_component:new(entity, rotation_max, rotation_speed)
    local self = component:new(entity)
    setmetatable(self, sway_component)

    self.name = "Sway Component"
    self.rotation_max = rotation_max or 0.1
    self.rotation_speed = rotation_speed or 1
    self.start_offset = math.random(0, 100)

    return self
end

function sway_component:tick(dt)
    self.entity.rot = (math.sin(world.world_time + self.start_offset * self.rotation_speed) * self.rotation_max)
end

return sway_component
