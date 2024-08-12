-- -- Libs
local component = require("src.core.component")

-- Sprite Pivot Enum
DUDE_BRAIN_STATE = {
    IDLE = 1,
    WANDERING = 2,
    FIND_FOOD = 3,
    FLEEING = 4
}

---- AI Mover Component

local dude_brain_component = {}
dude_brain_component.__index = dude_brain_component

setmetatable(dude_brain_component, {
    __index = component
})

function dude_brain_component:new(entity)
    local self = component:new(entity)
    setmetatable(self, dude_brain_component)

    self.name = "Dude Brain Component"

    self.dude = nil
    self.brain_state = DUDE_BRAIN_STATE.WANDERING
    self.completed = true
    self.pause_time = 0.0

    return self
end

-- function dude_brain_component:do_state_template(dt)

--     self.dude.status = "State"
--     if self.completed then
--         -- do something on start of state
--         -- self.completed = false
--     end
--     -- do something every frame

--     if action_completed then
--         self.completed = true
--     end
-- end

function dude_brain_component:do_wandering(dt)

    -- the general logic here is we should enter this state "finished" the first time, in which we can set a new goal, then upon re-entering this function we'll check if we're at the goal and set completed to true

    self.dude.status = "Wandering"
    if self.completed then
        local x, y = world:get_random_positon_in_radius(self.entity.x, self.entity.y, 5)
        self.dude.ai_mover.goal = {
            x = x,
            y = y
        }
        self.completed = false
    end

    if self.dude.ai_mover:is_at_goal() then
        self.dude.ai_mover.goal = nil
        self.completed = true
        self.pause_time = 5
    end
end

function dude_brain_component:do_find_food(dt)

    self.dude.status = "Finding Food"
    if self.completed then
        -- for now, harcode berry bush
        local food = world:find_nearest_entity_by_name("berry_bush", self.entity.x, self.entity.y)
        if is_valid(food) then
            self.dude.ai_mover.goal = food
            self.completed = false
        else

            self.completed = true
            self.pause_time = 1
            return
        end
    end
    -- do something every frame

    self.dude.status = "Moving to food"
    if is_valid(self.dude.ai_mover.goal) == false then
        self.dude.ai_mover.goal = nil
        self.completed = true
        self.pause_time = 1
        return
    end

    if self.dude.ai_mover:is_at_goal() then
        self.dude:eat(self.dude.ai_mover.goal)
        self.completed = true
        self.dude.hunger = 100
        self.pause_time = 2
    end

end

function dude_brain_component:update_brain_state()
    local new_state = self.brain_state
    if self.dude.hunger < 25 then
        new_state = DUDE_BRAIN_STATE.FIND_FOOD
        self.pause_time = 0
    else
        new_state = DUDE_BRAIN_STATE.WANDERING
    end

    if new_state ~= self.brain_state then
        self.completed = true
        self.dude.ai_mover.goal = nil
        self.brain_state = new_state
    end
end

-- Final loop

function dude_brain_component:update(dt)
    if self.dude == nil then
        self.dude = self.entity:find_component_of_type(DudeComponent)
        return
    end

    self:update_brain_state()

    if self.pause_time > 0 then
        self.dude.status = "Pausing"
        self.dude.ai_mover.should_move = false
        self.pause_time = self.pause_time - dt
        return
    else
        self.dude.ai_mover.should_move = true
    end

    if self.brain_state == DUDE_BRAIN_STATE.WANDERING then
        self:do_wandering(dt)
    elseif self.brain_state == DUDE_BRAIN_STATE.FIND_FOOD then
        self:do_find_food(dt)
    end
end

return dude_brain_component
