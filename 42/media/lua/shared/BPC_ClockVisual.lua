-- Experimental: render stopped clocks using a new sprite name with vanilla artwork.
-- Only the existing world object is changed; no replacement object is created.
-- Set false to restore vanilla sprites when clocks are next encountered.
local TEST_RUNTIME_STATIC_CLOCKS = true

BPC_ClockVisual = {}

-- Source tiles from Build 42's generated clocks.txt, plus two earlier variants.
local STATIC_TEXTURES = {
    location_community_school_01_32 = "location_community_school_01_32",
    location_community_school_01_33 = "location_community_school_01_33",
    location_community_school_01_34 = "location_community_school_01_34",
    location_community_school_01_35 = "location_community_school_01_35",
    walls_decoration_01_104 = "walls_decoration_01_104",
    walls_decoration_01_105 = "walls_decoration_01_105",
    walls_detailing_02_56 = "walls_detailing_02_56",
    walls_detailing_02_57 = "walls_detailing_02_57",
    walls_detailing_02_58 = "walls_detailing_02_58",
    walls_detailing_02_59 = "walls_detailing_02_59",
    animated_clock_01_0 = "location_community_school_01_32",
    animated_clock_01_1 = "location_community_school_01_33",
    animated_clock_01_2 = "walls_decoration_01_104",
    animated_clock_01_3 = "walls_decoration_01_105",
    animated_clock_01_4 = "walls_detailing_02_56",
    animated_clock_01_5 = "walls_detailing_02_57",
    animated_clock_01_6 = "walls_detailing_02_58",
    animated_clock_01_7 = "walls_detailing_02_59",
}

local spriteCache = {}
local activeObjects = {}

function BPC_ClockVisual.isStoppedSprite(object)
    if not object then return false end
    local original = object:getModData().BPC_RuntimeOriginalSprite
    return original ~= nil and STATIC_TEXTURES[original] ~= nil
end

local function makeStaticSprite(original, baseSprite)
    local success, result = pcall(function()
        local sprite = IsoSprite.new()
        if not sprite:LoadSingleTexture(STATIC_TEXTURES[original]) then return nil end
        sprite:setName("BPC_Stopped_" .. original)
        sprite:AddProperties(baseSprite)
        return sprite
    end)
    if success then return result end
    return nil
end

-- A runtime sprite has no persistent tile ID. Restore every tracked vanilla
-- sprite before the single-player world is saved, avoiding unresolvable tiles.
local function restoreOriginal(object)
    local data = object:getModData()
    local original = data.BPC_RuntimeOriginalSprite
    if not original then
        activeObjects[object] = nil
        return
    end
    local success = pcall(function()
        if object:getSpriteName() ~= original then
            object:setSpriteFromName(original)
        end
    end)
    if success then
        data.BPC_RuntimeOriginalSprite = nil
        activeObjects[object] = nil
        object:transmitModData()
    end
end

function BPC_ClockVisual.restoreBeforeSave()
    for object in pairs(activeObjects) do
        restoreOriginal(object)
    end
end

if Events and Events.OnSave then
    Events.OnSave.Add(BPC_ClockVisual.restoreBeforeSave)
end

function BPC_ClockVisual.sync(object, state)
    -- Runtime-only sprites aren't synchronized across multiplayer clients.
    if (isClient and isClient()) or (isServer and isServer()) then return end

    local data = object:getModData()
    local original = data.BPC_RuntimeOriginalSprite
    local running = state.hasBattery and state.charge > 0

    if not TEST_RUNTIME_STATIC_CLOCKS or running then
        if original then restoreOriginal(object) end
        return
    end

    original = original or object:getSpriteName()
    if not STATIC_TEXTURES[original] then return end
    local name = "BPC_Stopped_" .. original
    if object:getSpriteName() == name then return end

    local baseSprite = object:getSprite()
    if not baseSprite then return end
    -- When a save reloads a stopped clock, its vanilla sprite ID restores the
    -- original tile; reapply the custom visual next time it is encountered.
    local sprite = spriteCache[original]
    if not sprite then
        sprite = makeStaticSprite(original, baseSprite)
        if not sprite then return end
        spriteCache[original] = sprite
    end

    local success = pcall(function() object:setSprite(sprite) end)
    if success then
        data.BPC_RuntimeOriginalSprite = original
        activeObjects[object] = true
        object:transmitModData()
    end
end
