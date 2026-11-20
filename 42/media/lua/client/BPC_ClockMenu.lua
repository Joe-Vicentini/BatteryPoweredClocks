require "BPC_ClockState"

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

local function roundCharge(charge)
    return math.floor(math.max(0, math.min(100, charge)) + 0.5)
end

local function removeBattery(player, object)
    if not BPC_ClockState.isClock(object) then return end
    local charge = BPC_ClockState.removeBattery(object)
    if not charge then return end
    local item = player:getInventory():AddItem("Base.Battery")
    if item and item.setUsedDelta then
        item:setUsedDelta(charge / 100)
    end
end

local function insertBattery(player, object, battery, container)
    if not BPC_ClockState.isClock(object) then return end
    local state = BPC_ClockState.update(object)
    if state.hasBattery then return end
    if not battery or battery:getFullType() ~= "Base.Battery"
        or battery:getContainer() ~= container then return end
    local charge = battery.getUsedDelta and battery:getUsedDelta() * 100 or 100
    if not BPC_ClockState.insertBattery(object, charge, findWatch(player:getInventory())) then return end
    container:Remove(battery)
end

local function setClock(player, object)
    if BPC_ClockState.isClock(object) and findWatch(player:getInventory()) then
        BPC_ClockState.setTime(object)
    end
end

-- Build 42's world-menu element system runs even when the legacy menu finds no interaction.
local function fillClockMenu(data)
    local player = data.player
    local context = data.context
    if not player or not context then return false end

    local seenObjects = {}
    local seenSquares = {}

    local function addClock(object)
        if not object or seenObjects[object] then return false end
        seenObjects[object] = true
        if not BPC_ClockState.isClock(object) then return false end
        if data.test then return true end

        local state = BPC_ClockState.update(object)
        if state.hasBattery then
            context:addOption(getText("ContextMenu_BPC_RemoveBattery", roundCharge(state.charge)),
                player, removeBattery, object)
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
                    local charge = battery.getUsedDelta and battery:getUsedDelta() * 100 or 100
                    subMenu:addOption(string.format("%s (%d%%)", battery:getDisplayName(), roundCharge(charge)),
                        player, insertBattery, object, battery, entry.container)
                end
            end
        end

        if BPC_ClockState.isRunning(state) and BPC_ClockState.isOutOfSync(state)
            and findWatch(player:getInventory()) then
            context:addOption(getText("ContextMenu_BPC_SetClock"),
                player, setClock, object)
        end
        return false
    end

    local function checkSquare(square)
        if not square or seenSquares[square] then return false end
        seenSquares[square] = true
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
