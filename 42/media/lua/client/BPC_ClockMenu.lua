require "BPC_ClockState"
require "BPC_ClockAction"

local function findWatch(container)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local typeName = item:getType()
        if typeName and (typeName:find("WristWatch", 1, true)
            or typeName:find("DigitalWatch", 1, true)
            or typeName:find("ClassicWatch", 1, true)) then
            return true
        end
        if item:IsInventoryContainer() and findWatch(item:getInventory()) then
            return true
        end
    end
    return false
end

local function collectBatteries(container, batteries)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == "Base.Battery" then
            batteries[#batteries + 1] = { item = item, container = container }
        end
        if item:IsInventoryContainer() then
            collectBatteries(item:getInventory(), batteries)
        end
    end
end

-- Use identical rounding and percent formatting in both battery menus.
local function formatCharge(charge)
    local percent = math.floor(math.max(0, math.min(100, charge)) + 0.5)
    return string.format("%d%%", percent)
end

local function batteryCharge(battery)
    return math.max(0, math.min(100, battery:getCurrentUsesFloat() * 100))
end

local function finishRemoveBattery(player, object)
    if not BPC_ClockState.isClock(object) then return end
    local charge = BPC_ClockState.removeBattery(object)
    if not charge then return end
    local item = player:getInventory():AddItem("Base.Battery")
    if item then
        item:setCurrentUsesFloat(math.max(0, math.min(1, charge / 100)))
    end
end

local function finishInsertBattery(player, object, battery, container)
    if not BPC_ClockState.isClock(object) then return end
    local state = BPC_ClockState.update(object)
    if state.hasBattery then return end
    if not battery or battery:getFullType() ~= "Base.Battery"
        or battery:getContainer() ~= container then return end
    local charge = batteryCharge(battery)
    if not BPC_ClockState.insertBattery(object, charge, findWatch(player:getInventory())) then return end
    container:Remove(battery)
end

local function finishSetClock(player, object)
    if BPC_ClockState.isClock(object) and findWatch(player:getInventory()) then
        BPC_ClockState.setTime(object)
    end
end

local function queueClockAction(player, object, mode, callback, battery, container)
    if not BPC_ClockState.isClock(object) or not BPC_ClockAction.isNear(player, object) then return end
    if luautils.walkAdjObject(player, object, true, true) then
        ISTimedActionQueue.add(BPC_ClockAction:new(player, object, mode, callback, battery, container))
    end
end

local function removeBattery(player, object)
    queueClockAction(player, object, "remove", finishRemoveBattery)
end

local function insertBattery(player, object, battery, container)
    queueClockAction(player, object, "insert", finishInsertBattery, battery, container)
end

local function setClock(player, object)
    queueClockAction(player, object, "set", finishSetClock)
end

-- Build 42's world-menu element system runs even when the legacy menu finds no interaction.
local function fillClockMenu(data)
    local player = data.player
    local context = data.context
    if not player or not context then return false end

    local seenObjects = {}
    local seenSquares = {}
    local clickedSquares = {}
    local foundClock = false

    local function addClock(object)
        if not object or seenObjects[object] then return false end
        seenObjects[object] = true
        if not BPC_ClockState.isClock(object) or not BPC_ClockAction.isNear(player, object) then return false end
        foundClock = true
        if data.test then return true end

        local state, activeObject = BPC_ClockState.update(object)
        seenObjects[activeObject] = true
        if state.hasBattery then
            local removeOption = context:addOption(
                getText("ContextMenu_BPC_RemoveBattery") .. " (" .. formatCharge(state.charge) .. ")",
                player, removeBattery, activeObject)
            removeOption.iconTexture = getTexture("Item_Battery")
        else
            local batteries = {}
            collectBatteries(player:getInventory(), batteries)
            local option = context:addOption(getText("ContextMenu_BPC_InsertBattery"), nil, nil)
            local subMenu = context:getNew(context)
            context:addSubMenu(option, subMenu)
            if #batteries == 0 then
                local missing = subMenu:addOption(getText("ContextMenu_BPC_NoBatteryFound"), nil, nil)
                missing.notAvailable = true
            else
                for _, entry in ipairs(batteries) do
                    local battery = entry.item
                    local charge = batteryCharge(battery)
                    local batteryOption = subMenu:addOption(
                        string.format("%s (%s)", battery:getDisplayName(), formatCharge(charge)),
                        player, insertBattery, activeObject, battery, entry.container)
                    batteryOption.iconTexture = battery:getTex()
                end
            end
        end

        if BPC_ClockState.isRunning(state) and BPC_ClockState.isOutOfSync(state)
            and findWatch(player:getInventory()) then
            context:addOption(getText("ContextMenu_BPC_SetClock"),
                player, setClock, activeObject)
        end
        return false
    end

    local function checkSquare(square)
        if not square or seenSquares[square] then return false end
        seenSquares[square] = true
        clickedSquares[#clickedSquares + 1] = square
        local objects = square:getObjects()
        for i = 0, objects:size() - 1 do
            if addClock(objects:get(i)) then return true end
        end
        return false
    end

    -- Only examine objects/squares supplied by the clicked context menu.
    for _, object in ipairs(data.objects or {}) do
        if addClock(object) then return true end
        if object and checkSquare(object:getSquare()) then return true end
    end
    if data.object then
        if addClock(data.object) then return true end
        if checkSquare(data.object:getSquare()) then return true end
    end
    for _, square in ipairs(data.squares or {}) do
        if checkSquare(square) then return true end
    end

    -- The back of a north/west-wall clock may be clicked from the next tile,
    -- while its actual IsoObject belongs to the tile south/east of that click.
    -- Only recover a previously encountered clock with its battery removed.
    if not foundClock then
        for _, square in ipairs(clickedSquares) do
            local adjacent = { square:getS() or false, square:getE() or false }
            for _, neighbor in ipairs(adjacent) do
                if neighbor then
                    local objects = neighbor:getObjects()
                    for i = 0, objects:size() - 1 do
                        local object = objects:get(i)
                        if not seenObjects[object] and BPC_ClockState.isClock(object) then
                            local state = object:getModData().BPC_Clock
                            if state and state.hasBattery == false then
                                if addClock(object) then return true end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Registered before the vanilla world-menu elements are instantiated on game start.
ISWorldMenuElements = ISWorldMenuElements or {}
ISWorldMenuElements.BatteryPoweredClocks = function()
    local element = ISMenuElement.new()
    function element.createMenu(data)
        return fillClockMenu(data)
    end
    return element
end
