-- -- Libs
local component = require("src.core.component")

---- Building Component

local building_component = {}
building_component.__index = building_component

setmetatable(building_component, {
    __index = component
})


---comment
---@param entity entity owner of the component
---@param tags table<string> string of tags for this building
---@param incompatible_tags table<string> string of tags that this building cannot be onto the same tile
---@param required_resources table<string> resource names required to build this building
---@return nil
function building_component:new(entity, tags, incompatible_tags, required_resources)
    local self = component:new(entity)
    setmetatable(self, building_component)

    self.name = "Building Component"


    self.tags = tags or { "building" }
    self.incompatible_tags = incompatible_tags or { "building" }

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

    sfx_place_object:play()

    -- :setup sprite_component
    self.sprite_component.white = true
    self.sprite_component.tint = { 1.0, 1.0, 1.0, 0.1 }
    self.sprite_component.blink = true

    self.required_resources = required_resources or {}
    self.given_resources = {}

    return building_component
end

function building_component:get_next_material()
    for i, resource in ipairs(self.required_resources) do
        if self.given_resources[resource] == nil then
            return resource
        end
    end
    return nil
end

function building_component:add_material(resource)
    -- remove the resource from the required resources
    for i, required_resource in ipairs(self.required_resources) do
        if required_resource == resource.name then
            table.remove(self.required_resources, i)
            break
        end
    end

    print("Building Component: Added resource: ", resource.name)

    -- if we have all the resources, build the building
    if #self.required_resources == 0 then
        self:built()
    end
end

function building_component:built()
    self.sprite_component.white = false
    self.sprite_component.tint = { 1.0, 1.0, 1.0, 1.0 }
    self.sprite_component.blink = false

    print("Building Component: Built")
    self.is_valid = false
    self:destroy()
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