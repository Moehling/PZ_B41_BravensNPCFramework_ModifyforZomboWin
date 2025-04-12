-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleOrders = {} -- 主模块表
local managedNPCs = {} -- 存储被管理的NPC数据

--- 注册NPC到管理列表
---@param newData table 包含NPC数据的表（需有uniqueID和npc字段）
MyLittleOrders.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

--- 从管理列表中移除指定NPC
---@param npcID string NPC的唯一标识符
MyLittleOrders.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- 尝试装备物品到NPC
---@param npcData table NPC数据
---@param item Item 要装备的物品
---@param equipType string 装备类型（Primary/Secondary/BothHands）
---@param context ISContextMenu 上下文菜单对象
local function TryEquipItem(npcData, item, equipType, context)
    -- 40%概率播放装备武器语音
    if ZombRand(1, 10) <= 4 then
        local randSpeech = 1
        if item:IsWeapon() then
            randSpeech = ZombRand(1,4)
            MyLittleSpeech.Say(npcData, "Equip_Weapon_" .. randSpeech)
        end
    end

    -- 清空当前手持物品
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

    -- 根据类型装备物品
    if equipType == "Primary" then
        npcData.npc:setPrimaryHandItem(item)
    elseif equipType == "Secondary" then
        npcData.npc:setSecondaryHandItem(item)
    elseif equipType == "BothHands" or item:isRequiresEquippedBothHands() then
        npcData.npc:setPrimaryHandItem(item)
        npcData.npc:setSecondaryHandItem(item)
    end

    npcData.weaponIsRanged = item:isRanged() -- 标记是否为远程武器
    item:getModData().equippedByBravenNPC = true -- 标记物品已被装备
    context:closeAll() -- 关闭菜单
end

--- 尝试装备服装
---@param npcData table NPC数据
---@param items table 要装备的物品列表
---@param time number 动作耗时
---@param context ISContextMenu 上下文菜单对象
local function TryEquipClothing(npcData, items, time, context)
    for _, item in ipairs(items) do
        local location = nil
        if not instanceof(item, "InventoryContainer") then
            location = item:getBodyLocation() -- 获取服装部位
        else
            location = item:canBeEquipped() -- 容器装备位置
        end

        -- 如果该部位已有装备，先卸下
        local wornItem = npcData.npc:getWornItem(location)
        if wornItem then
            if wornItem ~= item then
                ISTimedActionQueue.add(ISUnequipAction:new(npcData.npc, wornItem, time))
                wornItem:getModData().equippedByBravenNPC = nil
            else
                context:closeAll()
                return
            end
        end

        ISTimedActionQueue.add(ISWearClothing:new(npcData.npc, item, time)) -- 添加穿戴动作
        item:getModData().equippedByBravenNPC = true -- 标记物品已被装备
    end

    -- 40%概率播放装备服装语音
    if ZombRand(1, 10) <= 4 then
        local randSpeech = ZombRand(1,4)
        MyLittleSpeech.Say(npcData, "Equip_Clothing_" .. randSpeech)
    end

    context:closeAll()
end

--- 尝试卸下物品
---@param npc IsoPlayer NPC对象
---@param items table 要卸下的物品列表
---@param time number 动作耗时
---@param context ISContextMenu 上下文菜单对象
local function TryUnequipItems(npc, items, time, context)
    for _, item in ipairs(items) do
        ISTimedActionQueue.add(ISUnequipAction:new(npc, item, time)) -- 添加卸下动作
        item:getModData().equippedByBravenNPC = nil -- 清除装备标记
    end
    context:closeAll()
end

--- 设置战斗姿态
---@param npcData table NPC数据
---@param newState string 新状态（Offensive/Balanced/Defensive）
---@param context ISContextMenu 上下文菜单对象
local function setCombatStance(npcData, newState, context)
    -- 延迟播放确认表情
    MyLittleUtils.DelayFunction(function() npcData.npc:playEmote(npcData.acknowledgeEmote) end, ZombRand(20, 100))
    MyLittleUtils.AcknowledgeAction(npcData) -- 执行确认动作
    MyLittleUtils.SetCombatStance(npcData, newState) -- 设置战斗姿态
    context:closeAll()

    local randSpeech = -1
    -- 40%概率播放对应语音
    if ZombRand(1, 10) <= 4 then
        randSpeech = ZombRand(1,4)
    end

    if newState == "Offensive" then
        if randSpeech ~= -1 then
            MyLittleSpeech.Say(npcData, "CombatMode_Offensive_" .. randSpeech)
        end
    elseif newState == "Balanced" then
        if randSpeech ~= -1 then
            MyLittleSpeech.Say(npcData, "CombatMode_Balanced_" .. randSpeech)
        end
    else
        npcData.target = getPlayer() -- 防御模式下以玩家为目标
        if randSpeech ~= -1 then
            MyLittleSpeech.Say(npcData, "CombatMode_Defensive_" .. randSpeech)
        end
    end
end

--- 添加武器装备子菜单
local function addEquipWeaponMenu(npcData, item, context, equipSubmenu)
    local equipTypeOption = equipSubmenu:addOption(item:getName())
    local equipTypeSubmenu = ISContextMenu:getNew(context)
    context:addSubMenu(equipTypeOption, equipTypeSubmenu)
    -- 添加装备选项（主手/副手/双手）
    equipTypeSubmenu:addOption(getText("ContextMenu_Equip_Primary"), npcData, TryEquipItem, item, "Primary", context)
    equipTypeSubmenu:addOption(getText("ContextMenu_Equip_Secondary"), npcData, TryEquipItem, item, "Secondary", context)
    equipTypeSubmenu:addOption(getText("ContextMenu_Equip_Two_Hands"), npcData, TryEquipItem, item, "BothHands", context)
