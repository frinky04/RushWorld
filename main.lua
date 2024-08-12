-- :core imports
World = require("src.core.world")
Entity = require("src.core.entity")
Component = require("src.core.component")
require "src.core.util"

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
-- require "src.libs.lovedebug"

-- :game imports
DudeComponent = require("src.game.dudes.dude_component")
DudeBrainComponent = require("src.game.dudes.dude_brain_component")
FoodComponent = require("src.game.food_component")
SwayComponent = require("src.game.sway_component")
SpawnOnDeathComponent = require("src.game.spawn_on_death_component")

-- :pre-engine initialize
love.graphics.setDefaultFilter("nearest", "nearest")

-- :constants
GRID_SIZE_PX = 16
GRID_SIZE_HALF_PX = GRID_SIZE_PX / 2
GRID_SIZE = 64
GRID_MAX = GRID_SIZE - 1
UPDATE_TIME = 0.2

-- :colors
BACKGROUND_A = hexToRGBA("1b1d1e") -- lighter
BACKGROUND_B = hexToRGBA("171819") -- darker
BACKGROUND_C = hexToRGBA("111213") -- darkest

-- :fonts
OXANIUM_REGULAR = love.graphics.newFont("assets/fonts/OXANIUM-BOLD.ttf")

-- :game vars
world = World:new(GRID_SIZE, GRID_SIZE)
local time_since_last_update = 0
local last_mouse_pos = {0, 0}
mouse_delta = {0, 0}

-- :setup functions
function setup_tree(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/tree.png"), {1, 1, 1, 1})
    SwayComponent:new(entity)
    entity.draw_priority = 5
    sprite_component.render_offset_x = love.math.random(-GRID_SIZE_HALF_PX / 2, GRID_SIZE_HALF_PX / 2)
    sprite_component.render_offset_y = love.math.random(-GRID_SIZE_HALF_PX / 2, 0.0)
    sprite_component.pivot = SPRITE_PIVOT.CENTER_BOTTOM

    HealthComponent:new(entity, 50)
    SpawnOnDeathComponent:new(entity, setup_log, "log")
end
function setup_log(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/log.png"), {1, 1, 1, 1})
    entity.draw_priority = 0
end
function setup_dude(entity)
    SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/dude.png"), {1, 1, 1, 1}, 35).pivot = SPRITE_PIVOT.CENTER_BOTTOM

    CollisionComponent:new(entity).affects_pathfinding = true
    AI_MovementComponent:new(entity)
    -- PlayerInputComponent:new(entity)
    local name_plate = TextComponent:new(entity, OXANIUM_REGULAR, "", {1, 1, 1, 1})
    name_plate.render_offset_y = GRID_SIZE_HALF_PX + 2
    name_plate.scale = 0.75

    HealthComponent:new(entity, 100)

    DudeBrainComponent:new(entity)

    DudeComponent:new(entity)

    entity.draw_priority = 10
end
function setup_chaser(entity)
    SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/dude.png"), {1, 0, 0, 1}).pivot = SPRITE_PIVOT.CENTER_BOTTOM
    CollisionComponent:new(entity).affects_pathfinding = false
    AI_MovementComponent:new(entity)
    entity.draw_priority = 10

end
function setup_rock(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/rock.png"), {1, 1, 1, 1})
    -- random offset
    entity.x = entity.x + love.math.random(-GRID_SIZE_HALF_PX / 2, GRID_SIZE_HALF_PX / 2) / GRID_SIZE_PX
    entity.y = entity.y + love.math.random(-GRID_SIZE_HALF_PX / 2, GRID_SIZE_HALF_PX / 2) / GRID_SIZE_PX

    HealthComponent:new(entity, 100)
    SpawnOnDeathComponent:new(entity, setup_stone, "stone")
end
function setup_stone(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/stone.png"), {1, 1, 1, 1})
end

function setup_grass(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/grass.png"), {1, 1, 1, 1})
    sprite_component.render_offset_x = love.math.random(-GRID_SIZE_HALF_PX / 2, GRID_SIZE_HALF_PX / 2)
    sprite_component.render_offset_y = love.math.random(-GRID_SIZE_HALF_PX / 2, 0.0)
    sprite_component.pivot = SPRITE_PIVOT.CENTER_BOTTOM
    SwayComponent:new(entity, 0.05, 0.25)
end
function setup_ruin(entity)
    SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/ruin.png"), {1, 1, 1, 1}).pivot = SPRITE_PIVOT.CENTER_BOTTOM
    entity.draw_priority = 0
    CollisionComponent:new(entity)
end
function setup_berry_bush(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/berry_bush.png"), {1, 1, 1, 1})
    sprite_component.pivot = SPRITE_PIVOT.CENTER_BOTTOM
    sprite_component.render_offset_y = -4
    sprite_component.render_offset_x = love.math.random(-GRID_SIZE_HALF_PX / 2, GRID_SIZE_HALF_PX / 2)
    sprite_component.render_offset_y = love.math.random(-GRID_SIZE_HALF_PX / 2, 0.0)
    -- sprite_component.flip_x = love.math.random(0, 1) == 1
    -- sprite_component.flip_y = love.math.random(0, 1) == 1
    FoodComponent:new(entity).priority = 0
    SwayComponent:new(entity, 0.05, 0.25)

    entity.draw_priority = 0
end
function setup_dude_corpse(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/dude_corpse.png"), {1, 1, 1, 1})
    -- sprite_component.render_offset_y = -2
    entity.draw_priority = 5
end

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
    local berry_bush = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "berry_bush", setup_berry_bush)
end

-- :trees
for i = 1, 64, 1 do
    local tree = Entity:new(love.math.random(0, GRID_MAX), love.math.random(0, GRID_MAX), "tree", setup_tree)
end

for i = 1, 1, 1 do
    local dude = Entity:new(GRID_SIZE / 2, GRID_SIZE / 2, "dude", setup_dude)
end

-- :LOVE2D

function love.load()
    love.window.setTitle("RushWorld")
    love.window.setMode(1280, 1080)
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(BACKGROUND_C)
end

function love.update(dt)
    dt = dt * world.time_scale
    time_since_last_update = time_since_last_update + dt
    if time_since_last_update >= UPDATE_TIME then
        time_since_last_update = 0
        world:update(UPDATE_TIME);
    end
    -- :update mouse delta
    local mouse_pos = {love.mouse.getX(), love.mouse.getY()}
    mouse_delta = {mouse_pos[1] - last_mouse_pos[1], mouse_pos[2] - last_mouse_pos[2]}
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

    love.graphics.print(love.timer.getFPS() .. " fps | " .. world.time_scale .. "x time-scale | " .. math.ceil(world.world_time) .. "s world-time | " .. #world.entities .. " entities", 8, love.graphics.getHeight() - 24)

    -- draw rectangle over the whole screen to represent nighttime

end

function love.keypressed(key, scancode, isrepeat)
    world:keypressed(key, scancode, isrepeat)

    if key == "space" then
        -- make sure there isn't something already there
        if world:find_entity_at_mouse() == nil then
            local x, y = world:get_current_mouse_grid_position()
            local entity = Entity:new(x, y, "tree")
            setup_ruin(entity)
        end
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
        -- find entity at x, y
        local entity = world:find_entity_at(x, y)
        if entity then
            damage_entity(entity, 100)
        end
    end

    if key == "f5" then
        print("Reloading...")
        _Debug.hotSwapUpdate()
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

