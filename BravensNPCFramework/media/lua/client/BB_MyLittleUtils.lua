-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleUtils = { }

--- Climate manager for the utilities.
MyLittleUtils.climateManager = nil
--- Cached player
MyLittleUtils.playerObj = nil

--- Function called on game start to initialize climateManager.
local onGameStart = function()
    MyLittleUtils.playerObj = getPlayer()
    MyLittleUtils.climateManager = getClimateManager()
end

Events.OnGameStart.Add(onGameStart)

local function onCharacterDeath(character)
    if character ~= MyLittleUtils.playerObj then return end
    MyLittleUtils.playerObj = getPlayer()
end

Events.OnCharacterDeath.Add(onCharacterDeath)

--- Attempt to play a sound clip on an object.
---@param obj table The object on which the sound clip should be played.
---@param soundName string The name of the sound clip.
---@param override boolean|nil (optional) If TRUE, override any existing playing sound with the same name.
MyLittleUtils.TryPlaySoundClip = function(obj, soundName, override)
    soundName = soundName or ""
	if not override and obj:getEmitter():isPlaying(soundName) then return end
    obj:getEmitter():playSoundImpl(soundName, IsoObject.new())
end

--- Attempt to stop a sound clip on an object.
---@param obj table The object on which the sound clip should be stopped.
---@param soundName string The name of the sound clip to stop.
MyLittleUtils.TryStopSoundClip = function(obj, soundName)
    soundName = soundName or ""
	if not obj:getEmitter():isPlaying(soundName) then return end
	obj:getEmitter():stopSoundByName(soundName)
end

--- Lock or unlock the movement of an NPC.
---@param npcData table The variable containing the NPC's persistent data.
---@param newState boolean The new state for movement lock (TRUE to lock, FALSE to unlock).
MyLittleUtils.LockMovement = function(npcData, newState)
	npcData.forceStop = newState
	ISTimedActionQueue.clear(npcData.npc)
end

--- Set the combat stance of an NPC.
---@param npcData table The variable containing the NPC's persistent data.
---@param newState string The new combat stance (OFFENSIVE, BALANCED or DEFENSIVE).
MyLittleUtils.SetCombatStance = function(npcData, newState)
	npcData.combatStance = newState
	ISTimedActionQueue.clear(npcData.npc)
end

--- Calculate the distance between two objects in the game world.
---@param firstObj table The first object.
---@param secondObj table The second object.
---@return number The distance between the two objects.
MyLittleUtils.DistanceBetween = function(firstObj, secondObj)
    local x1, y1, z1 = firstObj:getX(), firstObj:getY(), firstObj:getZ()
    local x2, y2, z2 = secondObj:getX(), secondObj:getY(), secondObj:getZ()

    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2

    if dz >= 2 then
        return 999
    end

    local distance = math.sqrt(dx * dx + dy * dy)
    return distance
end

--- Return the game's current speed.
---@return number gameSpeed The speed multiplier.
MyLittleUtils.GetGameSpeed = function()
    local speedControl = UIManager.getSpeedControls():getCurrentGameSpeed()
    local gameSpeed = 1

    if speedControl == 2 then
        gameSpeed = 5
    elseif speedControl == 3 then
        gameSpeed = 20
    elseif speedControl == 4 then
        gameSpeed = 40
    end

    return gameSpeed
end

--- Delay the execution of a function by a specified number of ticks.
---@param func function The function to be delayed.
---@param delay number (optional) The delay in ticks (default is 1).
---@param adaptToSpeed boolean|nil (optional) Adapt to game speed if the Player changed it.
---@return function A cancellation function that can be used to cancel the delayed function.
MyLittleUtils.DelayFunction = function(func, delay, adaptToSpeed)
    delay = delay or 1
    local ticks = 0
    local canceled = false
    local tickRate = 60
    local lastTickTime = os.time()

    local function onTick()
        local currentTime = os.time()
        local deltaTime = currentTime - lastTickTime
        lastTickTime = currentTime

        if adaptToSpeed then
            local multiplier = MyLittleUtils.GetGameSpeed()
            deltaTime = deltaTime * multiplier
        end

        ticks = ticks + deltaTime * tickRate

        if not canceled and ticks >= delay then
            ticks = 0
            Events.OnTick.Remove(onTick)
            if not canceled then func() end
        end
    end

    Events.OnTick.Add(onTick)

    return function()
        canceled = true
    end
end

--- Convert a Lua table to a string for serialization purposes.
---@param serialTable table The table to be converted to a string.
---@param key string The key of the current table entry.
---@param value any The value of the current table entry.
---@return string The serialized table as a string.
MyLittleUtils.Stringify = function(serialTable, key, value)
    local newTable = serialTable
    newTable = newTable .. '["' .. key .. '"]=' .. tostring(value) .. ","
    return newTable
end

--- Fetch a random square within a specified distance from a player square.
---@param playerSq table The player's square.
---@return table|nil A random square within the specified distance, or nil if no square is found.
MyLittleUtils.FetchRandomSquare = function(playerSq)
    if not playerSq then return end
    local maxDistance = 10
    local minDistance = 1
    for currentDistance = maxDistance, minDistance, -1 do
        local randomX = playerSq:getX() + ZombRand(-currentDistance, currentDistance)
        local randomY = playerSq:getY() + ZombRand(-currentDistance, currentDistance)
        local square = getCell():getGridSquare(randomX, randomY, 0)
        if square then
            return square
        end
    end
    return nil
end

