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
    if not MyLittleMoehling.target == player then return end
    if MyLittleMoehling.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleMoehling.npc, MyLittleMoehling.target) > 2 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleMoehling.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 5 then
            MyLittleMoehling.npc:faceThisObject(MyLittleMoehling.target)
        end
    end, ZombRand(100, 200))
end