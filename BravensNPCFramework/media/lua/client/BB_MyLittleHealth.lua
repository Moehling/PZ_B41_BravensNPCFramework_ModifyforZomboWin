-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- **             With help by Aiteron             **
-- **************************************************

MyLittleHealth = {}
local managedNPCs = {}
local knockedDownNPCs = {}
local counter = 0

--- Subscribe to this Module to handle the following NPC properties:
---<br> Ignore Bites - ON
---<br> Regen Health - ON
---<br> Faster Healing - ON
---<br> Is Essential - ON
---<br> No Needs - ON
---@param newData table The variable containing the NPC's persistent data.
MyLittleHealth.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleHealth.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

-- Function called to make an NPC fall and standby.
local function knockDown(npcData)
    local npcStats = { iterations = 0, cooldown = npcData.knockDowncooldown, npc = npcData.npc, setGod = npcData.setGod, inknock = npcData.inknock}
    table.insert(knockedDownNPCs, npcStats)
    -- npcData.npc:setInvisible(true)
    -- npcData.npc:setZombiesDontAttack(true)
    npcData.npc:setGodMod(npcData.knockDownisGod)
    npcData.npc:setNoClip(true)
    npcData.npc:setBumpType("stagger")
    npcData.npc:setVariable("BumpDone", false)
    npcData.npc:setVariable("BumpFall", true)
    npcData.npc:setVariable("BumpFallType", "pushedFront")
    npcData.inknock = true
end

MyLittleHealth.knockDown_Over = function (index, npcStats, indicesToRemove)
    local bodyDamage = npcStats.npc:getBodyDamage()
    if bodyDamage then
        local bodyParts = bodyDamage:getBodyParts()
        for i=0,BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
            local bodyPart = bodyParts:get(i)
            if bodyPart:getHealth() < 100 then
                bodyPart:SetHealth(100)
            end
        end
    end

    npcStats.npc:setZombiesDontAttack(false)
    npcStats.npc:setInvisible(false)
    npcStats.npc:setNoClip(true)
    npcStats.npc:setGodMod(npcStats.setGod)
    table.insert(indicesToRemove, index)
    npcStats.inknock = false
    return indicesToRemove
end

--- Function called on every tick to manage health behavior.
local onTick = function()
    if #managedNPCs == 0 then return end
    counter = counter + 1
    if counter >= 30 then
        for _, npcData in ipairs(managedNPCs) do
            local bodyDamage = npcData.npc:getBodyDamage()
            if bodyDamage then
                local bodyParts = bodyDamage:getBodyParts()
                for i=0,BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
                    local bodyPart = bodyParts:get(i)
                    if npcData.ignoreBites then
                        if bodyPart:bitten() or bodyPart:getBiteTime() ~= 0 then
                            bodyPart:SetBitten(false)
                            bodyPart:SetInfected(false)
                            bodyPart:SetFakeInfected(false)
                            bodyPart:setInfectedWound(false)
                            bodyPart:setBiteTime(0)
                        end
                    end

                    if npcData.regenHealth then
                        if bodyPart:getHealth() < 100 then
                            bodyPart:SetHealth(bodyPart:getHealth() + 0.15)
                        end
                    end

                    if npcData.fasterHealing then
                        if bodyPart:getBleedingTime() > 0 then
                            bodyPart:setBleedingTime(bodyPart:getBleedingTime() - 0.25)
                        end

                        if bodyPart:getScratchTime() > 0 then
                            bodyPart:setScratchTime(bodyPart:getScratchTime() - 0.4)
                        end

                        if bodyPart:getCutTime() > 0 then
                            bodyPart:setCutTime(bodyPart:getCutTime() - 0.25)
                        end

                        if bodyPart:getWoundInfectionLevel() > 0 then
                            bodyPart:setWoundInfectionLevel(0)
                        end
                    end
                end

                if npcData.isEssential then
                    if bodyDamage:getOverallBodyHealth() <= npcData.knockDownHealth and not npcData.inknock then
                        knockDown(npcData)
                    end
                end
            end

            if npcData.noNeeds then
                local stats = npcData.npc:getStats()
                if stats:getHunger() > 0.1 then
                    stats:setHunger(0)
                end

                if stats:getThirst() > 0.1 then
                    stats:setThirst(0)
                end

                if stats:getFatigue() > 0.1 then
                    stats:setFatigue(0)
                end

                if stats:getEndurance() <= 0.9 then
                    stats:setEndurance(1)
                end

                if bodyDamage:getFoodSicknessLevel() > 0.1 then
                    bodyDamage:setFoodSicknessLevel(0)
                end
            end
        end

        if #knockedDownNPCs > 0 then
            local indicesToRemove = {}
            local multiplier = MyLittleUtils.GetGameSpeed() or 1
            for index, npcStats in ipairs(knockedDownNPCs) do
                if npcStats.iterations < npcStats.cooldown then
                    --
                    npcStats.iterations = npcStats.iterations + multiplier
                    npcStats.npc:reportEvent("EventSitOnGround")
                else
                    indicesToRemove = MyLittleHealth.knockDown_Over(index, npcStats, indicesToRemove)
                    -- local Sq = npcStats.npc:getSquare()
                    -- ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(npcStats.npc, Sq:getX() + ZombRand(0, 1), Sq:getY() + ZombRand(0, 1), Sq:getZ()))
                end
            end

            for i = #indicesToRemove, 1, -1 do
                table.remove(knockedDownNPCs, indicesToRemove[i])
            end
        end

        counter = 0
    end
end

-- -- 保存原函数
-- local originalOnSave = MyLittleSave.OnSave

-- -- 劫持保存函数
-- MyLittleSave.OnSave = function(npc)
--     -- 检查并恢复所有倒地的NPC
--     if #knockedDownNPCs > 0 then
--         local indicesToRemove = {}
--         for index, npcStats in ipairs(knockedDownNPCs) do
--             -- 强制结束倒地状态（跳过冷却时间检查）
--             indicesToRemove = MyLittleHealth.knockDown_Over(index, npcStats, indicesToRemove)
--         end
        
--         -- 清理已恢复的NPC
--         for i = #indicesToRemove, 1, -1 do
--             table.remove(knockedDownNPCs, indicesToRemove[i])
--         end
--     end

--     -- 调用原保存逻辑
--     originalOnSave(npc)
-- end

Events.OnTick.Add(onTick)

local function onCharacterDeath(character)
    for _, npcData in ipairs(managedNPCs) do
        if npcData.isEssential and npcData.stashCoordsX and npcData.stashCoordsY and npcData.npc == character then
            MyLittleSave.OnSave(npcData)
            character:removeFromWorld()
            character:removeFromSquare()
        end
    end
end

Events.OnCharacterDeath.Add(onCharacterDeath)