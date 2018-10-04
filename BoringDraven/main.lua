print("Bore's Draven Loaded!")

local Draven = {
    _NAME        = "BoringDraven",
    _TYPE        = "lua",
    _URL         = "https://raw.githubusercontent.com/DepressedBore/hanbot/master/Draven/",
    _DESCRIPTION = "First Script on HanBot. I wonder how its gonna turn out.."
}
module.lib("MediocreLib")
module.lib("DivineLib")
module.load("DivineLib", "net").update(Draven._NAME, Draven._TYPE, Draven._URL) 

local orb         = module.internal("orb")
local Interrupter = module.load("MediocreLib", "interrupter")
local OnDash      = module.load("MediocreLib", "dash")
local Spell       = module.load("MediocreLib", "spell")
local Utils       = module.load("DivineLib", "util")
local Common      = module.load("MediocreLib", "common")

function Draven.__init()
    --[[Data Initialization]]
    Draven.scriptVersion = "1.0"
    Draven.LoadMenu()    
    Draven.Spells()
    Draven.AxeList = {}
    Draven.AxeCount = 0
    --[[Default Callbacks]]   
    cb.add(cb.tick, Draven.OnTick)
    cb.add(cb.draw, Draven.OnDraw)
    cb.add(cb.create_particle, Draven.OnCreateObj)
    cb.add(cb.delete_particle, Draven.OnDeleteObj)
    cb.add(cb.issueorder, Draven.OnIssueOrder)               
    --[[Custom Callbacks]]    
    Interrupter(Draven.OnInterruptable)
    OnDash(Draven.OnDash)                      
end

function Draven.Spells()
    Draven.Q = Spell({
        slot = 0,
        range = 0,
        delay = 0.25,
        speed = 0,
        radius = 0,
        collision = false,
        from = player,
        type = "Press",
        dmgType = "Physical"        
    })
    Draven.W = Spell({
        slot = 1,
        range = 0,
        delay = 0.25,
        speed = 0,
        radius = 0,
        collision = false,
        from = player,
        type = "Press"
    })
    Draven.E = Spell({
        slot = 2,
        range = 950,
        delay = 0.25,
        speed = 1400,
        width = 100,
        collision = {hero = false, minion = false},
        from = player,
        type = "Linear",
        boundingRadiusMod = 1
    })
    Draven.R = Spell({
        slot = 3,
        range = 1500, --huge
        delay = 0.4,
        speed = 2000,
        width = 160,
        collision = { hero = true, minion = false },
        from = player,
        type = "Linear",
        dmgType = "Physical",
        boundingRadiusMod = 1
    })
    Draven.Q.GetDamage = function(spellInstance, enemy, stage)
        local bonusAD = player.flatPhysicalDamageMod * player.percentPhysicalDamageMod
        local qLvl = player:spellSlot(0).level        
        local spellDmg = 30 + 5*qLvl + (0.55 + 0.1* qLvl) * bonusAD
        return spellDmg + player.baseAttackDamage + bonusAD              
    end
    Draven.R.GetDamage = function(spellInstance, enemy, stage)
        if not spellInstance:IsReady() then return 0 end
        --
        local rLvl = player:spellSlot(3).level
        return (75 + 100*rLvl + 1.1 * player.flatPhysicalDamageMod * player.percentPhysicalDamageMod)           
    end
end

