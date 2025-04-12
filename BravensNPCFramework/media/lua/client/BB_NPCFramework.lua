-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

BB_NPCFramework = { }

--- Function to generate a random unique ID
local function generateUniqueID()
    local timestamp = os.time()
    local randomFraction = ZombRand(0, 2)

    local timestampString = tostring(timestamp)
    local randomString = tostring(randomFraction):sub(3)
    local uniqueID = timestampString .. randomString

    return uniqueID
end

---@param npcData table The variable containing the NPC's persistent data.
---@param properties table The variable containing how you want the NPC to be. <br>
-- @field spawnSq IsoGridSquare The spawn square for the NPC. <br>
-- @field faceObj IsoObject The object to face when spawned. <br>
-- @field target IsoObject The target for the NPC. <br>
-- @field forceSq boolean If true, force the NPC to spawn at the specified spawn square without finding a nearby free tile. <br>
-- @field isFemale boolean If true, the NPC will be female; otherwise, it will be male. <br>
-- @field firstName string The first name of the NPC. <br>
-- @field lastName string The last name of the NPC. <br>
-- @field outfitName string The name of the outfit for the NPC to wear. <br>
-- @field hairStyle string The hairstyle of the NPC. <br>
-- @field hairColor table The hair color of the NPC as a table with R, G, B values (e.g., {R=0.5, G=0.3, B=0.1}). <br>
-- @field skinColorIndex number The index representing the skin color of the NPC. <br>
-- @field infiniteAmmo boolean If true, the NPC has infinite ammo. <br>
-- @field resupplyAmmo boolean If true, the NPC can resupply ammo. <br>
-- @field ignoreBites boolean If true, the NPC ignores bites. <br>
-- @field isTough boolean If true, the NPC is tough. <br>
-- @field fasterHealing boolean If true, the NPC heals faster. <br>
-- @field regenHealth boolean If true, the NPC regenerates health. <br>
-- @field noNeeds boolean If true, the NPC has no needs like hunger, sleep, etc. <br>
-- @field canFlee boolean If true, the NPC can flee. <br>
-- @field aimSpeedMultiplier number The multiplier for NPC's aiming speed. <br>
-- @field fleeDistance number The distance within which the NPC will flee. <br>
-- @field combatStance string The combat stance of the NPC ("Defensive", "Normal", "Aggressive"). <br>
-- @field dialogueStringPrefix string The prefix for NPC's dialogue strings. <br>
-- @field speechSfx string The sound effect for NPC's speech. <br>
-- @field speechColor table The color of NPC's speech text as a table with R, G, B values. <br>
BB_NPCFramework.CreateNPC = function(npcData, properties)

    local npcAesthetics = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, properties.isFemale or false)
    npcData.isFemale = properties.isFemale
    npcAesthetics:setForename(properties.firstName or "Braven")
    npcAesthetics:setSurname(properties.lastName or "")
    -- 这会导致从箱子加载相同部位服装时，间断性裸体或背包总会有一个初始服装，相关补丁在MyLittleUtils.TryLoadInventory
    -- npcAesthetics:dressInNamedOutfit(properties.outfitName or "")

    local npcVisuals = npcAesthetics:getHumanVisual()
    npcVisuals:setHairModel(properties.hairStyle or "OverEye")

    local hairColor = ImmutableColor.new(ZombRandFloat(0.0,1.0), ZombRandFloat(0.0,1.0), ZombRandFloat(0.0,1.0), 1)
    if properties.hairColor and type(properties.hairColor) == "table" then
        hairColor = ImmutableColor.new(properties.hairColor.R, properties.hairColor.G, properties.hairColor.B, 1)
    end

    npcVisuals:setHairColor(hairColor)
    npcVisuals:setSkinTextureIndex(properties.skinColorIndex or 1)

    local playerObj = getPlayer()
    local targetSq = nil
    if not properties.forceSq then
        targetSq = AdjacentFreeTileFinder.FindClosest(properties.spawnSq or playerObj:getSquare(), playerObj) or playerObj:getSquare()
    else
        targetSq = properties.spawnSq or playerObj:getSquare()
    end

    local npc = IsoPlayer.new(getWorld():getCell(), npcAesthetics, targetSq:getX() + ZombRand(-1,2), targetSq:getY() + ZombRand(-1,2), targetSq:getZ())
    npc:getModData().isBravenNPC = true
    npc:setSceneCulled(false)
    npc:setNPC(true)
    npcData.setGod = properties.setGod
    npcData.knockDownisGod = properties.knockDownisGod
    npc:setGodMod(npcData.setGod)
    npc:setInvisible(false)
    npc:reportEvent("EventSitOnGround")
    local Sq = npc:getSquare()
    MyLittleUtils.DelayFunction(function ()
        ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npc, Sq:getX() + ZombRand(-2, 2), Sq:getY() + ZombRand(-2, 2), Sq:getZ()))
    end,400)

    if properties.faceObj then npc:faceThisObject(properties.faceObj) end
    npcData.Acceptable_numbers = properties.Acceptable_numbers
    npcData.superzombie = properties.superzombie
    npcData.test = properties.test
    npcData.target = properties.target or playerObj
    npcData.infiniteAmmo = properties.infiniteAmmo or false
    npcData.resupplyAmmo = properties.resupplyAmmo or false
    npcData.ignoreBites = properties.ignoreBites or false
    npcData.isTough = properties.isTough or false
    npcData.fasterHealing = properties.fasterHealing or false
    if properties.regenHealth == nil then -- 语法只有当前面为nil才输出true
		npcData.regenHealth = true
	else
		npcData.regenHealth = properties.regenHealth
	end
    npcData.noNeeds = properties.noNeeds or false
	npcData.outfitName = properties.outfitName or ""
	if properties.canFlee == nil then -- 语法只有当前面为nil才输出true
		npcData.canFlee = true
	else
		npcData.canFlee = properties.canFlee
	end
    npcData.isEssential = properties.isEssential or false
    npcData.aimSpeedMultiplier = properties.aimSpeedMultiplier or 1
    npcData.fleeDistance = properties.fleeDistance or 5
    npcData.combatStance = properties.combatStance or "Balanced"
    npcData.acknowledgeEmote = properties.acknowledgeEmote or "thumbsup"
    npcData.dialogueStringPrefix = properties.dialogueStringPrefix or ""
    npcData.speechSfx = properties.speechSfx or nil
    local speechColor = { R = 1, G = 1, B = 1 }
    if properties.speechColor and type(properties.speechColor) == "table" then speechColor = properties.speechColor end
    npcData.speechColor = speechColor

    if npcData.isTough then
        npc:getTraits():add("ThickSkinned")
        SyncXp(npc)
    end

    npcData.forceStop = properties.forceStop or false
    npcData.isInVehicle = false
    npcData.inknock = false
    npcData.reacting = false
    npcData.isSpeaking = false
    npcData.currSpeech = ""
    npcData.currVehicle = nil
    npcData.weaponIsRanged = false
    npcData.isFleeing = false
    npcData.knockDownHealth = properties.knockDownHealth
    npcData.knockDowncooldown = properties.knockDowncooldown
    npcData.needCloseDoors = properties.needCloseDoors
    npcData.uniqueID = generateUniqueID()

    return npc
