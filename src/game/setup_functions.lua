-- :setup functions
function setup_tree(entity)
    local sprite_component = SpriteComponent:new(entity, love.graphics.newImage("assets/sprites/tree.png"), {1, 1, 1, 1})
    SwayComponent:new(entity)
    entity.draw_priority = 5
    sprite_component.pivot = SPRITE_PIVOT.CENTER_BOTTOM
    sprite_component.render_offset_y = -4

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
    --PlayerInputComponent:new(entity)
    -- local name_plate = TextComponent:new(entity, OXANIUM_REGULAR, "", {1, 1, 1, 1})
    -- name_plate.render_offset_y = GRID_SIZE_HALF_PX + 2
    -- name_plate.scale = 0.75
    
    HealthComponent:new(entity, 100)
    
    AI_MovementComponent:new(entity)
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