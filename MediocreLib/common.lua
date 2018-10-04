local ts = module.internal("TS")

local Common = {}

local _CHARM = 22;local _SUPRESS = 24;local _KNOCKUP = 29;local _KNOCKBACK = 30 
function Common.IsImmobile(unit, delay) 
    if unit.ms == 0 then return true end
    --
    local debuff, timeCheck = {} , game.time + (delay or 0)
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and timeCheck <= buff.endTime then
            debuff[buff.type] = true
        end
    end
    --[[STUN         TAUNT        SNARE         SLEEP         SUPRESSION    AIRBORNE]]   
    if  debuff[5] or debuff[8] or debuff[11] or debuff[18] or debuff[24] or debuff[29] then            
        return true
    end            
end

function Common.IsImmortal(obj)
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and buff.type == 17 then
            return true
        end
    end
end

function Common.IsValidTarget(obj, range)
    return obj and not obj.isDead and obj.isVisible and obj.isTargetable and not Common.IsImmortal(obj) and (not range or player.pos:dist(obj.pos) <= range)
end

function Common.HasBuff(obj, buffname)
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and buff.name == buffname and game.time <= buff.endTime then
            return buff            
        end        
    end
    return false     
end

function Common.HealthPercent(unit)
    return unit.maxHealth > 5 and unit.health/unit.maxHealth * 100 or 100
end

function Common.ManaPercent(unit)
    return unit.maxMana > 0 and unit.mana/unit.maxMana * 100 or 100
end

function Common.GetTrueAttackRange(source, target)
    return source.attackRange + source.boundingRadius + (target and target.boundingRadius or 0)
end

function Common.GetEnemyHeroes(range) 
    local t = {}
    for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        if player.pos:dist(enemy.pos) < range and Common.IsValidTarget(enemy) then
            t[#t + 1] = enemy
        end
    end
    return t
end

local range_check = 0
local function select_target(res, obj, dist)
    if dist > range_check then return end    
    res.obj = obj
    return true
end

function Common.GetTarget(range, dmgType)
    range_check = range
    return ts.get_result(select_target).obj    
end

local pi, cos, sin, huge = math.pi, math.cos, math.sin, math.huge
local function RotateAroundPoint(v1,v2, angle)
    local cos, sin = cos(angle), sin(angle)
    local x = ((v1.x - v2.x) * cos) - ((v1.z - v2.z) * sin) + v2.x
    local z = ((v1.z - v2.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return vec3(x, v1.y, z or 0)
end

local clock = os.clock
local DrawLine, w2s = graphics.draw_line_2D, graphics.world_to_screen
local COLOR_RED = graphics.argb(255,255,0,0) 
function Common.DrawMark(pos, size, color)
    local hPos, size = pos or player.pos, size*2 or 150
    local offset, rotateAngle, mod = hPos + vec3(0, 0, size), (clock()%360)*pi/3.6, 2/3*pi    
    local points = {
        w2s(hPos),
        w2s(RotateAroundPoint(offset, hPos, rotateAngle)) ,  
        w2s(RotateAroundPoint(offset, hPos, rotateAngle+mod)) ,
        w2s(RotateAroundPoint(offset, hPos, rotateAngle+2*mod))
    }        
    --
    for i=1, #points do
        for j=1, #points do
            local lambda = i~=j and DrawLine(points[i].x, points[i].y, points[j].x, points[j].y, 3, color or COLOR_RED)
        end
    end
end

local max = math.max
local DmgColor = graphics.argb(255,235,103,25)
function Common.DrawDmg(hero, damage)
    if hero.isOnScreen then 
        local barPos = hero.barPos                   
        local percentHealthAfterDamage = max(0, hero.health - damage) / hero.maxHealth
        DrawLine(barPos.x + 165 + 103 * hero.health/hero.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11, DmgColor)        
    end      
end

local deg, acos, abs = math.deg, math.acos, math.abs
function Common.IsFacing(unit, p2) --checks if unit is facing p2
    if not unit or not p2 then return end
    local facingPos = p2.type == vec3.type and p2 or p2.pos     
    local Angle = mathf.angle_between(unit.pos, facingPos, unit.pos + unit.direction*100) * 180/pi
    --[=[If anyone needs help visualizing]=]
    --local unitPos, facingPos, dirPos = w2s(unit.pos), w2s(facingPos), w2s(unit.pos + unit.direction*200)
    --DrawLine(unitPos.x, unitPos.y, facingPos.x, facingPos.y, 3, COLOR_RED)
    --DrawLine(unitPos.x, unitPos.y, dirPos.x, dirPos.y, 3, COLOR_RED)    
    if abs(Angle) < 40 then 
        return true  
    end        
end

local t_spells = {"Q", "W", "E", "R", "Q2", "W2", "E2", "R2"}
function Common.GetTotalDamage(instance, enemy)
    local totalDmg = 0
    for i=1, 8 do
        local spell = instance[t_spells[i]]
        if spell and spell.CalcDamage then 
            totalDmg = totalDmg + spell:CalcDamage(enemy)  
        end
    end
    return totalDmg
end

function Common.DrawSpells(instance, extrafn)
    local drawSettings = instance.Menu.Draw
    if drawSettings.ON:get() then            
        local qLambda = drawSettings.Q:get() and instance.Q and instance.Q:Draw(66, 244, 113)
        local wLambda = drawSettings.W:get() and instance.W and instance.W:Draw(66, 229, 244)
        local eLambda = drawSettings.E:get() and instance.E and instance.E:Draw(244, 238, 66)
        local rLambda = drawSettings.R:get() and instance.R and instance.R:Draw(244, 66, 104)
        local tLambda = drawSettings.TS:get() and instance.target and Common.DrawMark(instance.target.pos, instance.target.boundingRadius, COLOR_RED)
        --
        if instance.enemies and drawSettings.Dmg:get() then
            for i=1, #instance.enemies do
                local enemy = instance.enemies[i]
                Common.DrawDmg(enemy, Common.GetTotalDamage(instance, enemy))
                --
                if extrafn then
                    extrafn(enemy)
                end
            end 
        end 
    end
end

return Common