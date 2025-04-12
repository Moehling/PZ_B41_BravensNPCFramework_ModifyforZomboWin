-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleAttack = { }

--- Attempt a melee attack with the given NPC data, weapon, and player object.
---@param npcData table The variable containing the NPC's persistent data.
---@param weapon HandWeapon The melee weapon used for the attack.
MyLittleAttack.TryAttackMelee = function(npcData, weapon)
    local damage = weapon:getMinDamage()
    local wpnWeight = weapon:getWeight()
    local swingDelay = (wpnWeight * 60) - 20
    if swingDelay < 60 then swingDelay = 60 end

    npcData.npc:NPCSetAttack(true)
    npcData.npc:NPCSetMelee(true)
    npcData.npc:AttemptAttack(swingDelay + 120)

    MyLittleUtils.DelayFunction(function()
        if npcData.target and npcData.target ~= MyLittleUtils.playerObj then
            npcData.npc:playSound(weapon:getSwingSound())
        end
    end, swingDelay - 30)

    MyLittleUtils.DelayFunction(function()
        if npcData.target and npcData.target ~= MyLittleUtils.playerObj then
            npcData.target:Hit(weapon, npcData.npc, damage, true, 1.0, false)
            npcData.target:setHealth(npcData.target:getHealth() - damage)
            npcData.target:setAttackedBy(npcData.npc)
        end

        MyLittleAttack.StopAttacking(npcData)
    end, swingDelay)
end

local function predicateFake(item, magazineType)
	return true
end

local function predicateFullestMagazine(item1, item2)
	return item1:getCurrentAmmoCount() - item2:getCurrentAmmoCount()
end

local function getMagazine(inventory, weapon)
	return inventory:getBestEvalArgRecurse(predicateFake, predicateFullestMagazine, weapon:getMagazineType())
end

local function getBulletCount(inventory, weapon)
	return inventory:getCountTypeRecurse(weapon:getAmmoType())
end

--- Switch the NPC to a melee weapon.
---@param npcData table The variable containing the NPC's persistent data.
MyLittleAttack.SwitchToMelee = function(npcData)
    local npcInv = npcData.npc:getInventory()
    local npcItems = npcInv:getItems()

    for i=0, npcItems:size() - 1 do

        local item = npcInv:getItems():get(i)
        if not item:isEquipped() and item:getAttachedSlot() == -1 then

            if item:IsWeapon() and not item:isRanged() then

                local primaryHandItem = npcData.npc:getPrimaryHandItem()
                if primaryHandItem then
                    primaryHandItem:getModData().equippedByBravenNPC = nil
                    npcData.npc:setPrimaryHandItem(nil)
                end

                local secondaryHandItem = npcData.npc:getSecondaryHandItem()
                if secondaryHandItem then
                    secondaryHandItem:getModData().equippedByBravenNPC = nil
                    npcData.npc:setSecondaryHandItem(nil)
                end

                npcData.npc:setPrimaryHandItem(item)
                npcData.npc:setSecondaryHandItem(item)
                npcData.weaponIsRanged = item:isRanged()

                item:getModData().equippedByBravenNPC = true
                break
            end
        end
    end

    MyLittleAttack.StopAttacking(npcData)
    npcData.npc:NPCSetAiming(false)
    npcData.forceStop = false
end

local function resupplyAmmo(npcData, weapon)
    local npcInv = npcData.npc:getInventory()
    local ammoType = weapon:getAmmoType()
    local maxAmmo = weapon:getMaxAmmo()
    if getBulletCount(npcInv, weapon) == 0 then
        for _ = 1, maxAmmo do
            local newRound = InventoryItemFactory.CreateItem(ammoType)
            if newRound then
                npcInv:addItem(newRound)
            end
        end
    end
end

