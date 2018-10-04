--[=[
    DashManager
        .set_gapcloser(bool)
            Enable/Disable the unit being gapclosed check. [default = off]

        How-To:
            local OnDash = module.load("MediocreLib", "dash")
            local myClass = {}
            --
            OnDash.set_gapcloser(true) --if you comment out this line "gapclosed" will always be an empty table
            function myClass.OnDash(obj, gapclosed)
                for i=1, #gapclosed do
                    local unit = gapclosed[i]
                    if unit.team == TEAM_ALLY then
                        print("Enemy "..obj.charName.." is gapclosing on ally  "..unit.charName.."! Shield Him Now!")
                    else
                        print("Ally " ..obj.charName.." is gapclosing on enemy "..unit.charName.."! Prepare to Engage!")
                    end
                end                
            end
            --
            OnDash(myClass.OnDash)   -- call once  : callback added
            --OnDash(myClass.OnDash) -- call again : callback removed 
               
]=]

local pred
local DashManager = {
    callbacks = {},
    gapcloser_check = false
}

function DashManager.set_gapcloser(bool)    
    DashManager.gapcloser_check = bool
end

function DashManager.check_gapcloser(obj)    
    local predPos = pred.core.lerp(obj.path, network.latency + .25, obj.moveSpeed)
          predPos = vec3(pred_pos.x, obj.y, pred_pos.y)
    --
    local enemyT   = obj.team == TEAM_ALLY and objManager.enemies or objManager.allies
    local result = {}
    --
    for i = 0, #enemyT - 1 do
        local unit = enemyT[i]
        if predPos:dist(unit.pos) < 900 and predPos:dist(unit.pos) < obj.pos:dist(unit.pos) then
            result[#result+1] = unit
        end
    end
    --
    return result
end

function DashManager.cb_path(obj)
    if obj.path.isDashing then
        local gapclosed = DashManager.gapcloser_check and DashManager.check_gapcloser(obj) or {}
        for _, Emit in pairs(DashManager.callbacks) do
            Emit(obj, gapclosed)
        end                       
    end
end

function DashManager.load()
    pred = module.internal("pred") 
    cb.add(cb.path, DashManager.cb_path) 
    DashManager.load = nil       
end

return setmetatable({set_gapcloser = DashManager.set_gapcloser}, {
    __call = function(_, func)
        if DashManager.load then
            DashManager.load() 
        end
        local addr = tostring(func)
        local cb = DashManager.callbacks
        cb[addr] = not cb[addr] and func or nil        
    end
})