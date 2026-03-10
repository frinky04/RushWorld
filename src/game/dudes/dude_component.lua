-- -- Libs
local component = require("src.core.component")

---- AI Mover Component

local dude_component = {}
dude_component.__index = dude_component

setmetatable(dude_component, {
    __index = component
})

function dude_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, dude_component)

    self.name = "Dude Component"

    -- setup brain
    self.brain = entity:find_component_of_type(DudeBrainComponent)
    if not self.brain then
        print("DudeComponent requires a DudeBrainComponent, removing self")
        self:destroy()
        return nil
    end
    self.brain.dude = self

    -- setup ai mover component
    self.ai_mover = entity:find_component_of_type(AI_MovementComponent)
    if not self.ai_mover then
        print("DudeComponent requires an AI_MovementComponent, removing self")
        self:destroy()
        return nil
    end

    self.text = entity:find_component_of_type(TextComponent)

    self.health = entity:find_component_of_type(HealthComponent)
    if not self.health then
        print("DudeComponent requires a HealthComponent, removing self")
        self:destroy()
        return nil
    end
    self.health_death_callback_id = self.health:register_death_callback(self.on_death, self)

    self.first_name = "Dude"
    self.last_name = "McDuderson"
    self.status = "None"

    self.goal = nil
    self.work = nil

    self.held = nil
    self.last_held = nil

    self.hunger = 100
    self.tiredness = 100


    dude_manager:find_component_of_type(DudeManagerComponent):refresh_dudes(self)
    return self
end

function dude_component:tick(dt)
    self.ai_mover.goal = self.goal

    if self.held ~= self.last_held then
        if self.last_held then
            self:on_drop(self.last_held)
        end
        if self.held then
            self:on_pickup(self.held)
        end
        self.last_held = self.held
    end

    if self.held then
        local x, y = self.entity:get_render_position()
        self.held.x = x / GRID_SIZE_PX
        self.held.y = (y + 4) / GRID_SIZE_PX
    end
end

function dude_component:update(dt)
    if self.text then
        self.text.text = self.status ..
            "\nHunger: " .. math.ceil(self.hunger) .. "\nHealth: " .. math.ceil(self.health.health)
    end
    -- update stats
    self.hunger = self.hunger - dt
    if self.hunger < 0 then
        self.health:take_damage(dt * 2)
        self.hunger = 0
    end
end

function dude_component:destroy()
    if is_valid_component(self.health) and self.health_death_callback_id then
        self.health:unregister_death_callback(self.health_death_callback_id)
        self.health_death_callback_id = nil
    end

    if self.held then
        self:on_drop(self.held)
        self.held = nil
    end

    dude_manager:find_component_of_type(DudeManagerComponent):refresh_dudes(self)
    component.destroy(self)
end

function dude_component:on_death()
    -- self is the dude_component instance (registered via :register_death_callback)
    print("Dude has died")
    local corpse = Entity:new(self.entity.x, self.entity.y, "Corpse", setup_dude_corpse)
end

function dude_component:eat(entity)
    if not is_valid(entity) then
        return
    end

    local food_component = entity:find_component_of_type(FoodComponent)

    if food_component == nil then
        print("Dude tried to eat something that wasn't food!")
        return
    end

    self.hunger = self.hunger + food_component.hunger_restored
    if self.hunger > 100 then
        self.hunger = 100
    end

    food_component:on_eaten(self)
end

function dude_component:on_drop(entity)
    if is_valid(entity) then
        entity.held_by = nil
        release_entity_reservation(entity, self.entity)
        entity.render_ontop = false
        print("Dude dropped " .. entity.name)
    end
end

function dude_component:on_pickup(entity)
    if is_valid(entity) then
        entity.held_by = self.entity
        reserve_entity(entity, self.entity)
        entity.render_ontop = true
        print("Dude picked up " .. entity.name)
    end
end

return dude_component
