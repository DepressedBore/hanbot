return {
	id = "BoringDraven",
	name = "Boring Draven",
	load = function()
		return player.charName == 'Draven'
	end,
	flag = {
		text = "Bore",
			color = {
			text = 0xFF00fa21,
			background1 = 0xFF000000,
			background2 = 0xFF434743
		}
    },
    riot = true
}