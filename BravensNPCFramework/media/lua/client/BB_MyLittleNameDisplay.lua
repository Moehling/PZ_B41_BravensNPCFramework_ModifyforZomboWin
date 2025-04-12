-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- **             With help by Aiteron             **
-- **************************************************

MyLittleNameDisplay = {}
local managedNPCs = {}

--- Subscribe to this Module to handle an NPC's name tag.
---@param newData table The variable containing the NPC's persistent data.
MyLittleNameDisplay.ManageNPC = function(newData)

    local sortedData = {
        npcData = newData,
        prevSq = nil,
        nameTagBubble = nil
    }

    table.insert(managedNPCs, sortedData)
end

MyLittleNameDisplay.RemoveNPC = function(npcID)
    for i, sortedData in ipairs(managedNPCs) do
        if npcID == sortedData.npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- Remove the speech bubble associated with a specific sorted data.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function tryRemoveNameTagBubble(sortedData)
    if sortedData.nameTagBubble then
        sortedData.nameTagBubble:Clear()
        sortedData.nameTagBubble = nil
    end
end

--- Get the screen coordinates for rendering speech text.
---@param npc table The NPC object.
---@return number, number -- The X and Y screen coordinates.
local function getTagCoords(npc)
    local x, y, z = npc:getX(), npc:getY(), npc:getZ()
    local sx = IsoUtils.XToScreen(x, y, z, 0) - IsoCamera.getOffX() - npc:getOffsetX()
    local sy = IsoUtils.YToScreen(x, y, z, 0) - IsoCamera.getOffY() - npc:getOffsetY()
    sy = sy - getCore():getScreenHeight() / 100.0 * 13

    sx = sx / getCore():getZoom(0)
    sy = sy / getCore():getZoom(0)

    return sx, sy
end

--- Draw text on the screen as part of the speech bubble.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function drawText(sortedData)
    local x, y = getTagCoords(sortedData.npcData.npc)
    tryRemoveNameTagBubble(sortedData)

    sortedData.nameTagBubble = TextDrawObject.new()
    sortedData.nameTagBubble:setAllowAnyImage(true)
    sortedData.nameTagBubble:setDefaultFont(UIFont.Small)
    local npcName = sortedData.npcData.npc:getFullName()
    sortedData.nameTagBubble:ReadString(npcName)
    sortedData.nameTagBubble:setAllowChatIcons(true)
    sortedData.nameTagBubble:setDefaultColors(1, 1, 1, 1)
    sortedData.nameTagBubble:AddBatchedDraw(x, y, true)
end

--- Manage the speech behavior for a specific NPC.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function manageNameTag(sortedData)

    local npcSq = sortedData.npcData.npc:getSquare()
    if sortedData.prevSq ~= npcSq then
        drawText(sortedData)
        sortedData.prevSq = npcSq
    end

    local square = sortedData.npcData.npc:getSquare()
    if not square then return end

    local x, y = getTagCoords(sortedData.npcData.npc)
    tryRemoveNameTagBubble(sortedData)

    sortedData.nameTagBubble = TextDrawObject.new()
    sortedData.nameTagBubble:setAllowAnyImage(true)
    sortedData.nameTagBubble:setDefaultFont(UIFont.Small)
    local npcName = sortedData.npcData.npc:getFullName()
    sortedData.nameTagBubble:ReadString(npcName)
    sortedData.nameTagBubble:setAllowChatIcons(true)
    sortedData.nameTagBubble:setDefaultColors(1, 1, 1, 1)
    sortedData.nameTagBubble:AddBatchedDraw(x, y, true)
end

--- Function called on every tick to manage name tag behavior.
local onTick = function()
    if #managedNPCs == 0 then return end
    for _, sortedData in ipairs(managedNPCs) do
        if sortedData.npcData.npc:getSquare():isCanSee(0) then
            manageNameTag(sortedData)
        end
    end
end

Events.OnTick.Add(onTick)