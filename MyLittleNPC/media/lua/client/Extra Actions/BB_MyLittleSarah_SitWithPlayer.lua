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
    if not MyLittleSarah.target == player then return end
    if MyLittleSarah.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleSarah.npc, MyLittleSarah.target) > 2 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleSarah.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 5 then
            MyLittleSarah.npc:faceThisObject(MyLittleSarah.target)
        end
    end, ZombRand(100, 200))
end