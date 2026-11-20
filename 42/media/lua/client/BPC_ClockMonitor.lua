require "BPC_ClockState"

-- Only track clocks in currently loaded chunks; no world-wide scans.
local trackedClocks = {}

local function checkClock(object)
    if BPC_ClockState.isClock(object) then
        local _, activeObject = BPC_ClockState.update(object)
        trackedClocks[activeObject] = true
    end
end

local function checkChunk(chunk)
    if (isClient and isClient()) or (isServer and isServer()) then return end
    if not chunk then return end
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for x = 0, 9 do
            for y = 0, 9 do
                local square = chunk:getGridSquare(x, y, z)
                if square then
                    local objects = square:getObjects()
                    for i = 0, objects:size() - 1 do
                        checkClock(objects:get(i))
                    end
                end
            end
        end
    end
end

local function updateLoadedClocks()
    if (isClient and isClient()) or (isServer and isServer()) then return end
    local cell = getCell()
    if not cell then return end
    for object in pairs(trackedClocks) do
        local square = object:getSquare()
        if not square or cell:getGridSquare(square:getX(), square:getY(), square:getZ()) ~= square
            or not BPC_ClockState.isClock(object) then
            trackedClocks[object] = nil
        else
            local _, activeObject = BPC_ClockState.update(object)
            if activeObject ~= object then
                trackedClocks[object] = nil
                trackedClocks[activeObject] = true
            end
        end
    end
end

-- LoadChunk fires once per loaded 10x10 chunk, rather than once per square.
Events.LoadChunk.Add(checkChunk)
Events.EveryOneMinute.Add(updateLoadedClocks)

-- Initial chunks can load before OnGameStart in a resumed single-player game.
Events.OnGameStart.Add(function()
    if (isClient and isClient()) or (isServer and isServer()) then return end
    local player = getPlayer()
    if not player or not player:getSquare() then return end
    local square = player:getSquare()
    local cell = getCell()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local x = math.floor(square:getX() / 10) * 10 + dx * 10
            local y = math.floor(square:getY() / 10) * 10 + dy * 10
            local chunk = cell:getChunkForGridSquare(x, y, square:getZ())
            if chunk then checkChunk(chunk) end
        end
    end
end)