end

--- 锁定NPC移动
local function lockMovement(npcData, newState, context)
    MyLittleUtils.DelayFunction(function() npcData.npc:playEmote(npcData.acknowledgeEmote) end, ZombRand(20, 100))
    MyLittleUtils.AcknowledgeAction(npcData)
    MyLittleUtils.LockMovement(npcData, newState) -- 锁定或解锁移动
    context:closeAll()
end

--- 世界对象右键菜单事件
local onWorldContextMenu = function(player, context, worldobjects, test)
    if clickedPlayer then
        local clickedNPCData = nil
        for _, npcData in ipairs(managedNPCs) do
            if clickedPlayer == npcData.npc then
                clickedNPCData = npcData
                local npcInv = clickedNPCData.npc:getInventory()

                -- ===== 命令菜单 =====
                local orderOption = context:addOptionOnTop(getText("ContextMenu_Orders"))
                local orderSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(orderOption, orderSubmenu)

                -- ===== 装备菜单 =====
                local equipOption = orderSubmenu:addOption(getText("ContextMenu_Equip"))
                local equipSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(equipOption, equipSubmenu)

                -- 武器子菜单
                local equipWeaponOption = equipSubmenu:addOption(getText("IGUI_ItemCat_Weapon"))
                local equipWeaponSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(equipWeaponOption, equipWeaponSubmenu)

                -- 服装子菜单
                local equipClothingOption = equipSubmenu:addOption(getText("IGUI_ItemCat_Clothing"))
                local equipClothingSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(equipClothingOption, equipClothingSubmenu)

                -- ===== 卸下菜单 =====
                local unequipOption = orderSubmenu:addOption(getText("ContextMenu_Unequip"))
                local unequipSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(unequipOption, unequipSubmenu)

                -- 武器子菜单
                local unequipWeaponOption = unequipSubmenu:addOption(getText("IGUI_ItemCat_Weapon"))
                local unequipWeaponSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(unequipWeaponOption, unequipWeaponSubmenu)

                -- 服装子菜单
                local unequipClothingOption = unequipSubmenu:addOption(getText("IGUI_ItemCat_Clothing"))
                local unequipClothingSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(unequipClothingOption, unequipClothingSubmenu)

                -- ===== 物品分类处理 =====
                local allEquippedClothing = {} -- 已装备的服装
                local allUnequippedClothing = {} -- 未装备的服装
                local looseItemsBraven = {} -- 松散物品
                local bravenItems = npcInv:getItems()

                for i=0, bravenItems:size() - 1 do
                    local item = npcInv:getItems():get(i)
                    if item:getDisplayCategory() ~= "Wound" then
                        -- 未装备的物品
                        if not item:isEquipped() and item:getAttachedSlot() == -1 then
                            -- 服装类
                            if item:IsClothing() or instanceof(item, "InventoryContainer") then
                                equipClothingSubmenu:addOption(item:getName(), clickedNPCData, TryEquipClothing, { item }, 50, context)
                                table.insert(allEquippedClothing, item)
                            end
                            table.insert(looseItemsBraven, item)
                        else -- 已装备的物品
                            if item:IsWeapon() then
                                unequipWeaponSubmenu:addOption(item:getName(), clickedNPCData.npc, TryUnequipItems, { item }, 50, context)
                            end
                            if item:IsClothing() or instanceof(item, "InventoryContainer") then
                                unequipClothingSubmenu:addOption(item:getName(), clickedNPCData.npc, TryUnequipItems, { item }, 50, context)
                                table.insert(allUnequippedClothing, item)
                            end
                        end

                        -- 武器类
                        if item:IsWeapon() then
                            addEquipWeaponMenu(clickedNPCData, item, context, equipWeaponSubmenu)
                        end
                    end
                end

                -- ===== 批量操作选项 =====
                if #allEquippedClothing > 1 then
                    equipClothingSubmenu:addOptionOnTop(getText("ContextMenu_All"), clickedNPCData, TryEquipClothing, allEquippedClothing, 50, context)
                end
                if #allUnequippedClothing > 1 then
                    unequipClothingSubmenu:addOptionOnTop(getText("ContextMenu_All"), clickedNPCData.npc, TryUnequipItems, allUnequippedClothing, 50, context)
                end

                -- ===== 战斗姿态菜单 =====
                local stanceOption = orderSubmenu:addOption(getText("ContextMenu_CombatStance"))
                local stanceSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(stanceOption, stanceSubmenu)
                stanceSubmenu:addOption(getText("ContextMenu_Offensive"), clickedNPCData, setCombatStance, "Offensive", context)
                stanceSubmenu:addOption(getText("ContextMenu_Balanced"), clickedNPCData, setCombatStance, "Balanced", context)
                stanceSubmenu:addOption(getText("ContextMenu_Defensive"), clickedNPCData, setCombatStance, "Defensive", context)

                -- ===== 移动控制选项 =====
                orderSubmenu:addOption(getText("IGUI_Emote_Stop"), clickedNPCData,lockMovement, true, context)
                orderSubmenu:addOption(getText("IGUI_Emote_FollowMe"), clickedNPCData, lockMovement, false, context)
            end
        end
    end

    return context
end

Events.OnFillWorldObjectContextMenu.Add(onWorldContextMenu) -- 注册右键菜单事件