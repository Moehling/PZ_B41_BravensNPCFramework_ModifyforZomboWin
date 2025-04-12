-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- **             With help by Aiteron             **
-- **************************************************

MyLittleSpeech = {}
local managedNPCs = {}

--- Remove the speech bubble associated with a specific sorted data.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function tryRemoveSpeechBubble(sortedData)
    if sortedData.speechBubble then
        sortedData.speechBubble:Clear()
        sortedData.speechBubble = nil
    end
end

--- Get the screen coordinates for rendering speech text.
---@param npc table The NPC object.
---@return number, number -- The X and Y screen coordinates.
local function getSayCoords(npc)
    local x, y, z = npc:getX(), npc:getY(), npc:getZ()
    local sx = IsoUtils.XToScreen(x, y, z, 0) - IsoCamera.getOffX() - npc:getOffsetX()
    local sy = IsoUtils.YToScreen(x, y, z, 0) - IsoCamera.getOffY() - npc:getOffsetY()
    sy = sy - getCore():getScreenHeight() / 100.0 * 13

    sx = sx / getCore():getZoom(0)
    sy = sy / getCore():getZoom(0)

    sy = sy - 16 / 2 - 20

    return sx, sy
end

--- Draw text on the screen as part of the speech bubble.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function drawText(sortedData)
    local x, y = getSayCoords(sortedData.npcData.npc)
    tryRemoveSpeechBubble(sortedData)

    sortedData.speechBubble = TextDrawObject.new()
    sortedData.speechBubble:setAllowAnyImage(true)
    sortedData.speechBubble:setDefaultFont(UIFont.Dialogue)
    sortedData.speechBubble:ReadString(sortedData.npcData.currSpeech)
    sortedData.speechBubble:setAllowChatIcons(true)
    local color = sortedData.npcData.speechColor
    sortedData.speechBubble:setDefaultColors(color.R, color.G, color.B, sortedData.alpha)
    sortedData.speechBubble:AddBatchedDraw(x, y, true)
end

--- Manage the speech behavior for a specific NPC.
---@param sortedData table The sorted data containing NPC information and speech bubble.
local function manageSpeech(sortedData)

    sortedData.count = (sortedData.count + 1) * MyLittleUtils.GetGameSpeed()

    if sortedData.count >= sortedData.dialogueDuration then
        sortedData.count = 0
        sortedData.alpha = 0
        sortedData.prevSq = nil
        sortedData.npcData.isSpeaking = false
        sortedData.npcData.currSpeech = ""
        tryRemoveSpeechBubble(sortedData)
    else
        local npcSq = sortedData.npcData.npc:getSquare()
        if sortedData.prevSq ~= npcSq then
            drawText(sortedData)
            sortedData.prevSq = npcSq
        end
    end

    local square = sortedData.npcData.npc:getSquare()
    if not square then return end

    local x, y = getSayCoords(sortedData.npcData.npc)
    tryRemoveSpeechBubble(sortedData)

    if sortedData.count < sortedData.fadeInDuration then
        sortedData.alpha = sortedData.count / sortedData.fadeInDuration
    elseif sortedData.count < sortedData.fadeOutDuration then
        sortedData.alpha = 1
    else
        sortedData.alpha = 1 - (sortedData.count - sortedData.fadeOutDuration) / (sortedData.dialogueDuration - sortedData.fadeOutDuration)
    end

    sortedData.speechBubble = TextDrawObject.new()
    sortedData.speechBubble:setAllowAnyImage(true)
    sortedData.speechBubble:setDefaultFont(UIFont.Dialogue)
    sortedData.speechBubble:ReadString(sortedData.npcData.currSpeech)
    sortedData.speechBubble:setAllowChatIcons(true)
    local color = sortedData.npcData.speechColor
    sortedData.speechBubble:setDefaultColors(color.R, color.G, color.B, sortedData.alpha)
    sortedData.speechBubble:AddBatchedDraw(x, y, true)
end

local function containsAny(longString, stringTable)
    for _, subString_ in ipairs(stringTable) do
        -- 确保 subString_ 是一个表，并且第一个元素是字符串
        if type(subString_) == "table" and type(subString_[1]) == "string" then
            local subString = subString_[1]
            if longString:find(subString) then
                return true, subString  -- 找到匹配的子字符串，返回 true 和匹配的子字符串
            end
        else
            -- 如果 subString_ 不是期望的格式，可以在这里处理错误或跳过
            print("Invalid entry in stringTable:", subString_)
        end
    end
    return false, nil  -- 没有找到匹配的子字符串，返回 false 和 nil
end

