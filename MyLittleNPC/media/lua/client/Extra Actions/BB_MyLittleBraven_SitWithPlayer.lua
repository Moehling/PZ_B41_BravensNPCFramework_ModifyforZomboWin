-- **************************************************
-- ██████  ██████   █████  ██    ██ ███████ ███    ██ 
-- ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██ 
-- ██████  ██████  ███████ ██    ██ █████   ██ ██  ██ 
-- ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██ 
-- ██████  ██   ██ ██   ██   ████   ███████ ██   ████
-- **************************************************
-- ** Seek Excellence! Employ ME, not my Copycats. **
-- **************************************************

local onSitOnGround = ISWorldObjectContextMenu.onSitOnGround

ISWorldObjectContextMenu.onSitOnGround = function(player)
    onSitOnGround(player)
    if not MyLittleBraven.target == player then return end
    if MyLittleBraven.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleBraven.npc, MyLittleBraven.target) > 3 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleBraven.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 5 then
            MyLittleBraven.npc:faceThisObject(MyLittleBraven.target)
        end
    end, ZombRand(100, 200))
end