--- Rack a weapon if it is jammed, and proceed to reload it.
---@param npcData table The variable containing the NPC's persistent data.
---@param weapon HandWeapon The ranged weapon used for the attack.
local function rackAndReload(npcData, weapon)
    if MyLittleUtils.IsBusy() then return end

    if npcData.resupplyAmmo then
        resupplyAmmo(npcData, weapon)
    end

    if weapon:isJammed() then
        ISTimedActionQueue.add(ISRackFirearm:new(npcData.npc, weapon))
    end

    ISReloadWeaponAction.BeginAutomaticReload(npcData.npc, weapon)
end

--- Damage the target hit by the NPC.
---@param npc IsoPlayer The NPC to damage the target.
---@param target any The target itself.
---@param weapon HandWeapon The NPC's weapon.
---@param damage number The damage to be applied.
local function damageTarget(npc, target, weapon, damage)
    target:Hit(weapon, npc, damage, true, 1.0, false)
    target:setHealth(target:getHealth() - damage)
    target:setAttackedBy(npc)
end

--- Damage zombies in adjacent squares
---@param npc IsoPlayer The NPC to damage the target.
---@param weapon HandWeapon The NPC's weapon.
---@param damage number The damage to be applied.
---@param target any The target itself.
local function damageAdditionalTargets(npc, target, weapon, damage)
    local targetSquare = target:getSquare()
    local x, y, z = targetSquare:getX(), targetSquare:getY(), targetSquare:getZ()

    for dx = -2, 2 do
        for dy = -2, 2 do
            local sq = getCell():getGridSquare(x + dx, y + dy, z)
            if sq then
                for i = 1, sq:getMovingObjects():size() do
                    local obj = sq:getMovingObjects():get(i - 1)
                    if instanceof(obj, "IsoZombie") and obj ~= target then
                        damageTarget(npc, obj, weapon, damage)
                        break
                    end
                end
            end
        end
    end
end

--- Attempt a ranged attack with the given NPC data, weapon, and player object.
---@param npcData table The variable containing the NPC's persistent data.
---@param weapon HandWeapon The ranged weapon used for the attack.
MyLittleAttack.TryAttackRanged = function(npcData, weapon)
    if MyLittleUtils.DistanceBetween(npcData.npc, npcData.target) <= 1.3 then
        MyLittleAttack.SwitchToMelee(npcData)
        return
    end

    local inventory = npcData.npc:getInventory()
    local requiresMagazine = weapon:getMagazineType() ~= nil
    local magazine = requiresMagazine and getMagazine(inventory, weapon)

    local function isAmmoAvailable()
        if requiresMagazine then
            return magazine and magazine:getCurrentAmmoCount() > 0
        else
            return weapon:getCurrentAmmoCount() > 0
        end
    end

    local function reloadIfNoAmmo()
        if not isAmmoAvailable() then
            if ZombRand(1, 10) <= 5 then MyLittleSpeech.Say(npcData, "NoAmmo") end
            MyLittleAttack.StopAttacking(npcData)

            if isAmmoAvailable() then
                rackAndReload(npcData, weapon)
            else
                MyLittleAttack.SwitchToMelee(npcData)
            end
            return true
        end
        return false
    end

    if not npcData.infiniteAmmo and reloadIfNoAmmo() then
        return
    end

    local damage = weapon:getMinDamage()
    local aimDelay = (weapon:getSwingTime() * 60) - 60
    local aimTime = 150
    local fireDelay = (aimTime + aimDelay) * npcData.aimSpeedMultiplier

    npcData.forceStop = true
    if not npcData.npc:NPCGetAiming() then npcData.npc:NPCSetAiming(true) end

    MyLittleUtils.DelayFunction(function()
        if npcData.target and npcData.target ~= MyLittleUtils.playerObj and isAmmoAvailable() then
            MyLittleUtils.TryPlaySoundClip(npcData.npc, weapon:getSwingSound(), true)
            local radius = weapon:getSoundRadius()
            npcData.npc:addWorldSoundUnlessInvisible(radius, weapon:getSoundVolume(), false)
            MyLittleUtils.DelayFunction(function() MyLittleUtils.TryPlaySoundClip(npcData.npc, weapon:getShellFallSound(), true) end, 20)
            npcData.npc:startMuzzleFlash()

            if not npcData.infiniteAmmo then
                if requiresMagazine then
                    magazine:setCurrentAmmoCount(magazine:getCurrentAmmoCount() - 1)
                else
                    weapon:setCurrentAmmoCount(weapon:getCurrentAmmoCount() - 1)
                end
            end
        end
    end, fireDelay - 30)

    MyLittleUtils.DelayFunction(function()
        if npcData.target and npcData.target ~= MyLittleUtils.playerObj and isAmmoAvailable() then
            damageTarget(npcData.npc, npcData.target, weapon, damage)
            local projectileCount = weapon:getMaxHitCount()
            if projectileCount > 1 then
                for _ = 1, projectileCount do
                    damageAdditionalTargets(npcData.npc, npcData.target, weapon, damage / 5)
                end
            end
        end

        npcData.forceStop = false
        MyLittleAttack.StopAttacking(npcData, true)
    end, fireDelay)
