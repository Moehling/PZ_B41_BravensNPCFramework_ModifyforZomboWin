-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

local count = 0
local managedNPCs = {}

MyLittleDoorManager = {}

--- Subscribe to this Module to handle NPC closing doors automatically.
---@param newData table The variable containing the NPC's persistent data.
MyLittleDoorManager.ManageNPC = function(newData)
    table.insert(managedNPCs, newData)
end

MyLittleDoorManager.RemoveNPC = function(npcID)
    for i, npcData in ipairs(managedNPCs) do
        if npcID == npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- Check and close the door if open within the NPC's proximity.
local checkAndCloseDoor = function()
    for _, npcData in ipairs(managedNPCs) do
        if not npcData.closingDoor then
            local npcSquare = npcData.npc:getSquare()
            local door = MyLittleUtils.FetchDoorInSquare(npcSquare)
            if door then
                if door:IsOpen() then
                    npcData.closingDoor = true
                    MyLittleUtils.DelayFunction(function()
                        door:ToggleDoor(npcData.npc)
                        npcData.closingDoor = false
                    end, 50)
                end
            end
        end
    end
end

--- OnTick event handler to periodically check and close doors.
local onTick = function()
    if #managedNPCs == 0 then return end
    count = count + 1
    if count >= 20 then
        checkAndCloseDoor()
        count = 0
    end
end

Events.OnTick.Add(onTick)