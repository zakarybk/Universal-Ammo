// Credits to the creators of DarkRP - nice font fix :D

local function loadFonts()
	surface.CreateFont("HUDNumber5", {
		size = 30,
		weight = 800,
	 	antialias = true,
		shadow = false,
	 	font = "Default"})
end
loadFonts()

hook.Add("InitPostEntity", "UniversalAmmoLoadFontFix", loadFonts) 