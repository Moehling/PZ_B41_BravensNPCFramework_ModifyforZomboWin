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
    if not MyLittleEva.target == player then return end
    if MyLittleEva.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleEva.npc, MyLittleEva.target) > 2 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleEva.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 5 then
            MyLittleEva.npc:faceThisObject(MyLittleEva.target)
        end
    end, ZombRand(100, 200))
end