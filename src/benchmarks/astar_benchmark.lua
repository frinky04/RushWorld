-- Building 100 x 100 sized map.
-- Generating 2000 random start/finish positions.
-- Finding 1000 paths.
-- measure time in seconds overall
-- get average time per path
function astar_benchmark()
    local start = love.timer.getTime()
    local astar = AStar:new(100, 100)

    local paths = 0
    for i = 1, 1000, 1 do
        local start_x = love.math.random(0, 99)
        local start_y = love.math.random(0, 99)
        local finish_x = love.math.random(0, 99)
        local finish_y = love.math.random(0, 99)

        local path = astar:path({
            x = start_x,
            y = start_y
        }, {
            x = finish_x,
            y = finish_y
        })
        if path then
            paths = paths + 1
        end
    end

    local finish = love.timer.getTime()
    print("Time taken: " .. finish - start .. " seconds to find " .. paths .. " precise paths.")
    print("Average time per path: " .. (finish - start) / paths .. " seconds.")

    -- cleanup
    astar = nil
    collectgarbage()
end

function astar_rough_benchmark()
    local start = love.timer.getTime()
    local astar = AStar:new(100, 100)

    local paths = 0
    for i = 1, 1000, 1 do
        local start_x = love.math.random(0, 99)
        local start_y = love.math.random(0, 99)
        local finish_x = love.math.random(0, 99)
        local finish_y = love.math.random(0, 99)

        local path = astar:rough_path({
            x = start_x,
            y = start_y
        }, {
            x = finish_x,
            y = finish_y
        }, 5)
        if path then
            paths = paths + 1
        end
    end

    local finish = love.timer.getTime()
    print("Time taken: " .. finish - start .. " seconds to find " .. paths .. " rough paths.")
    print("Average time per path: " .. (finish - start) / paths .. " seconds.")

    -- cleanup
    astar = nil
    collectgarbage()
end
