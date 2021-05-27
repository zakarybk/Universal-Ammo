util.AddNetworkString("UniversalAmmo_SetAmmoCount")

-- util.AddNetworkString("UniversalAmmo_SetPrimaryAmmoForSWEP")
-- util.AddNetworkString("UniversalAmmo_SetSecondaryAmmoForSWEP")

util.AddNetworkString("UniversalAmmo_OnConfigChanged")
util.AddNetworkString("UniversalAmmo_DownloadConfig")

util.AddNetworkString("UniversalAmmo_ResetToDefaults")

local hasLoadedConfig = false
local config = {
	['ammo'] = {},
	-- ['swep.primary'] = {},
	-- ['swep.secondary'] = {},
	['darkrp'] = {}
}
UniversalAmmo.Config = function() return config end

local DIRECTORY = 'universal_ammo'
local FILE = 'config.txt'
local MAX_DOWNLOAD_REQUESTS = 5

UniversalAmmo.IsConfigLocked = function() return file.Exists(DIRECTORY .. '/lock.txt', 'DATA') end

local function configFilePath()
	return DIRECTORY .. '/' .. FILE
end

local function saveConfig()
	if not file.Exists(DIRECTORY, 'DATA') then
		file.CreateDir(DIRECTORY)
	end

	PrintTable(config)

	file.Write(
		configFilePath(),
		util.TableToJSON(config, true)
	)
end

local function loadConfig()
	-- Game needs to load all sweps first

	-- set default values for ammo
	config['ammo'] = UniversalAmmo.GuessGoodAmmoCount()
	if table.Count(config['ammo']) == 0 then
		timer.Simple(1, function() loadConfig() end) -- try again...
		return
	end

	-- set default values for darkrp -- required -- TODO: move out into darkrp.lua
	config['darkrp'] = {
		['universal_ammo'] = {
			enabled=false,
			price=70,
			printName="Universal Ammo"
		},
		['universal_ammo_infinite'] = {
			enabled=false,
			price=5000,
			printName="Universal Infinite Ammo"
		},
		['universal_ammo_secondary'] = {
			enabled=false,
			price=70,
			printName="Universal Secondary Ammo"
		},
	}

	-- Make sure file exists and contains a valid table
	if file.Exists(configFilePath(), 'DATA') then
		local readData = util.JSONToTable(file.Read(configFilePath(), 'DATA'))
		if readData and istable(readData) then
			-- Allow default values above to be set
			-- Means when new ammo is added, we have
			-- a default value
			table.Merge(
				config,
				readData
			)
		end
	end

	hasLoadedConfig = true
	net.Start("UniversalAmmo_DownloadConfig")
		net.WriteTable(config)
	net.Send(player.GetAll())

end
hook.Add("InitPostEntity", "UniversalAmmo_LoadConfig", loadConfig)

-- Where configName = key in config{},
-- Where className = ammo class or swep class
-- Where value = bullet count or ammo class
hook.Add("UniversalAmmo_OnConfigChanged", "UpdateClients",
	function(configName, className, value)

	-- Allow for more complex data such as that in darkrp.lua
	if istable(value) then
		value = util.TableToJSON(value)
	end

	if isnumber(value) then
		value = tostring(value)
	end

	net.Start("UniversalAmmo_OnConfigChanged")
		net.WriteString(configName)
		net.WriteString(className)
		net.WriteString(value)
	net.Send(player.GetAll())
end)

local function updateConfigRow(configName, className, value)
	config[configName][className] = value
	saveConfig()
	hook.Run('UniversalAmmo_OnConfigChanged',
		configName,
		className,
		value
	)
end
UniversalAmmo.UpdateConfigRow = updateConfigRow

local function setBulletCountForAmmo(bulletCount, ammoClass)
	if UniversalAmmo.IsValidAmmoClass(ammoClass) and isnumber(bulletCount) then
		updateConfigRow('ammo', ammoClass, math.Round(math.abs(bulletCount)))
	end
end

net.Receive("UniversalAmmo_SetAmmoCount", function(len, ply)
	if not hasLoadedConfig then return end

	if UniversalAmmo.CanEditConfig(ply) and not UniversalAmmo.IsConfigLocked() then
		local ammoClass = net.ReadString()
		local bulletCount = tonumber(net.ReadString())

		setBulletCountForAmmo(tonumber(bulletCount), ammoClass)
	else
		ply:ChatPrint("Universal Ammo: Permission denied")
	end
end)

-- Make sure the player is always able to download the ammo even with connection drops
net.Receive("UniversalAmmo_DownloadConfig", function(len, ply)
	if not hasLoadedConfig then return end

	if not ply.UniversalAmmoDownloads then
		ply.UniversalAmmoDownloads = 1
		net.Start("UniversalAmmo_DownloadConfig")
			net.WriteTable(config)
		net.Send(ply)
	elseif ply.UniversalAmmoDownloads < MAX_DOWNLOAD_REQUESTS then
		ply.UniversalAmmoDownloads = ply.UniversalAmmoDownloads + 1
		net.Start("UniversalAmmo_DownloadConfig")
			net.WriteTable(config)
		net.Send(ply)
	end
end)

net.Receive("UniversalAmmo_ResetToDefaults", function(len, ply)
	if UniversalAmmo.CanEditConfig(ply) and not UniversalAmmo.IsConfigLocked() then
		file.Delete(configFilePath())
		loadConfig()
		ply:ChatPrint("UniversalAmmo: Reset to defaults!")
	else
		ply:ChatPrint("Universal Ammo: Permission denied")
	end
end)