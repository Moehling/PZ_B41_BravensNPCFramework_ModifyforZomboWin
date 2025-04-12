-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleMovement = {}
local tickCounter = 0
local managedNPCs = {}

--- Subscribe to this Module to handle NPC movement.
---@param newData table The variable containing the NPC's persistent data.
MyLittleMovement.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleMovement.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

-- local function addAndWearItem(inventory, character, itemType)
--     local item = InventoryItemFactory.CreateItem("Base." .. itemType)
--     if item then
--         inventory:AddItem(item)
--         character:setWornItem(item:getBodyLocation(), item)
--         return item
--     end

--     return nil
-- end

--- Respawn an NPC at the player's location.
---@param npcData table The data for the NPC to be respawned.
MyLittleMovement.RespawnAtPlayer = function(npcData)
    -- npcData.OnSave(npcData.npc)
    -- local MyLittleNPCs = {}
    -- MyLittleNPCs = ModData.get("MyLittle" .. npcData.firstname)
    -- if MyLittleNPCs then
    --     MyLittleNPCs.FirstStart = false
    -- else
    --     MyLittleNPCs = ModData.create("MyLittle" .. npcData.firstname)
    --     MyLittleNPCs.FirstStart = true
    -- end
    -- MyLittleNPCs.npc = BB_NPCFramework.CreateNPC(MyLittleNPCs, npcData)

    -- local modules = { true, true, true, MyLittleNPCs.needCloseDoors, true, true, true, true, true, true }
    -- local setupStatus = BB_NPCFramework.SubscribeNPCToModules(MyLittleNPCs, modules)

    -- if setupStatus == "CUSTOMIZE" then
    --     local inventory = MyLittleNPCs.npc:getInventory()
    --     if MyLittleNPCs.outfitName then
    --         addAndWearItem(inventory, MyLittleNPCs.npc, MyLittleNPCs.outfitName)
    --     else
    --         local crowbar = InventoryItemFactory.CreateItem("Base.Crowbar")
    --         if crowbar then
    --             inventory:AddItem(crowbar)
    --             MyLittleNPCs.npc:setPrimaryHandItem(crowbar)
    --             MyLittleNPCs.npc:setSecondaryHandItem(crowbar)
    --             MyLittleNPCs.weaponIsRanged = false
    --         end
    --         addAndWearItem(inventory, MyLittleNPCs.npc, "Braven_Mask")
    --         addAndWearItem(inventory, MyLittleNPCs.npc, "Braven_HoodieUP")
    --         addAndWearItem(inventory, MyLittleNPCs.npc, "Braven_Gloves")
    --         addAndWearItem(inventory, MyLittleNPCs.npc, "Braven_Trousers")
    --     end

    --     local itemCount = inventory:getItems():size()
    --     for i = itemCount - 1, 0, -1 do
    --         local item = inventory:getItems():get(i)
    --         item:getModData().equippedByBravenNPC = true
    --     end
    -- end


    local playerSq = MyLittleUtils.playerObj:getSquare()
    local targetSq = AdjacentFreeTileFinder.FindClosest(playerSq, MyLittleUtils.playerObj) or playerSq

    local cachedAesthetics = npcData.npc:getDescriptor()
    local cachedInv = npcData.npc:getInventory()
    npcData.npc = nil
    npcData.npc = IsoPlayer.new(getWorld():getCell(), cachedAesthetics, targetSq:getX(), targetSq:getY(), targetSq:getZ())
    npcData.npc:setInventory(cachedInv)

    npcData.npc:setSceneCulled(false)
    npcData.npc:setNPC(true)
    npcData.npc:setGodMod(npcData.setGod)
    npcData.npc:setInvisible(false)
    npcData.npc:faceThisObject(MyLittleUtils.playerObj)

    npcData.target = MyLittleUtils.playerObj
    npcData.forceStop = false
    npcData.isInVehicle = false
    npcData.isSpeaking = false
    npcData.currSpeech = ""
    npcData.currVehicle = nil

    local npcInv = npcData.npc:getInventory()
    local stashCoords = { X = npcData.stashCoordsX, Y = npcData.stashCoordsY}
    MyLittleUtils.TryLoadInventory(npcData, npcInv, stashCoords )
