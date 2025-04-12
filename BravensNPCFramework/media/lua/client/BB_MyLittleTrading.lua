-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleTrading = {} -- 主模块表
local managedNPCs = {} -- 存储被管理的NPC数据

--- 注册NPC到交易管理列表
---@param newData table 包含NPC数据的表（需有uniqueID和npc字段）
MyLittleTrading.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

--- 从管理列表中移除指定NPC
---@param npcID string NPC的唯一标识符
MyLittleTrading.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- 让玩家走向NPC（如果距离过远）
---@param playerObj IsoPlayer 玩家对象
---@param npc IsoPlayer NPC对象
local function walkToNPC(playerObj, npc)
    if MyLittleUtils.DistanceBetween(npc, playerObj) > 2 then
        local npcSq = npc:getSquare()
        local targetSq = AdjacentFreeTileFinder.FindClosest(npcSq, playerObj) or npcSq
        ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(playerObj, targetSq:getX(), targetSq:getY(), targetSq:getZ()))
    end
end

--- 获取指定类型的物品列表
---@param mainContainer ItemContainer 容器对象
---@param itemType string 物品类型
---@param mustBeUnequipped boolean 是否必须未装备
---@return table 物品列表
local function getItemsOfType(mainContainer, itemType, mustBeUnequipped)
    local randomWeirdVar = mainContainer:getAllTypeRecurse(itemType)
    local itemList = {}

    for i=1,randomWeirdVar:size() do
        local item = randomWeirdVar:get(i-1)
        if not mustBeUnequipped then
            table.insert(itemList, item)
        elseif not item:isEquipped() and item:getAttachedSlot() == -1 then
            table.insert(itemList, item)
        end
    end

    return itemList
end

--- 处理单次交易
---@param playerObj IsoPlayer 玩家对象
---@param npcData table NPC数据
---@param tradeType string 交易类型（Give/Take）
---@param item Item 交易物品
---@param context ISContextMenu 上下文菜单
local function handleSingleTrade(playerObj, npcData, tradeType, item, context)
    if tradeType == "Give" then
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) -- 确保物品在玩家主库存
        if item:isEquipped() then ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, 50)) end
    else
        ISInventoryPaneContextMenu.transferIfNeeded(npcData.npc, item) -- 确保物品在NPC主库存
    end

    ISTimedActionQueue.add(MyLittleTimedActions:TradeWithNPC(npcData, playerObj, tradeType, item)) -- 添加交易动作
    MyLittleUtils.LockMovement(npcData, false) -- 解锁NPC移动
    context:closeAll()
end

--- 尝试与NPC交易
---@param playerObj IsoPlayer 玩家对象
---@param npcData table NPC数据
---@param tradeType string 交易类型（Give/Take）
---@param item Item|table 单个物品或物品列表
---@param quantity number 交易数量
---@param context ISContextMenu 上下文菜单
---@param dontWalk boolean 是否禁用自动移动
local function tryTradeWithNPC(playerObj, npcData, tradeType, item, quantity, context, dontWalk)
    if not dontWalk then
        walkToNPC(playerObj, npcData.npc) -- 自动靠近NPC
    end

    -- 40%概率播放交易语音
    if ZombRand(1, 10) <= 4 then
        local randSpeech = ZombRand(1,6)
        MyLittleSpeech.Say(npcData, "Trading_" .. randSpeech)
    end

    -- 批量处理
    if type(item) == "table" then
        for i, singleItem in ipairs(item) do
            if i <= quantity then
                handleSingleTrade(playerObj, npcData, tradeType, singleItem, context)
            else
                return
            end
        end
    else
        handleSingleTrade(playerObj, npcData, tradeType, item, context)
    end
end

