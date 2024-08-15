-- -- Libs
local component = require("src.core.component")

---- Building Component

local building_component = {}
building_component.__index = building_component

setmetatable(building_component, {
    __index = component
})

function building_component:new(entity, tags)
    local self = component:new(entity)
    setmetatable(self, building_component)

    self.name = "Building Component"


    self.tags = tags or { "building" }
    self.incompatible_tags = { "building" }

    -- : check for incompatible buildings
    local entities = world:find_entities_at(entity.x, entity.y)
    for i, other_entity in ipairs(entities) do
        if other_entity ~= entity then
            local building_component = other_entity:find_component_of_type(BuildingComponent)
            if building_component then
                if building_component:has_any_tag(self.incompatible_tags) then
                    sfx_error_placing:play()
                    entity:destroy()
                    return nil
                end
            end
        end
    end


    self.sprite_component = entity:find_component_of_type(SpriteComponent)
    if self.sprite_component == nil then
        sfx_error_placing:play()
        print("Building Component requires a Sprite Component")
        return nil
    end

    print(self.sprite_component)

    sfx_place_object:play()

    -- :setup sprite_component
    self.sprite_component.white = true
    self.sprite_component.tint = { 1.0, 1.0, 1.0, 0.1 }
    self.sprite_component.blink = true
    self.sprite_component.blink_min = 0.1
    self.sprite_component.blink_max = 0.5


    return building_component
end

function building_component:has_any_tag(tags)
    for i, tag in ipairs(tags) do
        for j, our_tag in ipairs(self.tags) do
            if tag == our_tag then
                return true
            end
        end
    end
    return false
end

return building_component