function Draven.LoadMenu()
    --Menu initialization
    Draven.Menu = menu("BoringDraven", "Boring Draven")
    Draven.Menu:header(" ", "Witch King's Draven")
    --Q--
    Draven.Menu:menu   ("Q", "Q Settings")
    Draven.Menu.Q:header  ("          ", "Combo Settings")
    Draven.Menu.Q:boolean ("Combo"     , "Use on Combo"      , true)
    Draven.Menu.Q:slider  ("Mana"      , "Min Mana %"        , 15, 0, 100, 1)
    Draven.Menu.Q:header  ("          ", "Harass Settings")
    Draven.Menu.Q:boolean ("Harass"    , "Use on Harass"     , true)
    Draven.Menu.Q:slider  ("ManaHarass", "Min Mana %"        , 15, 0, 100, 1)
    Draven.Menu.Q:header  ("          ", "Farm Settings")
    Draven.Menu.Q:boolean ("LastHit"   , "Use on LastHit"    , false)
    Draven.Menu.Q:boolean ("Jungle"    , "Use on JungleClear", false)
    Draven.Menu.Q:boolean ("Clear"     , "Use on LaneClear"  , false)
    Draven.Menu.Q:slider  ("ManaClear" , "Min Mana %"        , 15, 0, 100, 1)
    Draven.Menu.Q:header  ("          ", "Misc")
    Draven.Menu.Q:boolean ("Catch"     , "Auto Catch Axes"   , true)
    Draven.Menu.Q:slider  ("Max"       , "Max Axes To Have"  , 2 , 1, 3  , 1)          
    --W--
    Draven.Menu:menu   ("W", "W Settings")
    Draven.Menu.W:header  ("          ", "Combo Settings")
    Draven.Menu.W:boolean ("Combo"     , "Use on Combo"        , true)
    Draven.Menu.W:slider  ("Mana"      , "Min Mana %"          , 15, 0, 100, 1)
    Draven.Menu.W:header  ("          ", "Harass Settings")
    Draven.Menu.W:boolean ("Harass"    , "Use on Harass"       , true)
    Draven.Menu.W:slider  ("ManaHarass", "Min Mana %"          , 15, 0, 100, 1)
    Draven.Menu.W:header  ("          ", "Misc")
    Draven.Menu.W:boolean ("Catch"     , "Use to Catch Axes"   , true)   
    --E--
    Draven.Menu:menu   ("E", "E Settings")
    Draven.Menu.E:header  ("          ", "Combo Settings")
    Draven.Menu.E:boolean ("Combo"     , "Use on Combo"            , true)
    Draven.Menu.E:slider  ("Mana"      , "Min Mana %"              , 15, 0, 100, 1)
    Draven.Menu.E:header  ("          ", "Harass Settings")
    Draven.Menu.E:boolean ("Harass"    , "Use on Harass"           , false)
    Draven.Menu.E:slider  ("ManaHarass", "Min Mana %"              , 15, 0, 100, 1)
    Draven.Menu.E:header  ("          ", "Misc")
    Draven.Menu.E:boolean ("Gapcloser" , "Auto Use on Gapcloser"   , true)
    Draven.Menu.E:menu    ("Interrupt" , "Interrupt Targets")
    Draven.Menu.E.Interrupt:boolean ("Enabled" , "Enabled", true)
    Interrupter.load_to_menu(Draven.Menu.E.Interrupt)             
    --R--
    Draven.Menu:menu   ("R", "R Settings")                         
    Draven.Menu.R:menu    ("Heroes"    , "Duel Settings")
    Draven.Menu.R.Heroes:boolean("Combo"   , "Enabled"            ,   true)
    Draven.Menu.R:slider  ("Count"     , "Auto Use When X Enemies", 2, 0, 5, 1)
    Draven.Menu.R:boolean ("KS"        , "Use on KS"              , true)
    Draven.Menu.R:slider  ("Mana"      , "Min Mana %"             , 0, 0, 100, 1)
    Draven.Menu:header    ("_VERSION"  , "Release_"..Draven.scriptVersion)
    --
    Draven.Menu:menu   ("Draw", "Draw Settings") 
    Draven.Menu.Draw:boolean ("ON"     , "Drawings ON"            , true) 
    Draven.Menu.Draw:boolean ("Q"     , "Draw Q"            , true)
    Draven.Menu.Draw:boolean ("W"     , "Draw W"            , true)
    Draven.Menu.Draw:boolean ("E"     , "Draw E"            , true)
    Draven.Menu.Draw:boolean ("R"     , "Draw R"            , true)
    Draven.Menu.Draw:boolean ("TS"     , "Draw TS"            , true)
    Draven.Menu.Draw:boolean ("Dmg"     , "Draw Dmg"            , true)

    --
    for i=0, objManager.enemies_n -1 do
        local unit = objManager.enemies[i]
        if unit then
            Draven.Menu.R.Heroes:boolean(unit.charName, unit.charName, true)
        end
    end
end

