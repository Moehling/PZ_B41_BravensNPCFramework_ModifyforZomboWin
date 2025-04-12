-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleCombat = {}
local managedNPCs = {}

--- Subscribe to this Module to handle NPC combat.
---@param newData table The variable containing the NPC's persistent data.
MyLittleCombat.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleCombat.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- Handles making the NPC flee from hostiles.
---@param npcData table The data of the NPC.
---@param fleeX number The X coordinate to flee towards.
---@param fleeY number The Y coordinate to flee towards.
---@param fleeZ number The Z coordinate to flee towards.
MyLittleCombat.FleeToCoords = function(npcData, fleeX, fleeY, fleeZ)
    if not npcData.npc then return end
    if not fleeX or not fleeY then return end
    npcData.npc:NPCSetRunning(true)
    npcData.isFleeing = true
    ISTimedActionQueue.clear(npcData.npc)
    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npcData.npc, fleeX, fleeY, fleeZ))
    MyLittleUtils.DelayFunction(function() npcData.isFleeing = false end, (10 * npcData.fleeDistance))
end

MyLittleCombat.GetRandomCoordsAwayFromTarget = function(npcData, npcSq, targetPos, distance, counter)
    counter = counter or 0

    if counter >= 50 then
        return -1, -1, -1
    end

    -- Calculate the angle between the NPC and the target
    local angleToTarget = math.atan2(targetPos.Y - npcSq:getY(), targetPos.X - npcSq:getX())

    -- Add or subtract 180 degrees (pi radians) to move in the opposite direction
    local oppositeAngle = angleToTarget + math.pi

    -- Calculate the new coordinates based on the opposite angle
    if npcSq:getBuilding() then distance = math.floor(distance / 2) end
    local offsetX = distance * math.cos(oppositeAngle)
    local offsetY = distance * math.sin(oppositeAngle)

    local newX, newY, newZ = npcSq:getX() + offsetX, npcSq:getY() + offsetY, npcSq:getZ()
    local newSq = getCell():getGridSquare(newX, newY, newZ)
    local isValidSq = true

    if not newSq or (newSq and newSq:isBlockedTo(npcSq)) or (newSq and newSq:getZombie()) then
        isValidSq = false
    end

    if isValidSq then
        if counter == 0 then
            return newX, newY, newZ
        else
            MyLittleCombat.FleeToCoords(npcData, newX, newY, newZ)
        end
    else
        return MyLittleCombat.GetRandomCoordsAwayFromTarget(npcData, npcSq, targetPos, distance, counter + 1)
    end
end


--- Find the closest zombie from a list based on NPC's position.
---@param npcData table The data of the NPC.
---@param zombies table A table containing zombies.
---@return IsoZombie|nil --The closest zombie from the list.
local function findClosestZombie(npcData, zombies)
    local npcSq = npcData.npc:getSquare()
    if not npcSq then return nil end

    local closestZombie
    local minDistance = 999999

    for _, zombie in ipairs(zombies) do
        local distance = MyLittleUtils.DistanceBetween(npcData.npc, zombie) or 0
        if distance < minDistance then
            minDistance = distance
            closestZombie = zombie
        end
    end
    return closestZombie
end


--- Find the closest zombie from a list based on NPC's position.
---@param npcData table The data of the NPC.
---@param zombies table A table containing zombies.
---@return IsoZombie|nil --The closest zombie from the list.
local function findCloseF__kZombie(npcData, zombies, range)
    local npcSq = npcData.npc:getSquare()
    if not npcSq then return nil end

    local closestZombie
    -- 
    for _, zombie in ipairs(zombies) do
        local distance = MyLittleUtils.DistanceBetween(npcData.npc, zombie) or 0
        if distance <= range then
            closestZombie = zombie
            if ZombRand(1, 10) <= 3 then
                break
            end
        end
    end
    return closestZombie
end