--- Load items from a stash and equip them to an NPC.
---@param npcData table The variable containing the NPC's persistent data.
---@param npcInv table The NPC's inventory.
---@param stashCoords table The coordinates of the stash square.
MyLittleUtils.TryLoadInventory = function(npcData, npcInv, stashCoords)
    local stashSq = getCell():getGridSquare(stashCoords.X, stashCoords.Y, 0)
    local outfit = InventoryItemFactory.CreateItem("Base." .. npcData.outfitName)
    -- 检查 NPC 是否有相同部位的服装
    -- local hasSimilarOutfit = false
    -- local hasoutfit = false
    local hasAddedAlternative = false
    -- TTF->只有初始服装，加初始服装
    -- TTT->有初始服装，有替代品，不加初始服装
    -- TFT->只有替代品，不加初始服装
    -- FFF->没服装，加初始服装
    -- 故而可以一个参数完美控制
    if stashSq then
        local objs = stashSq:getObjects()
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            if instanceof(obj, "IsoObject") then
                local modData = obj:getModData()
                if modData and modData.isBravenNPCStash then
                    local objContainer = obj:getContainer()
                    local itemCount = objContainer:getItems():size()
                    for x = itemCount - 1, 0, -1 do
                        local item = objContainer:getItems():get(x)
                        if item then
                            -- npcInv:AddItem(item)
                            -- 过滤初始服装
                            if outfit then
                                if item:IsClothing() and not instanceof(item, "InventoryContainer") then
                                    if item:getBodyLocation() == outfit:getBodyLocation() then
                                        -- hasSimilarOutfit = true
                                        if item:getFullType() == outfit:getFullType() then
                                            -- hasoutfit = true
                                        else
                                            hasAddedAlternative = true
                                            npcInv:AddItem(item)
                                            -- npcData.npc:setWornItem(item:getBodyLocation(), item)
                                        end
                                    else npcInv:AddItem(item) end
                                else npcInv:AddItem(item) end
                            else npcInv:AddItem(item) end
                        end
                    end

                    -- 销毁箱子
                    sledgeDestroy(obj)
                    stashSq:transmitRemoveItemFromSquare(obj)
                    break
                end
            end
        end
    end
    local itemCount = npcInv:getItems():size()
    for i = itemCount - 1, 0, -1 do
        local item = npcInv:getItems():get(i)
        if item:getDisplayCategory() ~= "Wound" then
            local modData = item:getModData()

            if modData and modData.equippedByBravenNPC then
                if item:IsWeapon() then
                    npcData.npc:setSecondaryHandItem(item)
                    npcData.npc:setPrimaryHandItem(item)
                    npcData.weaponIsRanged = item:isRanged()
                elseif item:IsClothing() or instanceof(item, "InventoryContainer") then

                    local location = nil
                    if not instanceof(item, "InventoryContainer") then
                        location = item:getBodyLocation()
                        -- 百距复活生空箱
                        if outfit then
                            if location == outfit:getBodyLocation() then
                                hasAddedAlternative = true
                            end
                        end
                    else
                        location = item:canBeEquipped()
                    end
                    npcData.npc:setWornItem(location, item)
                end
            elseif modData and not modData.equippedByBravenNPC then
                if item:IsClothing() or instanceof(item, "InventoryContainer") then

                    local location = nil
                    if not instanceof(item, "InventoryContainer") then
                        location = item:getBodyLocation()
                        -- 百距复活生空箱
                        if outfit then
                            if location == outfit:getBodyLocation() then
                                hasAddedAlternative = true
                            end
                        end
                    else
                        location = item:canBeEquipped()
                    end
                    npcData.npc:setWornItem(location, item)
                end
            end
        end
    end
    if not hasAddedAlternative and outfit then
        npcInv:AddItem(outfit)
        npcData.npc:setWornItem(outfit:getBodyLocation(), outfit)
    end
    -- MyLittleUtils.DelayFunction(function ()
        -- npcData.npc:reportEvent("EventSitOnGround")
    -- end,10)
end

--- Teleport an NPC to a specified location.
---@param npc table The NPC to be teleported.
---@param x number The X-coordinate of the destination.
---@param y number The Y-coordinate of the destination.
---@param z number The Z-coordinate of the destination.
MyLittleUtils.TeleportTo = function(npc, x, y, z)
    npc:setX(x)
    npc:setY(y)
    npc:setZ(z)

    npc:setLx(x)
    npc:setLy(y)
    npc:setLz(z)
end

--- Round a number to a specified number of decimal places.
---@param number number The number to be rounded.
---@param decimalPlaces number (optional) The number of decimal places (default is 0).
---@return number The rounded number.
MyLittleUtils.RoundToDecimalPlaces = function(number, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
end

--- Fetch the door object in a specified square.
---@param square table The square to check for a door.
---@return table|nil The door object if found, or nil if no door is present.
MyLittleUtils.FetchDoorInSquare = function(square)
    local door = nil

    if square then
        local objects = square:getObjects()
        local numObjects = objects:size()

        for i = 0, numObjects - 1 do
            local obj = objects:get(i)

            if instanceof(obj, "IsoDoor") then
                door = obj
                break
            end
        end
    end

    return door
end

--- Check if an NPC is busy (Has queued Timed Actions). Returns TRUE or FALSE.
---@param npc IsoPlayer The variable containing the NPC itself.
MyLittleUtils.IsBusy = function(npc)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(npc)
    if actionQueue and #actionQueue > 0 then return true end
    return false
end

--- Decide if the NPC will acknowledge an action by Speech. Example: "Understood!"
---@param npcData table The variable containing the NPC's persistent data.
MyLittleUtils.AcknowledgeAction = function(npcData)
    -- if ZombRand(1, 10) <= 4 then
    if ZombRand(1, 10) <= 4 then
        local randSpeech = ZombRand(1,6)
        MyLittleSpeech.Say(npcData, "Acknowledge_" .. randSpeech)
    end
end

--- Check if a table contains an element
MyLittleUtils.TableContains = function(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end