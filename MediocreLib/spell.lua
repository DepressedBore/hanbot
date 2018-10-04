local pi, cos, sin, huge = math.pi, math.cos, math.sin, math.huge
local pred = module.internal("pred")
local utils = module.load("DivineLib", "util")

local COLOR_RED = graphics.argb(255,255,0,0)   

local Spell = setmetatable({}, {
    __index = Spell,
    __call = function(c, sD)
        local t = {
            slot               = sD.slot,
            range              = sD.range             or huge,
            delay              = sD.delay             or 0.25,
            speed              = sD.speed             or huge,
            radius             = sD.radius            or 0,
            width              = sD.width             or 0,
            from               = sD.from              or player,
            collision          = sD.collision         or {hero = false, minion = false},
            type               = sD.type              or "Press", 
            dmgType            = sD.dmgType           or "Physical",
            boundingRadiusMod  = sD.boundingRadiusMod or 1,
        }                
        setmetatable(t, c)
        c.__index = c
        return t
    end
})

function Spell:IsReady()
    return self.from:spellSlot(self.slot).state == 0
end

function Spell:GetPrediction(target)
    local result, castPos, hC
    if self.type == "Linear" then
        result = pred.linear.get_prediction(self, target, self.from)
    elseif self.type == "Circular" then
        result = pred.circular.get_prediction(self, target, self.from)
    else
        result = pred.core.lerp(target.path, network.latency + .25, target.moveSpeed)
    end
    --
    if result then
        castPos = vec3(result.endPos.x, target.y, result.endPos.y)
        hC = 2
        --[[Range Check]]
        if result.startPos:dist(result.endPos) > self.range then
            hC = 0
        end
        --[[Collision Check]]
        if self.collision and pred.collision.get_prediction(self, result, target) then
            hc = 0
        end
        --[[Angle Check]]        
        local temp_angle = mathf.angle_between(result.endPos, self.from.pos:to2D(), target.pos:to2D())
        if temp_angle < 30 or temp_angle > 150 then
            hC = hC + 1
        else
            hC = hC / 2
        end
    end
    return result, castPos, hC      
end

function Spell:CalcDamage(target)
    local rawDmg = self:GetDamage(target, stage)
    if rawDmg <= 0 then return 0 end        
    --
    local damage = 0        
    if self.dmgType == 'Magical' then
        damage = utils.calculateMagicalDamage(target, self.from, rawDmg)                      
    elseif self.dmgType == 'Physical' then
        damage = utils.calculatePhysicalDamage(target, self.from, rawDmg)        
    elseif self.dmgType == 'Mixed' then
        damage = utils.calculateMagicalDamage(target, self.from, rawDmg*.5) + utils.calculatePhysicalDamage(target, self.from, rawDmg*.5)
    elseif self.dmgType == 'True' then
        damage = rawDmg
    end    

    return damage
end

--[[Scripts are supposed to override this one]]
function Spell:GetDamage(target, stage)
    return 0
end

function Spell:Cast(castOn, castOn2)
    if not self:IsReady() then return end         
    --       
    if self.type == "Press" or not castOn then
        return player:castSpell("self", self.slot)
    end
    --
    local isObj = not (castOn.type == vec3.type or castOn.type == vec2.type)  
    if castOn2 and not isObj then
        player:castSpell("line", self.slot, castOn, castOn2)
    end                        
    return player:castSpell((isObj and "obj") or "pos", self.slot, castOn)
end

function Spell:CastToPred(target, minHitchance)
    if not target then return end
    --
    local result, predPos, hC = self:GetPrediction(target)        
    if predPos and hC >= minHitchance then                         
        return self:Cast(predPos)            
    end
end

local remove = table.remove
local getPredictedPos = utils.getPredictedPos
function Spell:GetBestCircularCastPos(lst)
    if not lst then error("expected table, got nil", 2) end
    local range, radius, speed, from, delay = self.range or 2000, self.radius or 50, self.speed or 1200, self.from.pos or player.pos, self.delay or 0
    local inRange, len = 0, #lst
    --
    repeat        
        local avg = {x = 0, z = 0, count = 0} 
        --[[Gets Avg Center]]
        for i = 1, len do
            local unit = lst[i]
            local org = getPredictedPos(unit, delay + unit.pos:dist(from)/speed)
            avg.x = avg.x + org.x/len 
            avg.z = avg.z + org.z/len                              
        end
        --[[Check how many targets are inside MEC and identifies furthest]]
        avg = vec3(avg.x, player.y, avg.z)
        local furthest, maxDist = nil, 0
        for i = 1, len do
            local unit = lst[i]
            local dist = avg:dist(unit.pos) - unit.boundingRadius
            if dist < radius then 
                inRange = inRange + 1
            elseif dist > maxDist then 
                furthest = i
                maxDist  = dist 
            end                
        end
        --[[Check if every target is in range or removes furthest and tries again]]
        if inRange >= #lst then
            return avg, inRange
        else
            remove(lst, furthest)
            inRange = 0;len = len-1            
        end
    until (len == 1)
    return getPredictedPos(lst[1], delay + lst[1].pos:dist(from)/speed), 1
end 

local dist2 = mathf.dist_line_vector --(vec2, line_point_1, line_point_2)
function Spell:GetBestLinearCastPos(lst)
    if not lst then error("expected table, got nil", 2) end
    local range, width, speed, from, delay = self.range or 2000, self.width or 50, self.speed or 1200, self.from.pos or player.pos, self.delay or 0
    local inRange, len = 0, #lst
    --
    repeat        
        local avg = {x = 0, z = 0, count = 0} 
        --[[Gets Avg Center]]
        for i = 1, len do
            local unit = lst[i]
            local org = getPredictedPos(unit, delay + unit.pos:dist(from)/speed)
            avg.x = avg.x + org.x/len 
            avg.z = avg.z + org.z/len                              
        end
        --[[Check how many targets are being hit and identifies furthest]]
        avg = vec3(avg.x, player.y, avg.z)
        local furthest, maxDist = nil, 0
        for i = 1, len do
            local unit = lst[i]
            local dist = dist2(unit.pos, avg, from) - unit.boundingRadius
            if dist < width then 
                inRange = inRange + 1
            elseif dist > maxDist then 
                furthest = i
                maxDist  = dist 
            end                
        end
        --[[Check if every target is in range or removes furthest and tries again]]
        if inRange >= #lst then
            return avg, inRange
        else
            remove(lst, furthest)
            inRange = 0;len = len-1            
        end
    until (len == 1)
    return getPredictedPos(lst[1], delay + lst[1].pos:dist(from)/speed), 1
end

local DrawCircle = graphics.draw_circle
function Spell:Draw(r, g, b)
    if not self.DrawColor then 
        self.DrawColor  = graphics.argb(255, r, g, b)
        self.DrawColor2 = graphics.argb(80 , r, g, b)
    end
    local range = self.range + self.radius
    if range and range ~= huge then
        DrawCircle(self.from.pos, range, 5, self:IsReady() and self.DrawColor or self.DrawColor2, 100)        
        return true
    end
end  

local DrawMap    = graphics.draw_circle_2D
function Spell:DrawMap(r, g, b)
    if not self.DrawColor then 
        self.DrawColor  = graphics.argb(255, r, g, b)
        self.DrawColor2 = graphics.argb(80 , r, g, b)
    end
    if self.range and self.range ~= huge then
        local pos = graphics.world_to_screen(self.from.pos)
        DrawMap(pos.x, pos.y, self.range, 5, self:IsReady() and self.DrawColor or self.DrawColor2, 100)        
        return true
    end        
end

return Spell