--- Fetch nearby zombies based on the NPC's position and range.
---@param npcData table The data of the NPC.
---@param npcSq IsoGridSquare The square the NPC is on.
---@param npcX number The X coordinate of the NPC.
---@param npcY number The Y coordinate of the NPC.
---@param npcZ number The Z coordinate of the NPC.
---@param range number The range to search for zombies.
---@return table --The list of zombies found within the specified range.
local function fetchNearbyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
    local zombieList = {}

    -- Iterate over the square-shaped area around the NPC
    for dx = -range, range do
        for dy = -range, range do
            local x = npcX + dx
            local y = npcY + dy

            -- Get the grid square at the current position
            local sq = getCell():getGridSquare(x, y, npcZ)

            -- Check if the square is not blocked to the NPC
            if sq and not sq:isBlockedTo(npcSq) then

                -- Iterate over moving objects in the square
                for i = 1, sq:getMovingObjects():size() do
                    local obj = sq:getMovingObjects():get(i - 1)

                    -- Check if the object is an IsoZombie
                    if instanceof(obj, "IsoZombie") then

                        -- Calculate the distance between the NPC and the zombie
                        local distance = MyLittleUtils.DistanceBetween(npcData.npc, obj) or 0

                        -- Check combat stances and zombie targeting
                        if npcData.combatStance == "Offensive" or
                           (obj:getTarget() == npcData.npc and distance <= 1) then
                            table.insert(zombieList, obj)
                        elseif npcData.combatStance == "Balanced" and (obj:getTarget() == npcData.npc or obj:getTarget() == MyLittleUtils.playerObj) then
                            table.insert(zombieList, obj)
                        elseif obj:isAttacking() and (obj:getTarget() == npcData.npc or obj:getTarget() == MyLittleUtils.playerObj) then
                            table.insert(zombieList, obj)
                        end
                    end
                end
            end
        end
    end

    return zombieList
end
--- Fetch nearby zombies without based on the NPC's position and range.
---@param npcData table The data of the NPC.
---@param npcSq IsoGridSquare The square the NPC is on.
---@param npcX number The X coordinate of the NPC.
---@param npcY number The Y coordinate of the NPC.
---@param npcZ number The Z coordinate of the NPC.
---@param range number The range to search for zombies.
---@return table --The list of zombies found within the specified range.
local function fetchNearbyanyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
    local zombieList = {}

    -- Iterate over the square-shaped area around the NPC
    for dx = -range, range do
        for dy = -range, range do
            local x = npcX + dx
            local y = npcY + dy

            -- Get the grid square at the current position
            local sq = getCell():getGridSquare(x, y, npcZ)

            -- Check if the square is not blocked to the NPC
            if sq and not sq:isBlockedTo(npcSq) then

                -- Iterate over moving objects in the square
                for i = 1, sq:getMovingObjects():size() do
                    local obj = sq:getMovingObjects():get(i - 1)

                    -- Check if the object is an IsoZombie
                    if instanceof(obj, "IsoZombie") then
                        if obj:isFemale() ~= npcData.npc:isFemale() then
                            table.insert(zombieList, obj)
                        end
                    end
                end
            end
        end
    end

    return zombieList
end


local function onlyFleeSomeTime(npcData, time)
    ISTimedActionQueue.clear(npcData.npc)
    npcData.npc:setInvisible(true)
    npcData.canFlee = true
    MyLittleUtils.DelayFunction(function()
        npcData.npc:setInvisible(false)
        npcData.canFlee = false
    end, time)
end


---@param playerSurrender boolean|nil player want to surrender
MyLittleCombat.HandleSurrender = function(npcData, range, playerSurrender)
    -- npcStats.npc:reportEvent("EventSitOnGround")
    -- if npcData.playerinSurrender then return end
    if npcData.isInSurrender then return end
    local npcSq = npcData.npc:getSquare()
    if npcSq then
        local npcX, npcY, npcZ = npcSq:getX(), npcSq:getY(), npcSq:getZ()
        -- 搜索附近的任意或有正确目标僵尸并让NPC过去并强制停止
        local nearbyZombies = {}
        local Acceptable_numbers = npcData.Acceptable_numbers
        if playerSurrender then
            Acceptable_numbers = 999
        else
            -- 视野越小概率越大，减少性能消耗，增加帧率
            if ZombRand(0, range) > 5 then return false end
        end
        if npcData.test then
            nearbyZombies = fetchNearbyanyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
        else
            nearbyZombies = fetchNearbyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
        end
        if #nearbyZombies > 0 and #nearbyZombies <= Acceptable_numbers then
            local closestZombie = nil
            if npcData.test or playerSurrender then
                closestZombie = findCloseF__kZombie(npcData, nearbyZombies, ZombRand(5, range))
            else
                closestZombie = findClosestZombie(npcData, nearbyZombies)
            end

            if not closestZombie then
                return
            end

            if closestZombie:isFemale() ~= npcData.npc:isFemale() then
                -- if playerSurrender then npcData.playerinSurrender = true end
                npcData.forceStop = true
                npcData.target = closestZombie
                -- local zombieX = closestZombie:getX() + ZombRand(-1, 2)
                -- local zombieY = closestZombie:getY() + ZombRand(-1, 2)
                local zombieX = closestZombie:getX()
                local zombieY = closestZombie:getY()
                local zombieZ = closestZombie:getZ()
                ISTimedActionQueue.clear(npcData.npc)

                npcData.npc:playEmote("surrender")

                MyLittleSpeech.F__kSay(npcData)

                if npcData.superzombie then
                    -- 让NPC传送到僵尸的位置
                    MyLittleUtils.TeleportTo(npcData.npc, zombieX, zombieY, zombieZ)

                else
                    ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npcData.npc, zombieX, zombieY, zombieZ))
                end
                npcData.isInSurrender = true

                -- MyLittleUtils.DelayFunction(function()
                --     -- npcData.npc:reportEvent("EventSitOnGround")
                --     -- 待后期接入
                --     npcData.isInSurrender = false
                -- end, ZombRand(700, 1400))

                -- 很安全就别回去了
                if #nearbyZombies < 2 then return true end

                -- 人多防闪退，就不回去了
                if #nearbyZombies > 5 then return true end
                MyLittleUtils.DelayFunction(function()
                    npcData.forceStop = false
                    npcData.isInSurrender = false
                    npcData.target = MyLittleUtils.playerObj
                    local distance = MyLittleUtils.DistanceBetween(npcData.npc, MyLittleUtils.playerObj) or 0
                    if distance > 10 and #nearbyZombies >= 10 then
                        local currTargetPos = npcData.target:getSquare()
                        local X = currTargetPos:getX() + ZombRand(-1,2)
                        local Y = currTargetPos:getY() + ZombRand(-1,2)
                        local Z = currTargetPos:getZ()
                        MyLittleUtils.TeleportTo(npcData.npc, X, Y, Z)
                        onlyFleeSomeTime(npcData, 200)
                    else
                        onlyFleeSomeTime(npcData, 200)
                    end
                end, ZombRand(1400, 4000))
                return true
            else
                onlyFleeSomeTime(npcData, 200)
                return false
            end
        elseif #nearbyZombies > Acceptable_numbers then
            npcData.target = MyLittleUtils.playerObj
            local distance = MyLittleUtils.DistanceBetween(npcData.npc, npcData.target) or 0
            if distance > 10 then
                local currTargetPos = npcData.target:getSquare()
                local X = currTargetPos:getX() + ZombRand(-1,2)
                local Y = currTargetPos:getY() + ZombRand(-1,2)
                local Z = currTargetPos:getZ()
                onlyFleeSomeTime(npcData, 200)
                MyLittleUtils.TeleportTo(npcData.npc, X, Y, Z)
                return false
            else
                onlyFleeSomeTime(npcData, 200)
            end
        end
    end
