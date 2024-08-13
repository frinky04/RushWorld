-- -- Libs
local component = require("src.core.component")

---- Spawn On Death Component
-- This component only works if the entity has a health component. Spawns an entity when the entity dies. executes a setup function on the spawned entity if provided.
local spawn_on_death_component = {}
spawn_on_death_component.__index = spawn_on_death_component

setmetatable(spawn_on_death_component, {
    __index = component
})

--- cretes a new spawn on death component
---@param entity entity the entity to attach to 
---@param setup_function function to call to setup the new entity
---@param spawned_entity_name string name of the entity to spawn
function spawn_on_death_component:new(entity, setup_function, spawned_entity_name)
    local self = component:new(entity)
    setmetatable(self, spawn_on_death_component)

    self.health_component = entity:find_component_of_type(HealthComponent)
    if not self.health_component then
        print("SpawnOnDeathComponent requires a HealthComponent, removing self")
        entity:destroy()
    end
    self.health_component:register_death_callback(self.on_death, self)

    self.name = "Spawn On Death Component"
    self.setup_function = setup_function
    self.spawned_entity_name = spawned_entity_name

    return self
end

function spawn_on_death_component:on_death()
    if self.setup_function then
        Entity:new(self.entity.x, self.entity.y, self.spawned_entity_name, self.setup_function)
    end
end

return spawn_on_death_component