local bool = false
function Draven.OnTick()            
    Draven.enemies = Common.GetEnemyHeroes(1500)
    Draven.target  = Common.GetTarget(Common.GetTrueAttackRange(player), 0)
    Draven.mode    = (orb.menu.combat:get() and 1) or (orb.menu.hybrid:get() and 2) or (orb.menu.lane_clear:get() and 3) or (orb.menu.last_hit:get() and 4)       
    --               
    Draven.Auto()
    Draven.KillSteal()
    --
    if not (Draven.mode and Draven.enemies) then return end        
    local executeMode = 
        Draven.mode == 1 and Draven.Combo()   or 
        Draven.mode == 2 and Draven.Harass()          
end

local modeChecks = {
    function(t) return Common.ManaPercent(player) >= Draven.Menu.Q.Mana:get()       and Draven.Menu.Q.Combo:get()   end,
    function(t) return Common.ManaPercent(player) >= Draven.Menu.Q.ManaHarass:get() and Draven.Menu.Q.Harass:get()  end,
    function(t) return Common.ManaPercent(player) >= Draven.Menu.Q.ManaClear:get()  and ((Draven.Menu.Q.Clear:get() and t.team ~= 300) or (Draven.Menu.Q.Jungle:get() and t.team == 300))  end,
    function(t) return Common.ManaPercent(player) >= Draven.Menu.Q.ManaClear:get()  and Draven.Menu.Q.LastHit:get() end
}
function Draven.OnIssueOrder(order, vec, obj)
    local moveTo, bestAxe 
    if Draven.Menu.Q.Catch:get() then
        bestAxe = Draven.GetBestAxe()
        moveTo = bestAxe and bestAxe.pos
    end
    if order == 3 then --attack
        if moveTo then
            local windUp = player:basicAttack(0).windUpTime
            local distToAxe = player.pos:dist(moveTo)            
            local deltaT = (distToAxe / player.moveSpeed) + windUp - (bestAxe.endTime - game.time)
            if distToAxe > 30 and deltaT > 0 then                
                if deltaT < windUp then
                    if Draven.Menu.W.Catch:get() and Draven.W:IsReady() and not Common.HasBuff(player, "DravenFury") then
                        Draven.W:Cast()
                    end
                elseif deltaT < windUp * 1.5 then
                    core.block_input()                                    
                end
            end
        elseif Draven.GetAxeCount() < Draven.Menu.Q.Max:get() and Draven.Q:IsReady() and obj > 0 then
            local obj = objManager.toluaclass(obj) 
            if Draven.mode and modeChecks[Draven.mode](obj) then
                Draven.Q:Cast()
            end    
        end 
    elseif order == 2 then --move
        if moveTo then
            if player.pos:dist(moveTo) < 20 then 
                core.block_input() 
            else
                local posTo = moveTo
                vec.x = posTo.x
                vec.y = posTo.y
                vec.z = posTo.z
            end 
        end        
    end    
end

function Draven.OnInterruptable(unit, spell)             
    if Draven.Menu.E.Interrupt[spell.name]:get() and Common.IsValidTarget(unit, Draven.E.range) and Draven.E:IsReady() then
        Draven.E:Cast(unit.pos)
    end        
end   

function Draven.OnDash(unit)
    if not (Draven.Menu.E.Gapcloser:get() and Draven.E:IsReady()) then return end
    if Common.IsValidTarget(unit) and player.pos:dist(unit.pos) < Draven.E.range and unit.team == TEAM_ENEMY then
        local isGapclosingOnMe = Common.IsFacing(unit, player)
        if isGapclosingOnMe or Utils.isFleeingFromMe(unit) then
            Draven.E:CastToPred(unit, 2)
        end                    
    end
end 

function Draven.Auto()
    if Draven.Menu.R.Count:get() ~= 0 and Draven.R:IsReady() then
        local bestPos, hit = Draven.R:GetBestLinearCastPos(Draven.enemies)            
        if bestPos and hit >= Draven.Menu.R.Count:get() then
            Draven.R:Cast(bestPos)
        end
    end                       
end