end

--- Look for hostiles in the NPC's proximity and engage them.
---@param npcData table The variable containing the NPC's persistent data.
---@return table --The list of zombies found within the specified range.
local function engageHostiles(npcData)
    local npcSq = npcData.npc:getSquare()
    if npcSq then
        local npcX, npcY, npcZ = npcSq:getX(), npcSq:getY(), npcSq:getZ()
        local range = 5; if npcData.weaponIsRanged then range = 15 end
        return fetchNearbyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
    end

    return {}
end

--- React to hostiles in the NPC's proximity.
---@param npcData table The variable containing the NPC's persistent data.
---@return table --The list of zombies found within the specified range.
local function lookForHostiles(npcData)
    local npcSq = npcData.npc:getSquare()
    if npcSq then
        local npcX, npcY, npcZ = npcSq:getX(), npcSq:getY(), npcSq:getZ()
        local range = 5; if npcData.weaponIsRanged then range = 8 end
        return fetchNearbyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
    end

    return {}
end

--- React to hostiles in the immediate area that are attacking.
---@param npcData table The variable containing the NPC's persistent data.
---@return table --The list of zombies found within the specified range.
local function reactToHostiles(npcData)
    local npcSq = npcData.npc:getSquare()
    if npcSq then
        local npcX, npcY, npcZ = npcSq:getX(), npcSq:getY(), npcSq:getZ()
        local range = 3; if npcData.weaponIsRanged then range = 6 end
        return fetchNearbyZombies(npcData, npcSq, npcX, npcY, npcZ, range)
    end

    return {}
end

local tickCounter = 0

