-- Experimental Build 42 stopped-clock object replacement.
-- Disabled after the unsuccessful object-replacement test. Existing dummies are
-- restored to regular clock objects when encountered.
local TEST_DUMMY_CLOCKS = false

BPC_ClockSwap = {}

-- Vanilla mappings from media/scripts/generated/clocks.txt, plus two known variants.
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

function BPC_ClockSwap.isDummy(object)
    return object and object:getModData().BPC_Dummy == true
end

local function replaceObject(object, sprite, makeDummy, originalSprite, state)
    local square = object:getSquare()
    if not square then return object, state, false end
    local objects = square:getObjects()
    local index = objects:indexOf(object)
    if index < 0 then return object, state, false end

    -- Prepare the replacement fully before touching the world square.
    local created, replacement = pcall(function()
        return IsoObject.new(getCell(), square, sprite)
    end)
    if not created or not replacement then return object, state, false end
    local sourceData = object:getModData()
    local targetData = replacement:getModData()
    for key, value in pairs(sourceData) do
        targetData[key] = value
    end
    local nextState = {}
    for key, value in pairs(state) do
        nextState[key] = value
    end
    nextState.preStopSprite = nil -- Compatibility with the previous sprite-only experiment.
    targetData.BPC_Clock = nextState
    targetData.BPC_Dummy = makeDummy and true or nil
    targetData.BPC_OriginalSprite = makeDummy and originalSprite or nil

    -- These square methods also transmit the object replacement.
    -- Never add the same object through AddTileObject as well.
    local ok = pcall(function()
        square:transmitRemoveItemFromSquare(object)
        if objects:indexOf(object) < 0 then
            square:transmitAddObjectToSquare(replacement, index)
        end
    end)
    if not ok or objects:indexOf(replacement) < 0 then
        -- Best-effort rollback if an engine call fails.
        pcall(function()
            if objects:indexOf(replacement) >= 0 then
                square:transmitRemoveItemFromSquare(replacement)
            end
            if objects:indexOf(object) < 0 then
                square:transmitAddObjectToSquare(object, index)
            end
        end)
        return object, state, false
    end
    return replacement, nextState, true
end

-- Returns the current world object, its persistent clock state, and success.
function BPC_ClockSwap.sync(object, state)
    -- The experimental replacement is single-player only until server authority is tested.
    if isClient and isClient() then return object, state, true end

    local running = state.hasBattery and state.charge > 0
    if BPC_ClockSwap.isDummy(object) then
        if not TEST_DUMMY_CLOCKS or running then
            local originalSprite = object:getModData().BPC_OriginalSprite
            if not originalSprite then return object, state, false end
            return replaceObject(object, originalSprite, false, nil, state)
        end
        return object, state, true
    end

    if TEST_DUMMY_CLOCKS and not running then
        local originalSprite = state.preStopSprite or object:getSpriteName()
        local staticSprite = STATIC_CLOCK_SPRITES[object:getSpriteName()]
            or STATIC_CLOCK_SPRITES[originalSprite]
        if not staticSprite then return object, state, true end
        return replaceObject(object, staticSprite, true, originalSprite, state)
    end
    return object, state, true
end
