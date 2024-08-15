--- Utility functions for the engine.
---@param hex string
---@return table {number, number, number, number}
function hexToRGBA(hex)
    -- Ensure the hex code is in the correct format (without #)
    hex = hex:gsub("#", "")

    -- Parse the hex string
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = 1.0 -- Default alpha value

    -- Return the RGBA values as a table
    return { r, g, b, a }
end

---returns if a value is almost equal to another value.
---@param a number
---@param b number
---@param epsilon number
---@return boolean
function almost_equals(a, b, epsilon)
    return math.abs(a - b) <= epsilon
end

---interpolates a value towards a target value.
---@param value number
---@param target number
---@param delta_t number
---@param rate number
---@return number value
---@return boolean reached
function interp_to(value, target, delta_t, rate)
    rate = rate / world.time_scale
    value = value + (target - value) * (1.0 - math.pow(2.0, -rate * delta_t))
    if almost_equals(value, target, 0.001) then
        value = target
        return value, true -- we made it
    end

    return value, false
end

---rounds a number to the nearest integer.
---@param num number
---@return integer
function round(num)
    return math.floor(num + 0.5)
end

---whether or not an entity is valid.
---@param entity entity
---@return boolean
function is_valid(entity)
    return entity and entity.is_valid
end

---if an entity has a health component, apply damage to it.
---@param entity entity
---@param damage number
function damage_entity(entity, damage)
    health_component = entity:find_component_of_type(HealthComponent)
    if health_component then
        health_component:take_damage(damage)
    end
end

---returns a random boolean value.
---@return boolean
function random_bool()
    return love.math.random(0, 1) == 1
end

-- checks if any of the entitys in the list have a component of the given type
---@param entities table
---@param component_type component
function any_entity_has_component_of_type(entities, component_type)
    for i, entity in ipairs(entities) do
        if entity:find_component_of_type(component_type) then
            return true
        end
    end
    return false
end

---comment
---@param value number the number
---@param in_min number the minimum value of the input range
---@param in_max number the maximum value of the input range
---@param out_min number the value when the input is in_min
---@param out_max number the value when the input is in_max
---@return number the mapped value
function map_to_range(value, in_min, in_max, out_min, out_max)
    return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

--- :v2

---returns v2 a + b.
---@param a any {number, number}
---@param b any {number, number}
---@return table {number, number}
function v2_add(a, b)
    return { a[1] + b[1], a[2] + b[2] }
end

---returns v2 a - b.
---@param a any {number, number}
---@param b any {number, number}
---@return table {number, number}
function v2_sub(a, b)
    return { a[1] - b[1], a[2] - b[2] }
end

---returns v2 a * b.
---@param a any {number, number}
---@param b any {number, number}
---@return table {number, number}
function v2_mul(a, b)
    return { a[1] * b[1], a[2] * b[2] }
end

--- :sound related

--- plays a sound, with its volume determined by camera distance/zoom
--- @param sound sound
--- @param x number
--- @param y number
--- @param audible_distance number
function play_sound(sound, x, y, audible_distance)
    local distance = v2_len(v2_sub({ x, y }, { world.camera.x, world.camera.y }))
    local volume = 1.0 - math.min(distance / audible_distance, 1.0)
    sound:setVolume(volume)
    sound:play()
end
