local Vector = require("src.libs.vector")
local Heap = require("src.libs.heap")

local astar = {}
astar.__index = astar

local Node = {}
Node.__index = Node

function Node:new(x, y, parent)
    local node = {
        x = x,
        y = y,
        parent = parent,
        gScore = math.huge,
        hScore = 0,
        fScore = math.huge,
        walkable = true
    }
    setmetatable(node, Node)
    return node
end

function Node:ID()
    return self.x .. "," .. self.y
end

local function distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy -- Using squared distance for efficiency
end

function astar:get_neighbors(pos)
    local neighbors = {}
    local directions = {Vector(0, -1), Vector(1, 0), Vector(0, 1), Vector(-1, 0)}

    for _, dir in ipairs(directions) do
        local newPos = Vector(pos.x + dir.x, pos.y + dir.y)
        if self:is_walkable(newPos.x, newPos.y) then
            table.insert(neighbors, newPos)
        end
    end

    return neighbors
end

function astar:new_grid(width, height)
    self.grid = {}
    for y = 0, height - 1 do
        self.grid[y] = {}
        for x = 0, width - 1 do
            self.grid[y][x] = Node:new(x, y)
        end
    end
end

function astar:generate_nodes()
    local nodes = {}

    if not self.grid then
        print("No grid found")
        return nodes
    end

    for y, row in pairs(self.grid) do
        nodes[y] = {}
        for x, cell in pairs(row) do
            nodes[y][x] = Node:new(x, y)
            nodes[y][x].walkable = cell.walkable
        end
    end

    return nodes
end

function astar:set_walkable(x, y, walkable)
    if not self.grid then
        return
    end
    if not self.grid[y] or not self.grid[y][x] then
        return
    end

    self.grid[y][x].walkable = walkable
end

function astar:is_walkable(x, y)
    if not self.grid then
        return false
    end
    if not self.grid[y] or not self.grid[y][x] then
        return false
    end

    return self.grid[y][x].walkable
end

function astar:find_closest_walkable(nodes, target_pos)
    local min_distance = math.huge
    local closest_node = nil

    for y = #nodes, 1, -1 do -- Start from the bottom row and move upwards
        for x, node in pairs(nodes[y]) do
            if node.walkable then
                local dist = distance(node, target_pos)
                if dist < min_distance then
                    min_distance = dist
                    closest_node = node
                end
            end
        end
    end

    return closest_node
end

function astar:path(start_pos, finish_pos)
    local open = Heap()
    local closed = {}
    local nodes = self:generate_nodes()



    if start_pos.x == finish_pos.x and start_pos.y == finish_pos.y then
        -- just return a path with the start position  
        return {start_pos}
    end

    local finish = nodes[finish_pos.y] and nodes[finish_pos.y][finish_pos.x] or nil

    -- set the start an end nodes to walkable
    nodes[start_pos.y][start_pos.x].walkable = true
    --nodes[finish_pos.y][finish_pos.x].walkable = true

    if not finish or not self:is_walkable(finish_pos.x, finish_pos.y) then
        -- If the finish position is non-walkable, search for the closest walkable tile
        finish = self:find_closest_walkable(nodes, finish_pos)
        if not finish then
            return {} -- No walkable tile found
        end
    end

    

    local start = nodes[start_pos.y][start_pos.x]

    start.gScore = 0
    start.hScore = distance(start, finish)
    start.fScore = start.gScore + start.hScore

    open.Compare = function(a, b)
        return a.fScore < b.fScore
    end

    open:Push(start)
    local best_node = start
    local best_distance = start.hScore

    while not open:Empty() do
        local current = open:Pop()
        local currentId = current:ID()

        if not closed[currentId] then
            if current.x == finish.x and current.y == finish.y then
                local path = {}
                while current do
                    table.insert(path, 1, {
                        x = current.x,
                        y = current.y
                    })
                    current = current.parent
                end
                return path
            end

            closed[currentId] = true

            -- Track the best node (closest to the finish)
            local current_distance = distance(current, finish)
            if current_distance < best_distance then
                best_node = current
                best_distance = current_distance
            end

            local neighbors = self:get_neighbors(Vector(current.x, current.y))
            for _, neighborPos in ipairs(neighbors) do
                local neighbor = nodes[neighborPos.y][neighborPos.x]
                local tentative_gScore = current.gScore + distance(current, neighbor)

                if not closed[neighbor:ID()] and (not neighbor.gScore or tentative_gScore < neighbor.gScore) then
                    neighbor.gScore = tentative_gScore
                    neighbor.hScore = distance(neighbor, finish)
                    neighbor.fScore = neighbor.gScore + neighbor.hScore
                    neighbor.parent = current

                    open:Push(neighbor)
                end
            end
        end
    end

    -- Return the best partial path found so far
    local path = {}
    while best_node do
        table.insert(path, 1, {
            x = best_node.x,
            y = best_node.y
        })
        best_node = best_node.parent
    end

    return path
end

function astar:rough_path(start_pos, finish_pos, depth_limit)
    local open = Heap()
    local closed = {}
    local nodes = self:generate_nodes()

    local finish = nodes[finish_pos.y] and nodes[finish_pos.y][finish_pos.x] or nil

    if not finish or not self:is_walkable(finish_pos.x, finish_pos.y) then
        -- If the finish position is non-walkable, search for the closest walkable tile
        finish = self:find_closest_walkable(nodes, finish_pos)
        if not finish then
            return {} -- No walkable tile found
        end
    end

    local start = nodes[start_pos.y][start_pos.x]

    start.hScore = distance(start, finish)
    open.Compare = function(a, b)
        return a.hScore < b.hScore -- Prioritize hScore only
    end

    open:Push(start)
    local depth = 0

    local best_node = start
    local best_distance = start.hScore

    while not open:Empty() do
        local current = open:Pop()
        local currentId = current:ID()

        if not closed[currentId] then
            -- Exit early if the depth limit is reached
            if depth >= depth_limit then
                break
            end

            if current.x == finish.x and current.y == finish.y then
                local path = {}
                while current do
                    table.insert(path, 1, {
                        x = current.x,
                        y = current.y
                    })
                    current = current.parent
                end
                return path
            end

            closed[currentId] = true

            -- Track the best node (closest to the finish)
            local current_distance = distance(current, finish)
            if current_distance < best_distance then
                best_node = current
                best_distance = current_distance
            end

            local neighbors = self:get_neighbors(Vector(current.x, current.y))
            for _, neighborPos in ipairs(neighbors) do
                local neighbor = nodes[neighborPos.y][neighborPos.x]
                if not closed[neighbor:ID()] then
                    neighbor.hScore = distance(neighbor, finish)
                    neighbor.parent = current
                    open:Push(neighbor)
                end
            end
        end
        depth = depth + 1
    end

    -- Return the best partial path found so far
    local path = {}
    while best_node do
        table.insert(path, 1, {
            x = best_node.x,
            y = best_node.y
        })
        best_node = best_node.parent
    end

    return path
end

function astar:new(x, y)
    local self = setmetatable({}, astar)

    self.x = x
    self.y = y

    self.grid = {}
    self:new_grid(x, y)

    return self
end

return astar
