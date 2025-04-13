-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleSave = {}
local managedNPCs = {}

--- Subscribe to this Module to save the Inventory of an NPC in a custom stash.
---@param newData table The variable containing the NPC's persistent data.
MyLittleSave.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleSave.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end


local saveStash = function(npcData)
    if npcData.FirstStart == false then
        local stashSq = MyLittleUtils.FetchRandomSquare(MyLittleUtils.playerObj:getSquare())
        if stashSq then
            npcData.stashCoordsX = stashSq:getX()
            npcData.stashCoordsY = stashSq:getY()
            local stash = IsoObject.new(getCell(), stashSq, "furniture_storage_02_29")
            if stash then
                stashSq:AddSpecialObject(stash)
                stash:getModData().isBravenNPCStash = true
                stash:transmitCompleteItemToClients()
                stash:transmitModData()

                local container = ItemContainer.new()
                stash:setContainer(container)

                local npcInv = npcData.npc:getInventory()
				
                local itemCount = npcInv:getItems():size()
                for i = itemCount - 1, 0, -1 do
                    local item = npcInv:getItems():get(i)
                    if item then
                        container:AddItem(item)
                    end
                end
            end
        end
    end
end

-- 热恢复npc出厂设置，点击退出到桌面，后点取消
MyLittleSave.restoreSettings = function ()
    for _, npcData in ipairs(managedNPCs) do
        local playerSq = MyLittleUtils.playerObj:getSquare()
        local targetSq = AdjacentFreeTileFinder.FindClosest(playerSq, MyLittleUtils.playerObj) or playerSq

        local cachedAesthetics = npcData.npc:getDescriptor()
        local cachedInv = npcData.npc:getInventory()

        -- npcData.npc:setInvisible(true)
        npcData.npc = nil
        npcData.npc = IsoPlayer.new(getWorld():getCell(), cachedAesthetics, targetSq:getX(), targetSq:getY(), targetSq:getZ())
        npcData.npc:setInventory(cachedInv)


        npcData.npc:setZombiesDontAttack(false)
        npcData.npc:setNoClip(true)
        local playerObj = MyLittleUtils.playerObj
        npcData.npc:faceThisObject(playerObj)
        npcData.npc:getModData().isBravenNPC = true
        npcData.npc:setSceneCulled(false)
        npcData.npc:setNPC(true)
        npcData.setGod = npcData.setGod or false
        npcData.knockDownisGod = npcData.knockDownisGod or false
        npcData.npc:setGodMod(npcData.setGod)
        npcData.npc:setInvisible(false)
        npcData.npc:reportEvent("EventSitOnGround")
        local Sq = npcData.npc:getSquare()
        MyLittleUtils.DelayFunction(function ()
        ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npcData.npc, Sq:getX() + ZombRand(-2, 2), Sq:getY() + ZombRand(-2, 2), Sq:getZ()))
        end,400)

        npcData.Acceptable_numbers = npcData.Acceptable_numbers or 15
        npcData.superzombie = npcData.superzombie or false
        npcData.test = npcData.test or false
        npcData.target = npcData.target or playerObj
        npcData.infiniteAmmo = npcData.infiniteAmmo or false
        npcData.resupplyAmmo = npcData.resupplyAmmo or false
        npcData.ignoreBites = npcData.ignoreBites or false
        npcData.isTough = npcData.isTough or false
        npcData.fasterHealing = npcData.fasterHealing or false
        npcData.regenHealth = npcData.regenHealth ~= false
        npcData.noNeeds = npcData.noNeeds or false
        npcData.outfitName = npcData.outfitName or ""
        npcData.canFlee = npcData.canFlee ~= false
        npcData.isEssential = npcData.isEssential or false
        npcData.aimSpeedMultiplier = npcData.aimSpeedMultiplier or 1
        npcData.fleeDistance = npcData.fleeDistance or 5
        npcData.combatStance = npcData.combatStance or "Balanced"
        npcData.acknowledgeEmote = npcData.acknowledgeEmote or "thumbsup"
        npcData.dialogueStringPrefix = npcData.dialogueStringPrefix or ""
        npcData.speechSfx = npcData.speechSfx
        local speechColor = { R = 1, G = 1, B = 1 }
        if npcData.speechColor and type(npcData.speechColor) == "table" then speechColor = npcData.speechColor end
        npcData.speechColor = speechColor

        if npcData.isTough then
            npcData.npc:getTraits():add("ThickSkinned")
            SyncXp(npcData.npc)
        end

        npcData.forceStop = npcData.forceStop or false
        npcData.inknock = false
        npcData.isInVehicle = false
        npcData.reacting = false
        npcData.isSpeaking = false
        npcData.currSpeech = ""
        npcData.currVehicle = nil
        npcData.weaponIsRanged = false
        npcData.isFleeing = false
        npcData.knockDownHealth = npcData.knockDownHealth or 15
        npcData.knockDowncooldown = npcData.knockDowncooldown or 60
        npcData.needCloseDoors = npcData.needCloseDoors or false

        local npcInv = npcData.npc:getInventory()
        local stashCoords = { X = npcData.stashCoordsX, Y = npcData.stashCoordsY}
        MyLittleUtils.TryLoadInventory(npcData, npcInv, stashCoords )
    end
end
--- Saves the Stash location of every NPC, no file management needed.
MyLittleSave.OnSave = function(npc)
    -- if (MyLittleUtils.playerObj and MyLittleUtils.playerObj:getHoursSurvived() <= 0.3) then return end

    if not npc then
        for _, npcData in ipairs(managedNPCs) do
            npcData.npc:setZombiesDontAttack(false)
            npcData.npc:setInvisible(false)
            npcData.npc:setNoClip(true)
            npcData.npc:setGodMod(npcData.setGod)
            npcData.inknock = false
            saveStash(npcData)
        end
    else
        saveStash(npc)
    end

    print("SAVED INVENTORY! SHOW THIS IN BUG REPORTS IF NEEDED!")
end

local onMainMenuMouseDown = MainScreen.onMenuItemMouseDownMainMenu

MainScreen.onMenuItemMouseDownMainMenu = function(item, x, y)
    if MainScreen.instance.inGame == true and item.internal == "EXIT" then
        MyLittleSave.OnSave()
    end
    if MainScreen.instance.inGame == true and item.internal == "QUIT_TO_DESKTOP" then
        MyLittleSave.restoreSettings()
    end

    onMainMenuMouseDown(item, x, y)
end
-- 保存原函数
local originalOnConfirmQuitToDesktop = MainScreen.onConfirmQuitToDesktop

-- 劫持函数
MainScreen.onConfirmQuitToDesktop = function(self, button)
    -- 如果玩家点击了"YES"（确认退出）
    if button.internal == "YES" then
        -- 检查是否在游戏中（避免在菜单界面误保存）
        if MainScreen.instance and MainScreen.instance.inGame then
            MyLittleSave.OnSave()  -- 调用你的保存逻辑
        end
    end

    -- 调用原函数（确保原有的退出逻辑仍然执行）
    return originalOnConfirmQuitToDesktop(self, button)
end