end

--- Attempt an idle reload with the given NPC data.
---@param npcData table The variable containing the NPC's persistent data.
MyLittleAttack.TryIdleReload = function(npcData)
    if npcData.isAttacking == true then return end
    local weapon = npcData.npc:getPrimaryHandItem()
    if not weapon or weapon and not weapon:isRanged() then return end

    if npcData.resupplyAmmo then
        resupplyAmmo(npcData, weapon)
    end

    local inventory = npcData.npc:getInventory()
    local usesMagazine = false
    local magazine

    if weapon:getMagazineType() then
        magazine = getMagazine(inventory, weapon)
        usesMagazine = true
    end

    if not usesMagazine then
        if weapon:getCurrentAmmoCount() < weapon:getMaxAmmo() and getBulletCount(inventory, weapon) > 0 then
            rackAndReload(npcData, weapon)
            return
        end
    elseif magazine then
        if magazine:getCurrentAmmoCount() < weapon:getMaxAmmo() and getBulletCount(inventory, weapon) > 0 then
            rackAndReload(npcData, weapon)
            return
        end
    end

end

--- Attempt an attack with the given NPC data.
---@param npcData table The variable containing the NPC's persistent data.
MyLittleAttack.TryAttack = function(npcData)
    ISTimedActionQueue.clear(npcData.npc)
    npcData.npc:faceThisObject(npcData.target)
    npcData.isAttacking = true

    local weapon = npcData.npc:getPrimaryHandItem(); if not weapon then return end
    if not weapon:isRanged() then
        MyLittleAttack.TryAttackMelee(npcData, weapon)
    else
        MyLittleAttack.TryAttackRanged(npcData, weapon)
    end
end

--- Stop the NPC from attacking.
---@param npcData table The variable containing the NPC's persistent data.
---@param dontResetAnims boolean|nil Indicates if animations should not be reset.
MyLittleAttack.StopAttacking = function(npcData, dontResetAnims)
    ISTimedActionQueue.clear(npcData.npc)
    npcData.isAttacking = false

    if dontResetAnims then return end
    npcData.npc:NPCSetAttack(false)
    npcData.npc:NPCSetMelee(false)
    npcData.npc:NPCSetAiming(false)
end

--- Check if the target is within the attack range of the NPC.
---@param npcData table The variable containing the NPC's persistent data.
---@return boolean Returns true if the target is within attack range, otherwise false.
MyLittleAttack.IsInAttackRange = function(npcData)

    local weapon = npcData.npc:getPrimaryHandItem()
    if not weapon then return false end

    if MyLittleUtils.DistanceBetween(npcData.npc, npcData.target) <=  weapon:getMaxRange() then
        return true
    end

    return false
end