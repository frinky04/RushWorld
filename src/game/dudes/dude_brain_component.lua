-- Utility AI Brain Component
local component = require("src.core.component")

-- Action modules
local action_idle = require("src.game.dudes.dude_actions.action_idle")
local action_wander = require("src.game.dudes.dude_actions.action_wander")
local action_eat = require("src.game.dudes.dude_actions.action_eat")
local action_work = require("src.game.dudes.dude_actions.action_work")

-- Hysteresis bonus for current action to prevent flickering
local HYSTERESIS_BONUS = 0.05

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
    self.pause_time = 0.0

    -- Registered actions
    self.actions = {
        action_idle,
        action_wander,
        action_eat,
        action_work,
    }

    -- Current action state
    self.current_action = nil
    self.action_time = 0
    self.action_state = {}

    -- Future system hooks (stubs for now)
    self.trait_modifiers = {}   -- {action_name = multiplier}
    self.mood_modifier = 1.0   -- global mood multiplier

    return self
end

function dude_brain_component:get_trait_modifier(action_name)
    return self.trait_modifiers[action_name] or 1.0
end

function dude_brain_component:score_action(action)
    local base = action:score(self.dude)
    local trait = self:get_trait_modifier(action.name)
    local score = base * trait * self.mood_modifier

    -- Hysteresis: current action gets a bonus
    if action == self.current_action then
        score = score + HYSTERESIS_BONUS
    end

    return score
end

function dude_brain_component:select_best_action()
    local best_action = nil
    local best_score = -1

    for _, action in ipairs(self.actions) do
        local score = self:score_action(action)
        if score > best_score then
            best_score = score
            best_action = action
        end
    end

    return best_action
end

function dude_brain_component:switch_action(new_action)
    if self.current_action then
        self.current_action:cancel(self.dude, self)
    end

    self.current_action = new_action
    self.action_time = 0
    self.action_state = {}

    if self.current_action then
        self.current_action:start(self.dude, self)
    end
end

function dude_brain_component:update(dt)
    if self.dude == nil then
        self.dude = self.entity:find_component_of_type(DudeComponent)
        return
    end

    -- Pause timer
    if self.pause_time > 0 then
        self.dude.ai_mover.should_move = false
        self.pause_time = self.pause_time - dt
        return
    else
        self.dude.ai_mover.should_move = true
    end

    -- Evaluate and potentially switch actions
    local best = self:select_best_action()
    if best ~= self.current_action then
        self:switch_action(best)
    end

    -- Perform current action
    if self.current_action then
        self.action_time = self.action_time + dt
        local complete = self.current_action:perform(self.dude, self, dt)
        if complete then
            self.current_action = nil
            self.action_time = 0
        end
    end
end

return dude_brain_component
