--[=[
    Interrupter            
        .load_to_menu(menu)
            Creates a switch for every interruptable spell in the current game
            with var = spell.name
            Input:
                - menu to add options 

        How-To:
            local interrupter = module.load("MediocreLib", "interrupter")
            local myClass = {}
            local Menu = menu("sample_script_101", "My Test Script")
            --
            function myClass.LoadMenu()
                Menu:boolean ("Enabled"   , "Enable Interrupter", true)
                Menu:menu    ("WhiteList" , "Interrupt Targets")
                interrupter.load_to_menu(Menu.WhiteList)                    
            end
            --
            function myClass.Interrupt(owner, spell) --you can return true to skip following callbacks
                local whitelist = Menu.WhiteList[spell]
                if Menu.Enabled:get() and whitelist and whitelist:get() then
                    print(owner.." is casting "..spell.name.." and can be interrupted!")
                else
                    print(owner.." is casting "..spell.name.." but shouldn't be interrupted!")
                end                
            end
            --
            interrupter(myClass.Interrupt)   -- call once  : callback added
            --interrupter(myClass.Interrupt) -- call again : callback removed              
]=]

local Interrupter = {
    callbacks = {}
}

function Interrupter.load_to_menu(menu)
    if not menu then error("menu cant be nil", 2) end
    --
    if Interrupter.load then
        Interrupter.load()
    end
    --
    local NoSpellsFound = true    
    for i=0, objManager.enemies_n -1 do
        local unit = objManager.enemies[i]
        if unit and Interrupter.spells[unit.charName] then
            NoSpellsFound = false
            for spell, display in pairs(Interrupter.spells[unit.charName]) do
                menu:boolean(spell, unit.charName .. display, true)
            end
        end
    end
    --
    if NoSpellsFound then 
        menu:header("NoSpellsFound", "No Spells To Be Interrupted")
    end
end

function Interrupter.cb_spell(spell)
    local charName = spell.owner.charName
    --
    if Interrupter.spells[charName] and Interrupter.spells[charName][spell.name] then
        for _, Emit in pairs(Interrupter.callbacks) do
            if Emit(spell.owner, spell) then return end
        end
    end
end

function Interrupter.load()    
    Interrupter.spells = {
        Caitlyn = {
            CaitlynAceintheHole = " | R | Ace in the Hole",
        },
        FiddleSticks = {
            Crowstorm = " | R | Crowstorm", Drain = " | W | Drain",
        },
        Janna = {
            ReapTheWhirlwind = " | R | Monsoon",
        },
        Karthus = {
            KarthusFallenOne = " | R | Requiem",
        },
        Katarina = {
            KatarinaR = " | R | Death Lotus",
        },
        Lucian = {
            LucianR = " | R | The Culling",
        },
        Malzahar = {
            MalzaharR = " | R | Nether Grasp",
        },
        MasterYi = {
            Meditate= " | W | Meditate",
        },
        MissFortune = {
            MissFortuneBulletTime = " | R | Bullet Time",
        },
        Nunu = {
            NunuR   = " | R | Absoulte Zero" ,
        },
        Pantheon = {
            PantheonRJump = " | R | Jump", PantheonRFall = " | R | Fall",
        },
        Shen = {
            ShenR = " | R | Stand United",
        },
        TwistedFate = {
            Gate = " | R | Destiny", 
        },
        Varus = {
            VarusQ = " | Q | Piercing Arrow",
        },
        Velkoz = {
            VelkozR = " | R | Desintegration Ray",
        },
        Warwick = {
            WarwickR = " | R | Infinite Duress",
        },
        Xerath = {
            XerathLocusOfPower2 = " | R | Rite of the Arcane",
        },    
    }    
    cb.add(cb.spell, Interrupter.cb_spell) 
    Interrupter.load = nil       
end

return setmetatable({load_to_menu = Interrupter.load_to_menu}, {
    __call = function(_, func)
        if Interrupter.load then
            Interrupter.load()
        end
        local addr = tostring(func)
        local cb = Interrupter.callbacks
        cb[addr] = not cb[addr] and func or nil        
    end
})
