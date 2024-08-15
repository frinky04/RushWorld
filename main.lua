-- :core imports
require "src.core.util"
require "src.core.shaders"
require "src.core.sounds"
World = require("src.core.world")
Entity = require("src.core.entity")
Component = require("src.core.component")

-- :colors
BACKGROUND_A = hexToRGBA("1b1d1e") -- lighter
BACKGROUND_B = hexToRGBA("171819") -- darker
BACKGROUND_C = hexToRGBA("111213") -- darkest


-- :misc imports
SpriteComponent = require("src.components.sprite_component")
TextComponent = require("src.components.text_component")
CollisionComponent = require("src.components.collision_component")
PlayerInputComponent = require("src.components.player_input_component")
AI_MovementComponent = require("src.components.ai_mover_component")
HealthComponent = require("src.game.health_component")

-- :lib/util imports
AStar = require("src.libs.astar")
require "src.benchmarks.astar_benchmark"

-- :game imports
require "src.game.setup_functions"
DudeComponent = require("src.game.dudes.dude_component")
DudeBrainComponent = require("src.game.dudes.dude_brain_component")
FoodComponent = require("src.game.food_component")
SwayComponent = require("src.game.sway_component")
SpawnOnDeathComponent = require("src.game.spawn_on_death_component")
BuildingComponent = require("src.game.building_component")



-- :music


-- :pre-engine initialize
love.graphics.setDefaultFilter("nearest", "nearest")

-- :constants
GRID_SIZE_PX = 16
GRID_SIZE_HALF_PX = GRID_SIZE_PX / 2
GRID_SIZE = 64
GRID_MAX = GRID_SIZE - 1
UPDATE_TIME = 0.2


-- :fonts
OXANIUM_REGULAR = love.graphics.newFont("assets/fonts/OXANIUM-BOLD.ttf")

--astar_benchmark()

-- :game vars0
world = World:new(GRID_SIZE, GRID_SIZE)

local time_since_last_update = 0
local last_mouse_pos = { 0, 0 }
mouse_delta = { 0, 0 }

-- :post-engine initialize
-- :rocks
for i = 1, 128, 1 do
    local rock = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "rock", setup_rock)
end

-- :ruins
for i = 1, 1, 1 do
    local ruin = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "ruin", setup_ruin)
end

-- :grass
for i = 1, 128, 1 do
    local grass = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "grass", setup_grass)
end

-- :berry_bushes
for i = 1, 32, 1 do
    local berry_bush = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "berry_bush",
        setup_berry_bush)
end

-- :trees
for i = 1, 64, 1 do
    local tree = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "tree", setup_tree)
end

-- :dudes
for i = 1, 1, 1 do
    local dude = Entity:new(GRID_SIZE / 2, GRID_SIZE / 2, "dude", setup_dude)
end

-- :LOVE2D
function love.load()
    love.window.setTitle("RushWorld")
    love.window.setMode(1280, 1080)
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(BACKGROUND_C)

    -- :sounds to play on start
    am_forest_ambience:play()
end

function love.update(dt)
    dt = dt * world.time_scale
    time_since_last_update = time_since_last_update + dt
    if time_since_last_update >= UPDATE_TIME then
        time_since_last_update = 0
        world:update(UPDATE_TIME);
    end
    -- :update mouse delta
    local mouse_pos = { love.mouse.getX(), love.mouse.getY() }
    mouse_delta = { mouse_pos[1] - last_mouse_pos[1], mouse_pos[2] - last_mouse_pos[2] }
    last_mouse_pos = mouse_pos

    if love.mouse.isDown(3) then
        world:move_by(-mouse_delta[1], -mouse_delta[2])
    end

    world:tick(dt);
end

function love.wheelmoved(x, y)
    if y > 0 then
        world:zoom_by(1.1)
    elseif y < 0 then
        world:zoom_by(0.9)
    end
end

function love.draw()
    world:draw();
    -- :anything drawn here will be world space

    world:draw_end()

    love.graphics.setColor(0, 0, 0, 0.5)

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.print(
        love.timer.getFPS() ..
        " fps | " ..
        world.time_scale ..
        "x time-scale | " .. math.ceil(world.world_time) .. "s world-time | " .. #world.entities .. " entities", 8,
        love.graphics.getHeight() - 24)

    -- draw rectangle over the whole screen to represent nighttime
end

function love.keypressed(key, scancode, isrepeat)
    world:keypressed(key, scancode, isrepeat)

    if key == "space" then
        local x, y = world:get_current_mouse_grid_position()
        local entity = Entity:new(x, y, "wall")
        setup_wall(entity)
    end

    if key == "c" then
        -- make sure there isn't something already there
        if world:find_entity_at_mouse() == nil then
            local x, y = world:get_current_mouse_grid_position()
            local entity = Entity:new(x, y, "dude", setup_dude)
        end
    end

    if key == "x" then
        local x, y = world:get_current_mouse_grid_position()
        -- find entitties at mouse
        local entities = world:find_entities_at(x, y)
        for i, entity in ipairs(entities) do
            if entity:find_component_of_type(HealthComponent) then
                damage_entity(entity, 100)
            else
                entity:destroy()
            end
        end
    end

    if key == "f1" then
        -- spawn an stone, and the give it do dude
        local x, y = world:get_current_mouse_grid_position()
        local entity = Entity:new(x, y, "stone", setup_log)
        local dude = world:find_entity_by_name("dude")
        if dude then
            dude:find_component_of_type(DudeComponent).held = entity
        end
    end

    -- time scale keys
    if key == "1" then
        world.time_scale = 1
    end
    if key == "2" then
        world.time_scale = 2
    end
    if key == "3" then
        world.time_scale = 8
    end
    if key == "4" then
        world.time_scale = 32
    end
end

function love.keyreleased(key, scancode)
    world:keyreleased(key, scancode)
end
