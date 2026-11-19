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

local function findBattery(container)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == "Base.Battery" then
            return item, container
        end
        if item:IsInventoryContainer() then
            local found, owner = findBattery(item:getInventory())
            if found then return found, owner end
        end
    end
    return nil, nil
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

local function insertBattery(player, object)
    if not BPC_ClockState.isClock(object) then return end
    local state = BPC_ClockState.update(object)
    if state.hasBattery then return end
    local battery, container = findBattery(player:getInventory())
    if not battery then return end
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

    local seen = {}
    for _, object in ipairs(data.objects or {}) do
        if not seen[object] and BPC_ClockState.isClock(object) then
            if data.test then return true end
            seen[object] = true
            local state = BPC_ClockState.update(object)
            local label
            if BPC_ClockState.isRunning(state) then
                label = getText("ContextMenu_BPC_ClockStatus",
                    BPC_ClockState.formatTime(state), math.floor(state.charge))
            else
                label = getText("ContextMenu_BPC_ClockStopped", BPC_ClockState.formatTime(state))
            end
            local status = context:addOption(label, nil, nil)
            status.notAvailable = true

            if state.hasBattery then
                context:addOption(getText("ContextMenu_BPC_RemoveBattery"),
                    player, removeBattery, object)
            elseif findBattery(player:getInventory()) then
                context:addOption(getText("ContextMenu_BPC_InsertBattery"),
                    player, insertBattery, object)
            end

            if BPC_ClockState.isRunning(state) and BPC_ClockState.isOutOfSync(state)
                and findWatch(player:getInventory()) then
                context:addOption(getText("ContextMenu_BPC_SetClock"),
                    player, setClock, object)
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
