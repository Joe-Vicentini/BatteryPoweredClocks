-- Clock state lives on each encountered world object, never in a map-wide registry.
BPC_ClockState = {}

local CLOCK_SPRITES = {
    location_community_school_01_32 = true, -- Wall Clock
    walls_decoration_01_105 = true,        -- Square Wall Clock
}

local function options()
    return SandboxVars.BatteryPoweredClocks or {}
end

local function nowHours()
    return getGameTime():getWorldAgeHours()
end

local function nowMinutes()
    return getGameTime():getTimeOfDay() * 60
end

local function wrapMinutes(minutes)
    return (minutes % 1440 + 1440) % 1440
end

local function drainRate()
    return math.max(0, tonumber(options().DrainPerDay) or 0.5) / 24
end

function BPC_ClockState.isClock(object)
    if not object or not object:getSquare() then return false end
    local sprite = object:getSpriteName()
    return sprite ~= nil and CLOCK_SPRITES[sprite] == true
end

-- A clock is only initialized when a player opens its context menu.
function BPC_ClockState.get(object)
    local data = object:getModData()
    if data.BPC_Clock then return data.BPC_Clock end

    local hours = nowHours()
    local minCharge = math.max(0, math.min(100, tonumber(options().MinInitialCharge) or 20))
    local initial = minCharge + (100 - minCharge) * ZombRand(10001) / 10000
    local rate = drainRate()
    local age = options().AgeInitialBatteries ~= false and hours or 0
    local charge = math.max(0, initial - age * rate)
    local stoppedHours = hours
    if charge <= 0 and rate > 0 and age > 0 then
        -- The battery would have run flat before the player encountered it.
        stoppedHours = hours - (age - initial / rate)
    end
    local dataClock = {
        charge = charge,
        hasBattery = true,
        displayedMinutes = wrapMinutes(nowMinutes() - (hours - stoppedHours) * 60),
        updatedHours = hours,
    }
    data.BPC_Clock = dataClock
    object:transmitModData()
    return dataClock
end

function BPC_ClockState.update(object)
    local state = BPC_ClockState.get(object)
    local hours = nowHours()
    local elapsed = math.max(0, hours - (state.updatedHours or hours))
    if state.hasBattery and state.charge > 0 and elapsed > 0 then
        local rate = drainRate()
        local workingHours = rate > 0 and math.min(elapsed, state.charge / rate) or elapsed
        state.displayedMinutes = wrapMinutes(state.displayedMinutes + workingHours * 60)
        state.charge = math.max(0, state.charge - elapsed * rate)
    end
    state.updatedHours = hours
    return state
end

function BPC_ClockState.isRunning(state)
    return state.hasBattery and state.charge > 0
end

function BPC_ClockState.isOutOfSync(state)
    local delta = math.abs(wrapMinutes(state.displayedMinutes - nowMinutes()))
    return math.min(delta, 1440 - delta) > 1
end

function BPC_ClockState.setTime(object)
    local state = BPC_ClockState.update(object)
    if not BPC_ClockState.isRunning(state) then return end
    state.displayedMinutes = wrapMinutes(nowMinutes())
    object:transmitModData()
end

function BPC_ClockState.removeBattery(object)
    local state = BPC_ClockState.update(object)
    if not state.hasBattery then return nil end
    local charge = state.charge
    state.charge = 0
    state.hasBattery = false
    object:transmitModData()
    return charge
end

function BPC_ClockState.insertBattery(object, charge, hasWatch)
    local state = BPC_ClockState.update(object)
    if state.hasBattery then return false end
    state.charge = math.max(0, math.min(100, charge))
    state.hasBattery = true
    if BPC_ClockState.isRunning(state)
        and options().AutoSetOnReplace ~= false and hasWatch then
        state.displayedMinutes = wrapMinutes(nowMinutes())
    end
    object:transmitModData()
    return true
end

function BPC_ClockState.formatTime(state)
    local minutes = math.floor(wrapMinutes(state.displayedMinutes))
    return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end
