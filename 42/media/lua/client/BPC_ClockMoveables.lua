require "BPC_ClockState"
require "Moveables/ISMoveableSpriteProps"

-- Vanilla moveables do not preserve ordinary IsoObject mod data on pickup.
-- Keep the clock's frozen time on the carried item and return its battery only
-- after the furniture has actually been picked up.
local originalPickUp = ISMoveableSpriteProps.pickUpMoveableInternal
function ISMoveableSpriteProps:pickUpMoveableInternal(character, square, object, spriteInstance, spriteName, createItem, rotating)
    local state
    if createItem and not rotating and BPC_ClockState.isClock(object)
        and not ((isClient and isClient()) or (isServer and isServer())) then
        state = BPC_ClockState.update(object)
    end

    local item = originalPickUp(self, character, square, object, spriteInstance, spriteName, createItem, rotating)
    if state and item and item:getContainer() == character:getInventory() then
        item:getModData().BPC_ClockCarryMinutes = state.displayedMinutes
        if state.hasBattery then
            local battery = character:getInventory():AddItem("Base.Battery")
            if battery then
                battery:setCurrentUsesFloat(math.max(0, math.min(1, state.charge / 100)))
            end
        end
    end
    return item
end

-- placeMoveable() is also called while rotating furniture (forceAllow=true).
-- Limit the reset to actual placement from inventory, not rotations.
local originalPlace = ISMoveableSpriteProps.placeMoveable
function ISMoveableSpriteProps:placeMoveable(character, square, spriteName, forceAllow)
    if (isClient and isClient()) or (isServer and isServer()) then
        return originalPlace(self, character, square, spriteName, forceAllow)
    end
    local previous = self.BPC_PlacingClockFromInventory
    self.BPC_PlacingClockFromInventory = not forceAllow
    local ok, result = pcall(originalPlace, self, character, square, spriteName, forceAllow)
    self.BPC_PlacingClockFromInventory = previous
    if not ok then error(result) end
    return result
end

local originalPlaceInternal = ISMoveableSpriteProps.placeMoveableInternal
function ISMoveableSpriteProps:placeMoveableInternal(square, item, spriteName)
    local object = originalPlaceInternal(self, square, item, spriteName)
    if not self.BPC_PlacingClockFromInventory or not BPC_ClockState.isClock(object) then
        return object
    end

    local minutes = tonumber(item and item:getModData().BPC_ClockCarryMinutes)
        or getGameTime():getTimeOfDay() * 60
    local data = object:getModData()
    data.BPC_Clock = {
        hasBattery = false,
        charge = 0,
        displayedMinutes = (minutes % 1440 + 1440) % 1440,
        updatedHours = getGameTime():getWorldAgeHours(),
    }
    -- The newly placed object must rebuild its own stopped overlay.
    data.BPC_ClockCarryMinutes = nil
    data.BPC_StoppedOverlay = nil
    data.BPC_PreviousOverlaySprite = nil
    object:transmitModData()
    BPC_ClockVisual.sync(object, data.BPC_Clock)
    return object
end
