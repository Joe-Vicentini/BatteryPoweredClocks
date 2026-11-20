-- Show a stopped clock with the static vanilla tile as an overlay.
-- The underlying world-object sprite always remains a registered vanilla tile.
BPC_ClockVisual = {}

local STATIC_CLOCK_SPRITES = {
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

-- Recognize clocks saved by the earlier runtime-sprite experiment, even if
-- their temporary sprite could not be resolved when the chunk was loaded.
function BPC_ClockVisual.isStoppedSprite(object)
    if not object then return false end
    local original = object:getModData().BPC_RuntimeOriginalSprite
    return original ~= nil and STATIC_CLOCK_SPRITES[original] ~= nil
end

-- This name is not in the vanilla clock scripts. Its texture is the original
-- game tile, with the stationary hands painted into the artwork.
local loadedFaces = {}
local function stoppedFaceSprite(original)
    local alias = "BPC_StaticFace_" .. original
    if loadedFaces[alias] then return alias end

    local ok, name = pcall(function()
        local manager = IsoSpriteManager.instance
        local sprite = manager:getSprite(alias) or manager:AddSprite(alias)
        if not sprite then return nil end
        if not sprite:LoadSingleTexture(original) then return nil end
        return alias
    end)
    if ok and name then
        loadedFaces[alias] = true
        return name
    end
    -- Keep the already-tested handless overlay if the texture is unavailable.
    return original
end

local function overlayName(object)
    local sprite = object:getOverlaySprite()
    return sprite and sprite:getName() or nil
end

function BPC_ClockVisual.sync(object, state)
    if (isClient and isClient()) or (isServer and isServer()) then return end

    local data = object:getModData()
    local legacySprite = data.BPC_RuntimeOriginalSprite
    if legacySprite then
        if not STATIC_CLOCK_SPRITES[legacySprite] then return end
        local restored = pcall(function() object:setSpriteFromName(legacySprite) end)
        if not restored then return end
        data.BPC_RuntimeOriginalSprite = nil
        object:transmitModData()
    end

    if state.hasBattery and state.charge > 0 then
        if data.BPC_StoppedOverlay then
            local previous = data.BPC_PreviousOverlaySprite
            local restored = pcall(function()
                object:setOverlaySprite(type(previous) == "string" and previous or nil, false)
            end)
            if restored then
                data.BPC_StoppedOverlay = nil
                data.BPC_PreviousOverlaySprite = nil
                object:transmitModData()
            end
        end
        return
    end

    local staticSprite = STATIC_CLOCK_SPRITES[object:getSpriteName()]
    if not staticSprite then return end
    local faceSprite = stoppedFaceSprite(staticSprite)
    if data.BPC_StoppedOverlay and overlayName(object) == faceSprite then return end

    local previous = data.BPC_PreviousOverlaySprite
    if not data.BPC_StoppedOverlay then
        previous = overlayName(object) or false
    end
    local applied = pcall(function() object:setOverlaySprite(faceSprite, false) end)
    if not applied then return end
    data.BPC_PreviousOverlaySprite = previous
    data.BPC_StoppedOverlay = true
    object:transmitModData()
end