end

--- Automatically load the NPC's inventory from its stash, IF this isn't the first time it is being generated.
--- <br> IF it *is* the first time the NPC is being generated, this will return "CUSTOMIZE".
--- <br> Up to you what you do then, like giving the NPC its starting gear.
---@param npcData table The variable containing the NPC's persistent data.
BB_NPCFramework.SetupNPC = function(npcData)
    local npcInv = npcData.npc:getInventory()
    if npcData.FirstStart == false then
        local stashCoords = { X = npcData.stashCoordsX, Y = npcData.stashCoordsY}
        if not stashCoords.X or not stashCoords.Y then
            return "FAILURE! STASH COORDS NOT SAVED."
        end

        MyLittleUtils.TryLoadInventory(npcData, npcInv, stashCoords )
        return "LOADED"
    else
        npcData.FirstStart = false
        return "CUSTOMIZE"
    end
end

--- Just to keep code clean. This automatically subscribes an NPC to ALL modules.
---@param npcData table The variable containing the NPC's persistent data.
BB_NPCFramework.SubscribeNPCToAllModules = function(npcData)
    MyLittleSave.ManageNPC(npcData)
    MyLittleMovement.ManageNPC(npcData)
    MyLittleEmotions.ManageNPC(npcData)
    MyLittleDoorManager.ManageNPC(npcData)
    MyLittleSpeech.ManageNPC(npcData)
    MyLittleCombat.ManageNPC(npcData)
    MyLittleNameDisplay.ManageNPC(npcData)
    MyLittleHealth.ManageNPC(npcData)
    MyLittleTrading.ManageNPC(npcData)
    MyLittleOrders.ManageNPC(npcData)

    local setupResult = BB_NPCFramework.SetupNPC(npcData)
    return setupResult
end

--- Subscribes an NPC to given modules.
---@param npcData table The variable containing the NPC's persistent data.
---@param enableModules table A table of boolean values indicating whether to enable each module.
BB_NPCFramework.SubscribeNPCToModules = function(npcData, enableModules)
    local modules = {
        MyLittleSave,
        MyLittleMovement,
        MyLittleEmotions,
        MyLittleDoorManager,
        MyLittleSpeech,
        MyLittleCombat,
        MyLittleNameDisplay,
        MyLittleHealth,
        MyLittleTrading,
        MyLittleOrders,
    }

    enableModules = enableModules or {}

    for i, module in ipairs(modules) do
        local isEnabled = enableModules[i] or false
        if isEnabled then
            module.ManageNPC(npcData)
        end
    end

    if enableModules[1] == true then
        local setupResult = BB_NPCFramework.SetupNPC(npcData)
        return setupResult
    else
        return "LOADED"
    end
end

--- PLEASE CALL THIS WHEN YOUR NPC DIES! You are responsible for checking WHEN that happens.
---@param npcID number The NPC's unique ID.
BB_NPCFramework.UnsubscribeNPCFromAllModules = function(npcID)
    MyLittleSave.RemoveNPC(npcID)
    MyLittleMovement.RemoveNPC(npcID)
    MyLittleEmotions.RemoveNPC(npcID)
    MyLittleDoorManager.RemoveNPC(npcID)
    MyLittleSpeech.RemoveNPC(npcID)
    MyLittleCombat.RemoveNPC(npcID)
    MyLittleNameDisplay.RemoveNPC(npcID)
    MyLittleHealth.RemoveNPC(npcID)
    MyLittleTrading.RemoveNPC(npcID)
    MyLittleOrders.RemoveNPC(npcID)
end