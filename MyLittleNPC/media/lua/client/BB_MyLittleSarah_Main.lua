-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleSarah = {}

local function initModData()
    MyLittleSarah = ModData.get("MyLittleSarah")
    if MyLittleSarah then return end

    MyLittleSarah = ModData.create("MyLittleSarah")
    MyLittleSarah.FirstStart = true
end

Events.OnInitGlobalModData.Add(initModData)

local function addAndWearItem(inventory, character, itemType)
    local item = InventoryItemFactory.CreateItem("Base." .. itemType)
    if item then
        inventory:AddItem(item)
        character:setWornItem(item:getBodyLocation(), item)
        return item
    end

    return nil
end

local function spawnSarah()
    local playerObj = getPlayer()
    local playerSq = playerObj:getSquare()

    local Sarah_parameters = {
        isFemale = true,  -- NPC性别
        firstName = "Sarah",  -- NPC名字
        lastName = "",  -- NPC姓氏（默认为空）
        hairstyle = "OverEye",  -- NPC发型
        hairColor = { R = 1, G = 1, B = 1 },  -- NPC发色
        skinColorIndex = 1,  -- NPC肤色索引（默认为1）
        speechColor = { R = 0.88, G = 0.22, B = 0.94 },  -- NPC语音颜色
        isEssential = SandboxVars.BB_MyLittleSarah.isEssential, -- 是否为重要角色（默认为false）
		forceStop = SandboxVars.BB_MyLittleSarah.forceStop, -- 强制停止移动（默认false）
        setGod = SandboxVars.BB_MyLittleNPCs.setGod, -- 启用无敌
        outfitName = SandboxVars.BB_MyLittleSarah.outfitName,  -- NPC初始服装（默认为空）
        Acceptable_numbers = SandboxVars.BB_MyLittleNPCs.Acceptable_numbers, -- npc投降可以接受的数目，数量超过4，有闪退风险
        superzombie = SandboxVars.BB_MyLittleNPCs.superzombie, -- 切换投降时，是否直接传送给僵尸（立即进入动画），而不是慢慢走过去
        spawnSq = playerSq,  -- NPC生成位置
        faceObj = playerObj,  -- NPC生成后面向的对象（应该为playerObj）
        target = playerObj,  -- NPC的目标对象（应该为playerObj）
        forceSq = false,  -- 是否强制在指定位置生成（默认为false）
        infiniteAmmo = SandboxVars.BB_MyLittleNPCs.infiniteAmmo,  -- 是否有无限弹药（默认为false）
        resupplyAmmo = false,  -- 是否可以自动补充弹药（默认为false）
        ignoreBites = SandboxVars.BB_MyLittleNPCs.ignoreBites,  -- 是否忽略僵尸咬伤（默认为true）
        isTough = SandboxVars.BB_MyLittleNPCs.isTough,  -- 是否为“坚韧”类型（默认为true）
        regenHealth = SandboxVars.BB_MyLittleNPCs.regenHealth,  -- 是否自动恢复健康（默认为true）
        fasterHealing = SandboxVars.BB_MyLittleNPCs.fasterHealing,  -- 是否加速恢复（默认为true）
        noNeeds = SandboxVars.BB_MyLittleNPCs.noNeeds,  -- 是否没有需求（如饥饿、口渴等）（默认为true）
        canFlee = SandboxVars.BB_MyLittleNPCs.canFlee,  -- 是否可以逃跑（默认为true，启用逃跑）
        needCloseDoors = SandboxVars.BB_MyLittleNPCs.CloseDoors, -- 是否自动关门
        aimSpeedMultiplier = 0.5,  -- NPC瞄准速度乘数（默认为0.5）
        fleeDistance = 5,  -- NPC逃跑距离（默认为5）
        combatStance = "Balanced",  -- NPC战斗姿态（默认为“Balanced”）
        dialogueStringPrefix = "IGUI_MyLittleNPCs_",  -- NPC对话字符串前缀
        speechSfx = nil,  -- NPC语音音效（默认为nil）
        acknowledgeEmote = "thumbsup",  -- NPC确认动作（默认为“thumbsup”）
        test = SandboxVars.BB_MyLittleNPCs.test, -- 测试其他功能
        knockDownHealth = SandboxVars.BB_MyLittleNPCs.knockDownHealth, -- 战败血线
        knockDowncooldown = SandboxVars.BB_MyLittleNPCs.knockDowncooldown, -- 战败恢复读秒
        knockDownisGod = SandboxVars.BB_MyLittleNPCs.isGod, -- 战败无敌吗
    }

    MyLittleSarah.npc = BB_NPCFramework.CreateNPC(MyLittleSarah, Sarah_parameters)

    local modules = { true, true, true, MyLittleSarah.needCloseDoors, true, true, true, true, true, true }
    local setupStatus = BB_NPCFramework.SubscribeNPCToModules(MyLittleSarah, modules)

    if setupStatus == "CUSTOMIZE" then
        local inventory = MyLittleSarah.npc:getInventory()
        if MyLittleSarah.outfitName then
            addAndWearItem(inventory, MyLittleSarah.npc, MyLittleSarah.outfitName)
        else
            local crowbar = InventoryItemFactory.CreateItem("Base.Crowbar")
            if crowbar then
                inventory:AddItem(crowbar)
                MyLittleSarah.npc:setPrimaryHandItem(crowbar)
                MyLittleSarah.npc:setSecondaryHandItem(crowbar)
                MyLittleSarah.weaponIsRanged = false
            end
            addAndWearItem(inventory, MyLittleSarah.npc, "Braven_Mask")
            addAndWearItem(inventory, MyLittleSarah.npc, "Braven_HoodieUP")
            addAndWearItem(inventory, MyLittleSarah.npc, "Braven_Gloves")
            addAndWearItem(inventory, MyLittleSarah.npc, "Braven_Trousers")
        end

        local itemCount = inventory:getItems():size()
        for i = itemCount - 1, 0, -1 do
            local item = inventory:getItems():get(i)
            item:getModData().equippedByBravenNPC = true
        end
    end
end

local onGameStart = function()
    spawnSarah()
	
end

Events.OnGameStart.Add(onGameStart)

local function onCharacterDeath(character)
    if character ~= MyLittleSarah.npc then return end

    MyLittleUtils.DelayFunction(function()
        spawnSarah()
    end, 1800, true)
end

Events.OnCharacterDeath.Add(onCharacterDeath)