end

--- Handle NPC movement based on the player's location.
---@param npcData table The data for the NPC whose movement is handled.
MyLittleMovement.HandleMovement = function(npcData)
    if npcData.isEssential and npcData.inknock then return end
    if npcData.forceStop == true then return end
    if npcData.isInSurrender then return end
    local currTargetPos = npcData.target:getSquare()

    if npcData.prevTargetPos ~= currTargetPos and ZombRand(-2,2) then
    -- if npcData.prevTargetPos ~= currTargetPos then

        local targetX = currTargetPos:getX()
        local targetY = currTargetPos:getY()
        local targetZ = currTargetPos:getZ()
        local distance = MyLittleUtils.DistanceBetween(npcData.npc, npcData.target) or 0
        ISTimedActionQueue.clear(npcData.npc)

        local offsetX = 0
        local offsetY = 0

        if npcData.target == MyLittleUtils.playerObj then
			offsetX = ZombRand(-2, 4) * (ZombRand(0, 1) == 0 and -1 or 1)
			offsetY = ZombRand(-2, 4) * (ZombRand(0, 1) == 0 and -1 or 1)

            if distance >= 8 and not (MyLittleUtils.playerObj:HasTrait("KeenHearing") or MyLittleUtils.playerObj:getBuilding()) then
                local npcSq = npcData.npc:getSquare()
                if npcSq and not (npcSq:isCanSee(0) or npcData.isSpeaking == true) then

                    local dir = MyLittleUtils.playerObj:getDir()
                    local newSq = npcSq

                    if (dir == IsoDirections.N) then        newSq = getCell():getGridSquare(targetX + ZombRand(-2, 2), targetY + ZombRand(-2, 4), targetZ)
                    elseif (dir == IsoDirections.NE) then   newSq = getCell():getGridSquare(targetX - ZombRand(-2, 4), targetY + ZombRand(-2, 4), targetZ)
                    elseif (dir == IsoDirections.E) then    newSq = getCell():getGridSquare(targetX - ZombRand(-2, 4), targetY + ZombRand(-2, 2), targetZ)
                    elseif (dir == IsoDirections.SE) then   newSq = getCell():getGridSquare(targetX - ZombRand(-2, 4), targetY - ZombRand(-2, 4), targetZ)
                    elseif (dir == IsoDirections.S) then    newSq = getCell():getGridSquare(targetX + ZombRand(-2, 2), targetY - ZombRand(-2, 4), targetZ)
                    elseif (dir == IsoDirections.SW) then   newSq = getCell():getGridSquare(targetX + ZombRand(-2, 4), targetY - ZombRand(-2, 4), targetZ)
                    elseif (dir == IsoDirections.W) then    newSq = getCell():getGridSquare(targetX + ZombRand(-2, 4), targetY + ZombRand(-2, 2), targetZ)
                    elseif (dir == IsoDirections.NW) then   newSq = getCell():getGridSquare(targetX + ZombRand(-2, 4), targetY + ZombRand(-2, 4), targetZ)
                    end

                    if not newSq:getBuilding() then
                        MyLittleUtils.TeleportTo(npcData.npc, newSq:getX(), newSq:getY(), newSq:getZ())
                    end
                end
            end
        end

        targetX = targetX + offsetX
        targetY = targetY + offsetY

        if distance >= 100 then
            -- ISTimedActionQueue.clear(npcData.npc)
            MyLittleMovement.RespawnAtPlayer(npcData)
        elseif distance >= 50 then
            -- ISTimedActionQueue.clear(npcData.npc)
            MyLittleUtils.TeleportTo(npcData.npc, targetX + ZombRand(-1,1), targetY + ZombRand(-1,1), targetZ)
        elseif distance >= 16 then
            if not npcData.npc:NPCGetRunning() then
                npcData.npc:NPCSetRunning(true)
            end
        elseif distance <= 8 then
            if npcData.npc:NPCGetRunning() then
                npcData.npc:NPCSetRunning(false)
            end
        end

        ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npcData.npc, targetX, targetY, targetZ))
        npcData.prevTargetPos = currTargetPos

        if ZombRand(1, 100) <= 1 then
            local randSpeech = ZombRand(1,7)

            if MyLittleUtils.climateManager:getNightStrength() <= 0.7 then
                MyLittleSpeech.Say(npcData, "Traveling_Day_" .. randSpeech)
            else
                MyLittleSpeech.Say(npcData, "Traveling_Night_" .. randSpeech)
            end
        end

    elseif ZombRand(0, 40) == 1 then
        npcData.npc:faceThisObject(npcData.target)
    end