function Draven.Combo()
    local eTarget = Common.GetTarget(Draven.E.range, 0)
    if not eTarget then return end
    local runningAway = (Common.IsFacing(player, eTarget) and not Common.IsFacing(eTarget, player) and player.pos:dist(eTarget) > Common.GetTrueAttackRange(player))
    if Draven.W:IsReady() and Draven.Menu.W.Combo:get() and Common.ManaPercent(player) >= Draven.Menu.W.Mana:get() and not Common.HasBuff(player, "DravenFury") then  
        if eTarget and (eTarget.moveSpeed > player.moveSpeed or runningAway) then
            Draven.W:Cast()
        end
    end        
    if Draven.E:IsReady() and Draven.Menu.E.Combo:get() and Common.ManaPercent(player) >= Draven.Menu.E.Mana:get() then
        local eTarget = Common.GetTarget(Draven.E.range, 0)
        if Common.IsValidTarget(eTarget) and (Common.HealthPercent(player) <= 40 or runningAway) then
            Draven.E:CastToPred(eTarget, 2)
        end
    end
    if Draven.R:IsReady() and Draven.Menu.R.Heroes.Combo:get() and Common.ManaPercent(player) >= Draven.Menu.R.Mana:get() then
        local rTarget = Common.GetTarget(1500, 0)
        if Common.IsValidTarget(rTarget) and Draven.Menu.R.Heroes[rTarget.charName]:get() and rTarget.health >= 200 and (Draven.R:GetDamage(rTarget) * 2 > orb.farm.predict_hp(rTarget, player.pos:dist(rTarget)/Draven.R.speed) or Common.HealthPercent(player) <= 40 ) then
            if Draven.R:CastToPred(enemy, 2) then
                Draven.CallUltBack(enemy)                    
            end
        end
    end                
end

function Draven.Harass()
    if Draven.E:IsReady() and Draven.Menu.E.Harass:get() and Common.ManaPercent(player) >= Draven.Menu.E.ManaHarass:get() then
        local eTarget = Common.GetTarget(Draven.E.range, 0)            
        if Common.IsValidTarget(eTarget) and (Common.HealthPercent(player) <= 40 or (Common.IsFacing(player, eTarget) and not Common.IsFacing(eTarget, player) and player.pos:dist(eTarget) > Common.GetTrueAttackRange(player))) then
            Draven.E:CastToPred(eTarget, 2)
        end
    end      
end

function Draven.KillSteal()        
    if Draven.Menu.R.KS:get() and Draven.R:IsReady() then
        for i=1, #(Draven.enemies) do
            local enemy = Draven.enemies[i]
            local hp = enemy.health + enemy.physicalShield                                            
            if Draven.R:GetDamage(enemy) * 2 >= hp and (hp >= 100 or HeroesAround(600, enemy.pos, TEAM_ALLY) == 0) then
                if Draven.R:CastToPred(enemy, 2) then
                    Draven.CallUltBack(enemy)
                    break
                end
            end
        end
    end
end

function Draven.OnDraw()
    Common.DrawSpells(Draven) 
end

function Draven.GetBestAxe()
    local closest, dist = nil, 1000    
    for ptr, data in pairs(Draven.AxeList) do
        local dist2 = player.pos:dist(data.pos)
        if dist2 < dist then
            closest = data
            dist    = dist2
        end
    end  
    return closest     
end 

function Draven.OnCreateObj(obj)
    if player.pos:dist(obj.pos) > 1000 then return end
    if obj.name:find("reticle_self") then        
        Draven.AxeList[obj.ptr] = {endTime = game.time + 1.1, pos = obj.pos}
        Draven.AxeCount = Draven.AxeCount + 1        
    end 
end

function Draven.OnDeleteObj(obj)
    if Draven.AxeList[obj.ptr] then
        Draven.AxeList[obj.ptr] = nil
        Draven.AxeCount = Draven.AxeCount - 1  
    end 
end 

local abs = math.abs
function Draven.CallUltBack(enemy)
    Utils.setDelayAction(function()
        Draven.R:Cast()                        
    end, abs(player.pos:dist(enemy.pos) - 500) / 2000)
end

function Draven.GetAxeCount()
    local axesOnHand = Common.HasBuff(player, "DravenSpinningAttack") 
    return Draven.AxeCount + (axesOnHand and axesOnHand.stacks or 0)
end



Draven.__init()



