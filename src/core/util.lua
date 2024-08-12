function hexToRGBA(hex)
    -- Ensure the hex code is in the correct format (without #)
    hex = hex:gsub("#", "")

    -- Parse the hex string
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = 1.0 -- Default alpha value

    -- Return the RGBA values as a table
    return {r, g, b, a}
end

-- Checks if the difference between a and b is smaller than epsilon
function almost_equals(a, b, epsilon)
    return math.abs(a - b) <= epsilon
end

-- Animates the float value to target over time.
-- @param value current value
-- @param target target value
-- @param delta_t delta time
-- @param rate rate at which we approach.
-- @return whether or not we reached the value (true if we made it)
function interp_to(value, target, delta_t, rate)
    rate = rate / world.time_scale
    value = value + (target - value) * (1.0 - math.pow(2.0, -rate * delta_t))
    if almost_equals(value, target, 0.001) then
        value = target
        return value, true -- we made it
    end

    return value, false
end

function uuid()
    -- seed random with cpu time
    math.randomseed(os.clock() * 100000000000)
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and love.math.random(0, 0xf) or love.math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function round(num)
    return math.floor(num + 0.5)
end

function is_valid(entity)
    return entity and entity.is_valid
end

function damage_entity(entity, damage)
    health_component = entity:find_component_of_type(HealthComponent)
    if health_component then
        health_component:take_damage(damage)
    end
end

function random_bool()
    return love.math.random(0, 1) == 1
end