--- 尝试交易所有指定物品
---@param playerObj IsoPlayer 玩家对象
---@param npcData table NPC数据
---@param characterInv ItemContainer 角色库存
---@param tradeType string 交易类型
---@param items table 物品列表
---@param context ISContextMenu 上下文菜单
local function tryTradeEverything(playerObj, npcData, characterInv, tradeType, items, context)
    walkToNPC(playerObj, npcData.npc)
    for _, item in ipairs(items) do
        if not item:isEquipped() and item:getAttachedSlot() == -1 then
            local itemList = getItemsOfType(characterInv, item:getType(), true)
            tryTradeWithNPC(playerObj, npcData, tradeType, item, #itemList, context, true)
        end
    end
end

--- 检查值是否在列表中
---@param value any 要检查的值
---@param list table 目标列表
---@return boolean 是否存在
local function isInList(value, list)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

--- 添加负重提示到菜单选项
---@param option ISContextMenuOption 菜单选项
---@param isRed boolean 是否显示为红色（超重）
---@param currWeight number 当前负重
---@param totalWeight number 总容量
---@param extraWeight number 额外增加的负重
local function addInvWeightTooltip(option, isRed, currWeight, totalWeight, extraWeight)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    option.toolTip = tooltip

    local description = getText("IGUI_char_Weight") .. " " .. MyLittleUtils.RoundToDecimalPlaces(currWeight, 2)
    if extraWeight then
        description = description .. " (+ " .. MyLittleUtils.RoundToDecimalPlaces(extraWeight, 2)  .. ")"
    end

    description = description .. " / " .. MyLittleUtils.RoundToDecimalPlaces(totalWeight, 2)

    if (isRed) then
        description = "<RGB:1,0.2,0.2>" .. description
    end

    tooltip.description = description
end

--- 检查交易是否会导致超重
---@param option ISContextMenuOption 菜单选项
---@param itemWeight number 物品重量
---@param currCharacterWeight number 当前负重
---@param maxCharacterWeight number 最大负重
local function checkIfOverburdened(option, itemWeight, currCharacterWeight, maxCharacterWeight)
    if currCharacterWeight + itemWeight > maxCharacterWeight then
        option.notAvailable = true -- 禁用选项
        addInvWeightTooltip(option, true, currCharacterWeight, maxCharacterWeight, itemWeight)
    else
        addInvWeightTooltip(option, false, currCharacterWeight, maxCharacterWeight, itemWeight)
    end
end

--- 添加批量交易子菜单
local function addBulkMenu(npcData, tradeType, submenu, context, items, itemCount, itemWeight, character, currCharacterWeight, maxCharacterWeight)
    local bulkGiveOption = submenu:addOption(items[1]:getName())
    local bulkGiveSubmenu = ISContextMenu:getNew(context)
    context:addSubMenu(bulkGiveOption, bulkGiveSubmenu)

    local amounts = {100, 50, 25, 10, 5, 4, 3, 2, 1} -- 预设数量选项
    for _, count in ipairs(amounts) do
        if itemCount >= count then
            local option = bulkGiveSubmenu:addOption(tostring(count), character, tryTradeWithNPC, npcData, tradeType, items, count, context)
            checkIfOverburdened(option, itemWeight * count, currCharacterWeight, maxCharacterWeight)
        end
    end

    local allOption = bulkGiveSubmenu:addOptionOnTop(getText("ContextMenu_All"), character, tryTradeWithNPC, npcData, tradeType, items, itemCount, context)
    checkIfOverburdened(allOption, itemWeight * itemCount, currCharacterWeight, maxCharacterWeight)
end

--- 计算实际最大容量（包括容器）
---@param charInventory ItemContainer 角色库存
---@param character IsoPlayer 角色对象
---@return number 实际容量
local function getActualMaxCapacity(charInventory, character)
    local maxPersonCapacity = charInventory:getEffectiveCapacity(character)
    local maxBagCapacity = 0

    -- 累加已装备容器的容量
    for i=0, charInventory:getItems():size() - 1 do
        local item = charInventory:getItems():get(i)
        if item:isEquipped() and instanceof(item, "InventoryContainer") then
            maxBagCapacity = maxBagCapacity + item:getEffectiveCapacity(character)
        end
    end

    return maxPersonCapacity + maxBagCapacity
end

--- 世界对象右键菜单事件
local onWorldContextMenu = function(player, context, worldobjects, test)
    if clickedPlayer then
        local clickedNPCData = nil
        for _, npcData in ipairs(managedNPCs) do
            if clickedPlayer == npcData.npc then
                clickedNPCData = npcData

                local playerObj = getSpecificPlayer(player)
                local playerInv = playerObj:getInventory()
                local currPlayerWeight = playerInv:getCapacityWeight()
                local maxPlayerWeight = playerInv:getEffectiveCapacity(playerObj)

                local npcInv = clickedNPCData.npc:getInventory()
                local currBravenWeight = npcInv:getCapacityWeight()
                local maxBravenWeight = getActualMaxCapacity(npcInv, clickedNPCData.npc)
                local listedItems = { "KeyRing" } -- 默认忽略钥匙串

                -- ===== 交易主菜单 =====
                local tradeOption = context:addOptionOnTop(getText("ContextMenu_Trade", clickedNPCData.npc:getFullName()))
                local tradeSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(tradeOption, tradeSubmenu)

                -- ===== NPC状态菜单 =====
                local statusOption = context:addOptionOnTop(getText("UI_Scoreboard_Stats"))
                local statusSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(statusOption, statusSubmenu)
                local invStatsOption = statusSubmenu:addOption(getText("IGUI_Controller_Inventory"))
                addInvWeightTooltip(invStatsOption, false, currBravenWeight, maxBravenWeight, nil)

                -- ===== 给予物品菜单 =====
                local giveOption = tradeSubmenu:addOption(getText("ContextMenu_Give"))
                local giveSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(giveOption, giveSubmenu)

                local looseItemsPlayer = {} -- 玩家可交易物品
                local playerItems = playerInv:getItems()

                for i = 0, playerItems:size() - 1 do
                    local item = playerItems:get(i)
                    if not item:isEquipped() and item:getAttachedSlot() == -1 then
                        local itemType = item:getType()

                        -- 忽略非空容器和钥匙串
                        if not (instanceof(item, "InventoryContainer") and item:getInventoryWeight() > 0) then
                            if not isInList(itemType, listedItems) then
                                local itemList = getItemsOfType(playerInv, itemType, true)
                                local itemWeight = item:getWeight()

                                -- 单个或批量选项
                                if #itemList < 2 then
                                    local option = giveSubmenu:addOption(item:getName(), playerObj, tryTradeWithNPC, clickedNPCData, "Give", item, 1, context)
                                    checkIfOverburdened(option, itemWeight, currBravenWeight, maxBravenWeight)
                                else
                                    addBulkMenu(clickedNPCData, "Give", giveSubmenu, context, itemList, #itemList, itemWeight, playerObj, currBravenWeight, maxBravenWeight)
                                end

                                table.insert(listedItems, itemType)
                            end
                        end

                        if itemType ~= "KeyRing" then
                            table.insert(looseItemsPlayer, item)
                        end
                    end
                end

                -- 全部给予选项
                if #looseItemsPlayer > 1 then
                    giveSubmenu:addOptionOnTop(getText("ContextMenu_All"), playerObj, tryTradeEverything, clickedNPCData, playerInv, "Give", looseItemsPlayer, context)
                end

                -- ===== 拿走物品菜单 =====
                local takeOption = tradeSubmenu:addOption(getText("ContextMenu_Take"))
                local takeSubmenu = ISContextMenu:getNew(context)
                context:addSubMenu(takeOption, takeSubmenu)
                listedItems = { } -- 重置已列出物品

                local looseItemsNPC = {} -- NPC可交易物品
                local NPCItems = npcInv:getItems()

                for i=0, NPCItems:size() - 1 do
                    local item = npcInv:getItems():get(i)
                    -- 忽略伤口、已装备或附加物品
                    if item:getDisplayCategory() ~= "Wound" and not item:isEquipped() and item:getAttachedSlot() == -1 then
                        local itemType = item:getType()

                        if not isInList(itemType, listedItems) then
                            local itemList = getItemsOfType(npcInv, itemType, true)
                            local itemWeight = item:getWeight()

                            -- 单个或批量选项
                            if #itemList < 2 then
                                local option = takeSubmenu:addOption(item:getName(), playerObj, tryTradeWithNPC, clickedNPCData, "Take", item, 1, context)
                                checkIfOverburdened(option, itemWeight, currPlayerWeight, maxPlayerWeight)
                            else
                                addBulkMenu(clickedNPCData, "Take", takeSubmenu, context, itemList, #itemList, itemWeight, playerObj, currPlayerWeight, maxPlayerWeight)
                            end

                            table.insert(listedItems, itemType)
                        end

                        table.insert(looseItemsNPC, item)
                    end
                end

                -- 全部拿走选项
                if #looseItemsNPC > 1 then
                    takeSubmenu:addOptionOnTop(getText("ContextMenu_All"), playerObj, tryTradeEverything, clickedNPCData, npcInv, "Take", looseItemsNPC, context)
                end
            end
        end
    end

    return context
end

Events.OnFillWorldObjectContextMenu.Add(onWorldContextMenu) -- 注册右键菜单事件