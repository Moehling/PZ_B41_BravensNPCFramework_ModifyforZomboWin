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
    if not MyLittleBob.target == player then return end
    if MyLittleBob.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleBob.npc, MyLittleBob.target) > 5 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleBob.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 10 then
            MyLittleBob.npc:faceThisObject(MyLittleBob.target)
        end
    end, ZombRand(100, 200))
end