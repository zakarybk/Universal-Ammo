util.AddNetworkString("UniversalAmmo_SetAmmoCount")

-- util.AddNetworkString("UniversalAmmo_SetPrimaryAmmoForSWEP")
-- util.AddNetworkString("UniversalAmmo_SetSecondaryAmmoForSWEP")

util.AddNetworkString("UniversalAmmo_OnConfigChanged")
util.AddNetworkString("UniversalAmmo_DownloadConfig")

local hasLoadedConfig = false
local config = {
	['ammo'] = {},
	-- ['swep.primary'] = {},
	-- ['swep.secondary'] = {},
	-- ['darkrp'] = {} -- TODO: Add entity to F4 menu
}
UniversalAmmo.Config = function() return config end

local DIRECTORY = 'universal_ammo'
local FILE = 'config.txt'
local MAX_DOWNLOAD_REQUESTS = 5

local function configFilePath()
	return DIRECTORY .. '/' .. FILE
end

local function saveConfig()
	if not file.Exists(DIRECTORY, 'DATA') then
		file.CreateDir(DIRECTORY)
	end

	file.Write(
		configFilePath(),
		util.TableToJSON(config, true)
	)
end

local function forceTableValueToString(tbl)
	local replaced = {}

	for k, v in pairs(tbl) do
		if istable(v) then
			replaced[tostring(k)] = forceTableValueToString(v)
		else
			replaced[tostring(k)] = tostring(v)
		end
	end

	return replaced
end

local function loadConfig()
	-- Game needs to load all sweps first
	timer.Simple(2, function()
		-- set default values for ammo
		config['ammo'] = UniversalAmmo.GuessGoodAmmoCount()
		if table.Count(config['ammo']) == 0 then
			loadConfig() -- try again...
			return
		end

		if file.Exists(configFilePath(), 'DATA') then
			-- Allow default values above to be set
			-- Means when new ammo is added, we have
			-- a default value
			table.Merge(
				config,
				forceTableValueToString(
					util.JSONToTable(
						file.Read(configFilePath(), 'DATA')
					)
				)
			)
		end

		hasLoadedConfig = true
		net.Start("UniversalAmmo_DownloadConfig")
			net.WriteTable(config)
		net.Send(player.GetAll())
	end)
end
hook.Add("InitPostEntity", "UniversalAmmo_LoadConfig", loadConfig)

-- Where configName = key in config{},
-- Where className = ammo class or swep class
-- Where value = bullet count or ammo class
hook.Add("UniversalAmmo_OnConfigChanged", "UpdateClients",
	function(configName, className, value)

	net.Start("UniversalAmmo_OnConfigChanged")
		net.WriteString(configName)
		net.WriteString(className)
		net.WriteString(value)
	net.Send(player.GetAll())
end)

local function updateConfigRow(configName, className, value)
	config[configName] = table.Merge(
		config[configName],
		{[className] = value}
	)
	saveConfig()
	hook.Run('UniversalAmmo_OnConfigChanged',
		configName,
		className,
		value
	)
end

local function setBulletCountForAmmo(bulletCount, ammoClass)
	if UniversalAmmo.IsValidAmmoClass(ammoClass) and isnumber(bulletCount) then
		updateConfigRow('ammo', ammoClass, math.abs(bulletCount))
	end
end

net.Receive("UniversalAmmo_SetAmmoCount", function(len, ply)
	if not hasLoadedConfig then return end

	if UniversalAmmo.CanEditConfig(ply) then
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