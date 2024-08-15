-- :ambience
am_forest_ambience = love.audio.newSource("assets/sounds/forest_ambience.wav", "static")
am_forest_ambience:setLooping(true)
am_forest_ambience:setVolume(0.5)

-- :sfx
sfx_place_object = love.audio.newSource("assets/sounds/sfx/place_object.wav", "static")
sfx_place_object:setVolume(0.1)

sfx_error_placing = love.audio.newSource("assets/sounds/sfx/error_placing.wav", "static")
sfx_error_placing:setVolume(0.1)

-- :music
