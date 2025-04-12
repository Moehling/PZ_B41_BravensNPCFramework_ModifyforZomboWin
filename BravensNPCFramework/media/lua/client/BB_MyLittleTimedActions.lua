-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

require "TimedActions/ISBaseTimedAction"

MyLittleTimedActions = ISBaseTimedAction:derive("MyLittleTimedActions")

MyLittleTimedActions.isValid = function(self)
    return true
end

MyLittleTimedActions.start = function(self)
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Mid")
end

MyLittleTimedActions.stop = function(self)
    ISBaseTimedAction.stop(self)
    self.npcData.forceStop = false
end

MyLittleTimedActions.perform = function(self)

    if self.typeTimeAction == "Trade" then

        local playerInv = self.playerObj:getInventory()
        local npcInv = self.npcData.npc:getInventory()

        if self.tradeType == "Give" then
            npcInv:AddItem(self.item)
            playerInv:Remove(self.item)
        else
            npcInv:Remove(self.item)
            playerInv:AddItem(self.item)
        end

        self.npcData.forceStop = false
    end

    ISBaseTimedAction.perform(self)
end

local function calculateActionTime(itemWeight)
    local baseTicks = 50
    local scaleFactor = 30
    local minTicks = 1
    local minWeightThreshold = 0.099

    if itemWeight < minWeightThreshold then
        return minTicks
    else
        local actionTicks = baseTicks + scaleFactor * math.log(itemWeight + 1)
        return math.max(actionTicks, minTicks)
    end
end

MyLittleTimedActions.TradeWithNPC = function(self, npcData, playerObj, tradeType, item)

    local action = ISBaseTimedAction.new(self, playerObj)
    action.typeTimeAction = "Trade"
    action.npcData = npcData
    action.playerObj = playerObj
    action.tradeType = tradeType
    action.item = item
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = calculateActionTime(item:getWeight())
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then action.maxTime = 1 end
    return action
end

return TimeAction