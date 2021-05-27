if SERVER then
	include("universal_ammo/shared.lua")
	include("universal_ammo/init.lua")
	include("universal_ammo/darkrp.lua")
	AddCSLuaFile("universal_ammo/config_menu.lua")
	AddCSLuaFile("universal_ammo/shared.lua")
	AddCSLuaFile("universal_ammo/darkrp.lua")
else
	include("universal_ammo/shared.lua")
	include("universal_ammo/config_menu.lua")
	include("universal_ammo/darkrp.lua")

	// Credits to the creators of DarkRP - nice font fix :D
	local function fontFix()
		surface.CreateFont("HUDNumber5", {
			size = 30,
			weight = 800,
		 	antialias = true,
			shadow = false,
		 	font = "Default"
		})

		hook.Add("InitPostEntity", "UniversalAmmoLoadFontFix", fontFix)
	end
	fontFix()
end