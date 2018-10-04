local mLib;

mLib = {
    _NAME        = "MediocreLib",
    _TYPE        = "lib",
    _URL         = "https://raw.githubusercontent.com/DepressedBore/hanbot/master/MediocreLib/",
    _DESCRIPTION = "Mediocre huh..I wonder why"
}

module.load("DivineLib", "net").update(mLib._NAME, mLib._TYPE, mLib._URL)

setmetatable(mLib, {
    __index = function(_, b)
        return module.load("MediocreLib", b)
    end
})

return mLib