-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

MyLittleEmotions = {}
local onEmote = ISEmoteRadialMenu.emote
local managedNPCs = {}

--- Subscribe to this Module to handle NPC reactions to emotes.
---@param newData table The variable containing the NPC's persistent data.
MyLittleEmotions.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleEmotions.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- Override the emote function to add custom behavior.
---@param emote string The emote triggered by the player.
function ISEmoteRadialMenu:emote(emote)
    onEmote(self, emote)

    for _, npcData in ipairs(managedNPCs) do
        if not npcData.inknock then
            if not npcData.reacting then
                if MyLittleUtils.DistanceBetween(npcData.npc, getPlayer()) >= 35 then
                    if emote == "comehere" then
                        ISTimedActionQueue.clear(npcData.npc)
                        MyLittleMovement.RespawnAtPlayer(npcData)
                        return -- 只来一个
                    end
                end
                npcData.npc:faceThisObject(getPlayer())
                if emote == "shout" then
                elseif emote == "surrender" then
                    ISTimedActionQueue.clear(npcData.npc)
                    MyLittleCombat.HandleSurrender(npcData, 25, true)
                elseif emote == "wavehi" or emote == "wavehi02" or emote == "wavebye" then
                    MyLittleUtils.DelayFunction(function() npcData.npc:playEmote("wavebye") end, ZombRand(20, 100))
                elseif emote == "stop" or emote == "freeze" then
                    -- npcData.playerinSurrender = false
                    npcData.isInSurrender = false
                    MyLittleAttack.StopAttacking(npcData)
                    MyLittleUtils.LockMovement(npcData, true)
                    MyLittleUtils.DelayFunction(function() npcData.npc:playEmote(npcData.acknowledgeEmote) end, ZombRand(20, 100))
                elseif emote == "followme" or  emote == "comefront" then
                    MyLittleUtils.LockMovement(npcData, false)
                    -- npcData.playerinSurrender = false
                    npcData.isInSurrender = false
                    MyLittleAttack.StopAttacking(npcData)
                    MyLittleUtils.DelayFunction(function() npcData.npc:playEmote(npcData.acknowledgeEmote) end, ZombRand(20, 100))
                -- else
                --     npcData.npc:playEmote(emote)
                end

                if not (emote == "wavehi" or emote == "wavehi02" or emote == "wavebye" or emote == "surrender") then
                    MyLittleUtils.AcknowledgeAction(npcData)
                end

                npcData.reacting = true
                MyLittleUtils.DelayFunction(function() npcData.reacting = false end, 20)
            end
        end
    end
end