local baseString = {
    {"ZWbanMoraleF_",6},
    {"ZWbanMoraleH_",7},
    {"ZW1Strip_",6},
    {"ZW1Perverse_",6},
    {"ZWreBandit_",6},
    {"ZWbanRapist_",6}
}
--- Make an NPC say a specified text.
---@param npcData table The variable containing the NPC's persistent data.
---@param text string The text to be spoken.
---@param override boolean|nil Override current speech.
MyLittleSpeech.Say = function(npcData, text, override)
    
    for _, sortedData in ipairs(managedNPCs) do
        if npcData == sortedData.npcData then
            if override or not sortedData.npcData.isSpeaking then
                local proceed = true -- 使用标志变量控制是否继续执行

                if sortedData.npcData.dialogueStringPrefix ~= "" and sortedData.npcData.isFemale then

                    local fetchedText = getText(sortedData.npcData.dialogueStringPrefix .. text)
                    if fetchedText == sortedData.npcData.dialogueStringPrefix .. text then
                        sortedData.npcData.isSpeaking = false
                        return
                    end
                    sortedData.npcData.currSpeech = fetchedText or text
                elseif sortedData.npcData.dialogueStringPrefix ~= "" and not sortedData.npcData.isFemale then
                    local found, _ = containsAny(text, baseString)
                    if found then
                        local fetchedText = getText(sortedData.npcData.dialogueStringPrefix .. text)
                        if fetchedText == sortedData.npcData.dialogueStringPrefix .. text then
                            sortedData.npcData.isSpeaking = false
                            return
                        end
                        sortedData.npcData.currSpeech = fetchedText or text
                    else
                        sortedData.npcData.isSpeaking = false
                        proceed = false -- 设置标志变量，跳过后续逻辑
                    end
                else
                    sortedData.npcData.currSpeech = "MAKE A IG_UI_EN.txt FILE AND SET THE DIALOGUE STRING PREFIX"
                end

                if proceed then -- 检查标志变量
                
                    if override then
                        sortedData.count = 0
                        sortedData.alpha = 0
                        sortedData.prevSq = nil
                    end

                    sortedData.npcData.isSpeaking = true
                    sortedData.dialogueDuration = 12 * #sortedData.npcData.currSpeech
                    sortedData.fadeOutDuration = sortedData.fadeInDuration + (sortedData.dialogueDuration - sortedData.fadeInDuration) / 1.2
                    if npcData.speechSfx then
                        npcData.npc:playSound(npcData.speechSfx)
                    end
                end
            end
        end
    end
end
-- IGUI_MyLittleNPCs_secret_Female_1
local function secret_say(npcData)
    MyLittleSpeech.Say(npcData, "secret_Female_" .. ZombRand(1,10))
end
local function getRandomDialogueKey(isFemale)


    local gender = "Male_"

    if isFemale then
        gender = "Female_"
        local a = ZombRand(1, 9)
        if a >= 7 then
            return "secret_Female_" .. ZombRand(1, 10)
        else
            return baseString[a][1] .. gender .. ZombRand(1, baseString[a][2])
        end

    else
        local a = ZombRand(1, 7)
        return baseString[a][1] .. gender .. ZombRand(1, baseString[a][2])
    end
end

MyLittleSpeech.F__kSay = function (npcData)
    local isFemale = npcData.npc:isFemale()
    -- if ZombRand(1,3) <= 2 and isFemale then
    --     secret_say(npcData)
    --     return
    -- end
    MyLittleUtils.DelayFunction(function ()
    MyLittleSpeech.Say(npcData, getRandomDialogueKey(isFemale))
    end, ZombRand(100,200))
    -- MyLittleUtils.DelayFunction(function ()
    -- MyLittleSpeech.Say(npcData, getRandomDialogueKey(isFemale))
    -- end, ZombRand(200,500))
    -- MyLittleUtils.DelayFunction(function ()
    -- MyLittleSpeech.Say(npcData, getRandomDialogueKey(isFemale))
    -- end, ZombRand(500,1000))
    -- MyLittleUtils.DelayFunction(function ()
    -- MyLittleSpeech.Say(npcData, getRandomDialogueKey(isFemale))
    -- end, ZombRand(1000,1500))
end
--- Subscribe to this Module to handle NPC speech.
---@param newData table The variable containing the NPC's persistent data.
MyLittleSpeech.ManageNPC = function(newData)

    local sortedData = {
        npcData = newData,
        count = 0,
        dialogueDuration = 0,
        prevSq = nil,
        alpha = 0,
        fadeInDuration = 15,
        fadeOutDuration = 0,
        speechBubble = nil
    }

    table.insert(managedNPCs, sortedData)
end

MyLittleSpeech.RemoveNPC = function(npcID)
    for i, sortedData in ipairs(managedNPCs) do
        if npcID == sortedData.npcData.uniqueID then
            table.remove(managedNPCs, i)
            break
        end
    end
end

--- Function called on every tick to manage speech behavior.
local onTick = function()
    if #managedNPCs == 0 then return end
    for _, sortedData in ipairs(managedNPCs) do
        if sortedData.npcData.isSpeaking == true then
            manageSpeech(sortedData)
        end
    end
end

Events.OnTick.Add(onTick)