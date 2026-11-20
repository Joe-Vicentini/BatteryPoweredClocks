require "TimedActions/ISBaseTimedAction"
require "BPC_ClockState"
require "luautils"

BPC_ClockAction = ISBaseTimedAction:derive("BPC_ClockAction")

-- Keep the world menu local, but allow a short walk to reach the clock.
local MENU_RANGE = 2

function BPC_ClockAction.isNear(character, object)
    local square = object and object:getSquare()
    if not square or not character:getCurrentSquare() or character:getVehicle()
        or math.floor(character:getZ()) ~= square:getZ() then return false end
    local dx = character:getX() - (square:getX() + 0.5)
    local dy = character:getY() - (square:getY() + 0.5)
    return dx * dx + dy * dy <= MENU_RANGE * MENU_RANGE
end

function BPC_ClockAction.isInReach(character, object)
    if not object or not object:getSquare() or not character:getCurrentSquare()
        or math.floor(character:getZ()) ~= object:getSquare():getZ() then return false end
    local square = luautils.getCorrectSquareForWall(character, object:getSquare())
    if not square then return false end
    return math.abs(square:getX() + 0.5 - character:getX()) <= 1.6
        and math.abs(square:getY() + 0.5 - character:getY()) <= 1.6
        and character:getCurrentSquare():canReachTo(square)
end

function BPC_ClockAction:isValid()
    if not BPC_ClockState.isClock(self.object) or self.object:getObjectIndex() == -1
        or not BPC_ClockAction.isInReach(self.character, self.object) then return false end
    local state = self.object:getModData().BPC_Clock
    if not state then return false end
    if self.mode == "remove" then
        return state.hasBattery
    elseif self.mode == "insert" then
        return not state.hasBattery and self.battery ~= nil
            and self.battery:getFullType() == "Base.Battery"
            and self.battery:getContainer() == self.container
    end
    return state.hasBattery and state.charge > 0
end

function BPC_ClockAction:waitToStart()
    self.character:faceThisObject(self.object)
    return self.character:shouldBeTurning()
end

function BPC_ClockAction:update()
    self.character:faceThisObject(self.object)
end

function BPC_ClockAction:start()
    if self.mode ~= "set" then
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "High")
    end
end

function BPC_ClockAction:perform()
    ISBaseTimedAction.perform(self)
end

function BPC_ClockAction:complete()
    if self:isValid() then
        self.callback(self.character, self.object, self.battery, self.container)
    end
    return true
end

function BPC_ClockAction:new(character, object, mode, callback, battery, container)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.mode = mode
    o.callback = callback
    o.battery = battery
    o.container = container
    -- Match vanilla ISDeviceBatteryAction for removing/inserting radio batteries.
    o.maxTime = mode == "set" and 1 or 30
    return o
end
