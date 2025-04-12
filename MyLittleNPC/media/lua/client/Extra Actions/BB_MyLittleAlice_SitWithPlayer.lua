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
    if not MyLittleAlice.target == player then return end
    if MyLittleAlice.target:isSitOnGround() then return end
    if MyLittleUtils.DistanceBetween(MyLittleAlice.npc, MyLittleAlice.target) > 2 then return end

    MyLittleUtils.DelayFunction(function()
        MyLittleAlice.npc:reportEvent("EventSitOnGround")
        if ZombRand(1, 10) <= 5 then
            MyLittleAlice.npc:faceThisObject(MyLittleAlice.target)
        end
    end, ZombRand(100, 200))
end