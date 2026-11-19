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

local function onFillWorldObjectContextMenu(playerIndex, context, worldObjects, test)
    if test then return end
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local seen = {}
    for i = 1, #worldObjects do
        local square = worldObjects[i] and worldObjects[i]:getSquare()
        if square then
            local objects = square:getObjects()
            for j = 0, objects:size() - 1 do
                local object = objects:get(j)
                if not seen[object] and BPC_ClockState.isClock(object) then
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
        end
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