end


local function toggleInVehicle(npcData, newState)

    local doorPart = nil
    for i=1,npcData.currVehicle:getMaxPassengers() do
        if not npcData.currVehicle:isSeatOccupied(i) then
            local currDoorPart = npcData.currVehicle:getPassengerDoor(i)
            doorPart = currDoorPart
            if newState == true then
                npcData.currVehicle:enter(i, npcData.npc)
                npcData.npc:setInvisible(true)
            else
                npcData.currVehicle:exit(npcData.npc)
                npcData.npc:setInvisible(false)
            end
            break
        end
    end

    if npcData.currVehicle ~= nil and doorPart ~= nil then
        local cachedVehicle = npcData.currVehicle
        MyLittleUtils.DelayFunction(function() cachedVehicle:playPartSound(doorPart, npcData.npc, "Open") end, 50)
        MyLittleUtils.DelayFunction(function() cachedVehicle:playPartSound(doorPart, npcData.npc, "Close") end, 100)
    elseif npcData.currVehicle then
        MyLittleUtils.DelayFunction(function() MyLittleUtils.TryPlaySoundClip(npcData.currVehicle, "VehicleDoorOpenStandard") end, 50)
        MyLittleUtils.DelayFunction(function() MyLittleUtils.TryPlaySoundClip(npcData.currVehicle, "VehicleDoorCloseStandard") end, 100)
    end

    npcData.isInVehicle = newState

    if ZombRand(1, 10) <= 4 then
        local randSpeech = ZombRand(1,5)
        if newState then
            MyLittleSpeech.Say(npcData, "Vehicle_Enter_" .. randSpeech)
        else
            MyLittleSpeech.Say(npcData, "Vehicle_Exit_" .. randSpeech)
        end
    end
end

--- Function called on every tick to manage NPC movement.
local onTick = function()
	if not MyLittleUtils.playerObj then return end
    local playerObj = getPlayer(); if not playerObj then return end

    if tickCounter < 80 then
        tickCounter = tickCounter + 1
    else
        for _, npcData in ipairs(managedNPCs) do

            if npcData.target and npcData.target ~= MyLittleUtils.playerObj and (npcData.target:getHealth() <= 0 or npcData.target:isDead()) then
                npcData.target = MyLittleUtils.playerObj
                MyLittleAttack.StopAttacking(npcData)
            elseif npcData.target ~= MyLittleUtils.playerObj then
                npcData.target = MyLittleUtils.playerObj
            end

            if npcData.forceStop == false and npcData.target == MyLittleUtils.playerObj then

                if not playerObj:getVehicle() then
                    if npcData.isInVehicle == true then
                        toggleInVehicle(npcData, false)
                        npcData.currVehicle = nil
                    end
                    MyLittleMovement.HandleMovement(npcData)
                else
                    if npcData.isInVehicle == false then
                        npcData.currVehicle = playerObj:getVehicle()
                        toggleInVehicle(npcData, true)
                    end
                end
            end

            tickCounter = 0
        end
    end
end

Events.OnTick.Add(onTick)