--- OnTick event handler to periodically check and react to hostiles.
local function onTick()

    if not MyLittleUtils.playerObj then return end
    local vehicle = MyLittleUtils.playerObj:getVehicle(); if vehicle then return end

    tickCounter = tickCounter + 1
    if tickCounter > 120 then
        tickCounter = 0
    end

    if tickCounter == 60 or tickCounter == 120 then
        for _, npcData in ipairs(managedNPCs) do
            if npcData.isEssential and npcData.inknock == true then
            else

                if npcData.combatStance == "Offensive" then
                    local result = engageHostiles(npcData)
                    if result then
                        local nearestTarget = findClosestZombie(npcData, result)
                        if nearestTarget then npcData.target = nearestTarget end
                    end
                elseif npcData.combatStance == "Balanced" then
                    local result = lookForHostiles(npcData)
                    if result then
                        local nearestTarget = findClosestZombie(npcData, result)
                        if nearestTarget then npcData.target = nearestTarget end
                    end
                else
                    local result = reactToHostiles(npcData)
                    if result then
                        local nearestTarget = findClosestZombie(npcData, result)
                        if nearestTarget then npcData.target = nearestTarget end
                    end
                end

                if npcData.target and npcData.target ~= MyLittleUtils.playerObj then
                    -- 有武器，打不到就前往目标，打得到继续判定
                    local weapon = npcData.npc:getPrimaryHandItem()
                    local pursuing = false
                    if weapon and not MyLittleAttack.IsInAttackRange(npcData) then
                        MyLittleMovement.HandleMovement(npcData)
                        pursuing = true
                    end
                    -- 没武器或可攻击
                    if not pursuing then
                        -- 还没跑且可跑，看3格内威胁
                        if not npcData.isFleeing and npcData.canFlee then
                            -- 取远距原版僵尸，算威胁
                            local result = engageHostiles(npcData)
                            local threats = 0
                            if result then
                                for _, zombie in ipairs(result) do
                                    local distance = MyLittleUtils.DistanceBetween(npcData.npc, zombie) or 0
                                    if distance <= 3 then
                                        threats = threats + 1
                                    end
                                end
                            end
                            -- 没武器或刚攻击完但威胁>2
                            if not weapon or (threats > 2 and not npcData.isAttacking) then
                                -- 没武器，视野小
                                if not weapon then
                                    result = reactToHostiles(npcData)
                                end
                                -- 逃离最近的威胁
                                local npcSq = npcData.npc:getSquare()
                                local targetSq = findClosestZombie(npcData, result)
                                if targetSq then
                                    local coords = { X = targetSq:getX(), Y = targetSq:getY(), Z = targetSq:getZ() }
                                    local fleeX, fleeY, fleeZ = MyLittleCombat.GetRandomCoordsAwayFromTarget(npcData, npcSq, coords, npcData.fleeDistance)
                                    -- 反方向跑
                                    if fleeX ~= -1 and fleeY ~= -1 and fleeZ ~= -1 then
                                        if npcData.inknock then return end
                                        MyLittleCombat.FleeToCoords(npcData, fleeX, fleeY, fleeZ)
                                        return
                                    end
                                end
                            end
                        end
                        -- 有敌人还不让逃跑，触发异性投降
                        if not npcData.canFlee and tickCounter == 120 then
                            if npcData.weaponIsRanged then
                                if MyLittleCombat.HandleSurrender(npcData, 5) then
                                    return
                                end
                            elseif not weapon then
                                if MyLittleCombat.HandleSurrender(npcData, 10) then
                                    return
                                end
                            else
                                if MyLittleCombat.HandleSurrender(npcData, 2) then
                                    return
                                end
                            end

                        end

                        if weapon and not npcData.isAttacking and not npcData.isFleeing then
                            if npcData.inknock then return end
                            MyLittleAttack.TryAttack(npcData)
                            MyLittleAttack.TryIdleReload(npcData)
                        end
                    end
                -- 丢失目标
                elseif not npcData.target  and tickCounter == 120 then
                    npcData.target = MyLittleUtils.playerObj
                end
                -- 不能逃跑还跟着玩家
                if not npcData.canFlee and npcData.target == MyLittleUtils.playerObj and tickCounter == 120 then

                    if npcData.weaponIsRanged then
                        MyLittleCombat.HandleSurrender(npcData, 5)
                    elseif not npcData.npc:getPrimaryHandItem() then
                        MyLittleCombat.HandleSurrender(npcData, 10)
                    else
                        MyLittleCombat.HandleSurrender(npcData, 2)
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(onTick)

--- EveryOneMinute event handler to perform actions every minute.
local function everyMinute()
    for _, npcData in ipairs(managedNPCs) do
        if MyLittleUtils.IsBusy(npcData.npc) then return end
        MyLittleAttack.TryIdleReload(npcData)
    end
end

Events.EveryOneMinute.Add(everyMinute)

--- OnHitZombie event handler to react to hitting zombies.
---@param zombie IsoZombie The hit zombie.
---@param character IsoPlayer The character hitting the zombie.
---@param bodyPartType string The body part hit.
---@param handWeapon HandWeapon The weapon used for the hit.
local function OnHitZombie(zombie, character, bodyPartType, handWeapon)

    for _, npcData in ipairs(managedNPCs) do

        if npcData.target == character then
            npcData.npc:faceThisObject(zombie)
            npcData.target = zombie
        end

        if character == npcData.npc and handWeapon then
            if ZombRand(1, 10) <= 1 then
                local randSpeech = ZombRand(1,6)
                MyLittleSpeech.Say(npcData, "Attack_" .. randSpeech)
            end

            npcData.npc:playSound(handWeapon:getZombieHitSound())
        end
    end
end

Events.OnHitZombie.Add(OnHitZombie)
