--[[

	DForm - https://wiki.facepunch.com/gmod/DForm
]]--

UniversalAmmo.Menu = {}
local config = {}
UniversalAmmo.Config = function() return config end

local function updateConfig(configName, className, value)
	local networkMapping = {
		['ammo'] = "UniversalAmmo_SetAmmoCount",
		['darkrp'] = "UniversalAmmo_SetDarkRPAmmo"
		-- ['swep.primary'] = "UniversalAmmo_SetPrimaryAmmoForSWEP",
		-- ['swep.secondary'] = "UniversalAmmo_SetSecondaryAmmoForSWEP"
	}

	if istable(value) then
		value = util.TableToJSON(value)
	end

	print("Updating config")

	net.Start(networkMapping[configName])
		net.WriteString(className)
		net.WriteString(tostring(value))
	net.SendToServer()
end
UniversalAmmo.UpdateServerConfig = updateConfig

UniversalAmmo.Menu.IsOpen = function()
	return UniversalAmmo.Menu.Frame ~= nil
end

--
-- Load data
--

net.Receive("UniversalAmmo_DownloadConfig", function()
	timer.Remove("UniversalAmmo_DownloadConfig")
	-- Do not load twice - count because key:val pairs
	if table.Count(config)==0 then
		config = net.ReadTable()
		hook.Run("UniversalAmmo_DownloadedConfig", config)
		LocalPlayer():ChatPrint("Loaded config")
	end
end)
timer.Create("UniversalAmmo_DownloadConfig", 1, 0, function()
	local ply = LocalPlayer()

	if IsValid(ply) then
		net.Start("UniversalAmmo_DownloadConfig")
		net.SendToServer()
	end
end)

--
-- Update data
--

UniversalAmmo.UpdateLocalConfig = function(configName, className, value)
	-- hack
	if configName == 'darkrp' then
		value = util.JSONToTable(value)
	end

	config[configName] = config[configName] or {}
	config[configName][className] = value

	hook.Run('UniversalAmmo_OnConfigChanged',
		configName,
		className,
		value
	)
end

UniversalAmmo.Menu.UpdateConfig = function(configName, className, value)
	UniversalAmmo.UpdateLocalConfig(configName, className, value)
	-- Can only update an open menu
	if UniversalAmmo.Menu.IsOpen() then
		UniversalAmmo.Menu.Panel[configName].UpdateRow(className, value)
	end
end
net.Receive("UniversalAmmo_OnConfigChanged", function()
	UniversalAmmo.Menu.UpdateConfig(
		net.ReadString(),
		net.ReadString(),
		net.ReadString()
	)
end)

--[[
	Spawn Menu
]]--

hook.Add("AddToolMenuCategories", "CustomCategory222", function()
	spawnmenu.AddToolCategory("Utilities", "Universal_Ammo", "Universal Ammo")
end)

local function createRow(className, value, possibleValues)
	local row = {}

	local classLabel = vgui.Create("DLabel", row)
	classLabel:Dock(LEFT)
	classLabel:SetTextColor(Color(0,0,0,255))
	classLabel:SetText(className)
	classLabel:SetTooltip(className)
	row.classLabel = classLabel

	local valueEntry = vgui.Create("DTextEntry", row)
	valueEntry:Dock(RIGHT)
	valueEntry:SetText(value)
	valueEntry:SetNumeric(true)
	valueEntry.OnEnter = function(self)
		updateConfig('ammo', classLabel:GetText(), self:GetValue())
	end
	row.valueEntry = valueEntry

	return row
end

UniversalAmmo.Menu.Generate = function(panel)
	UniversalAmmo.Menu.Frame = panel
	UniversalAmmo.Menu.Panel = {}
	UniversalAmmo.Menu.Panel['ammo'] = panel
	panel:DockPadding(0, 0, 0, 5)
	panel:ClearControls()

	local rows = {}
	local possibleValues = UniversalAmmo.GetAmmoClasses()

	if not IsValid(UniversalAmmo.Menu.HiddenPanel) then
		UniversalAmmo.Menu.HiddenPanel = vgui.Create("DPanel")
		UniversalAmmo.Menu.HiddenPanel:Hide()
	end

	panel.AddRow = function(className, value)
		local row = createRow(
			className,
			value,
			possibleValues
		)
		panel:AddItem(row.classLabel, row.valueEntry)
		table.insert(rows, row)
	end

	panel.PopulateRows = function(classAndValue)
		if classAndValue then
			for class, value in pairs(classAndValue) do
				panel.AddRow(class, value)
			end
		end
	end

	panel.ClearRows = function()
		for k, v in pairs(rows) do
			v.classLabel:Remove()
			v.valueEntry:Remove()
		end
		rows = {}
	end

	panel.UpdateRow = function(className, value)
		for i, row in ipairs(rows) do
			if row.classLabel:GetText() == className then
				row.valueEntry:SetText(value)
				break
			end
		end
	end

	panel.RowsToTable = function()
		local tbl = {}

		for k, row in pairs(rows) do
			table.insert(tbl, {
				Key = row.classLabel:GetText(),
				Value = row.valueEntry:GetValue()
			})
		end

		return tbl
	end

	panel.SortRows = function(text)
		local prevRows = panel.RowsToTable()
		panel.ClearRows()
		table.sort(
			prevRows,
			function(a, b)
				return UniversalAmmo.StringLikeness(a.Key, text)
					> UniversalAmmo.StringLikeness(b.Key, text)
			end
		)
		for k, row in ipairs(prevRows) do
			panel.AddRow(row.Key, row.Value)
		end
	end

	local sortEntry = panel:TextEntry('Sort')
	sortEntry:SetPlaceholderText("sort by class name")
	sortEntry.OnChange = function(self)
		local searchText = self:GetValue()
		panel.SortRows(searchText)
	end
	panel.sortEntry = sortEntry

	local primaryAmmoBtn = vgui.Create("DButton", heldAmmoPanel)
	primaryAmmoBtn:SetText("Primary: ")
	primaryAmmoBtn:Dock(FILL)
	primaryAmmoBtn.DoClick = function()
		local wep = LocalPlayer():GetActiveWeapon()
		local primary = wep:GetPrimaryAmmoType()
		if primary ~= -1 then
			panel.sortEntry:SetText(game.GetAmmoName(primary))
			panel.sortEntry:OnChange()
		end
	end
	primaryAmmoBtn.Think = function(self)
		local wep = LocalPlayer():GetActiveWeapon()
		local primary = wep:GetPrimaryAmmoType()
		self:SetDisabled(primary==-1)
		if primary ~= -1 then
			primaryAmmoBtn:SetText("Primary: " .. game.GetAmmoName(primary))
		else
			primaryAmmoBtn:SetText("Primary: None")
		end
	end

	local secondaryAmmoBtn = vgui.Create("DButton", heldAmmoPanel)
	secondaryAmmoBtn:SetText("Secondary: ")
	secondaryAmmoBtn:Dock(FILL)
	secondaryAmmoBtn.DoClick = function()
		local wep = LocalPlayer():GetActiveWeapon()
		local secondary = wep:GetSecondaryAmmoType()
		if secondary ~= -1 then
			panel.sortEntry:SetText(game.GetAmmoName(secondary))
			panel.sortEntry:OnChange()
		end
	end
	secondaryAmmoBtn.Think = function(self)
		local wep = LocalPlayer():GetActiveWeapon()
		local secondary = wep:GetSecondaryAmmoType()
		self:SetDisabled(secondary==-1)
		if secondary ~= -1 then
			secondaryAmmoBtn:SetText("Secondary: " .. game.GetAmmoName(secondary))
		else
			secondaryAmmoBtn:SetText("Secondary: None")
		end
	end

	panel:AddItem(primaryAmmoBtn)
	panel:AddItem(secondaryAmmoBtn)

	panel.PopulateRows(config['ammo'])
end

hook.Add("PopulateToolMenu", "CustomMenuSettings2222", function()
	spawnmenu.AddToolMenuOption("Utilities", "Universal_Ammo", "Ammo", "Ammo", "", "", function(panel)
		UniversalAmmo.Menu.Generate(panel)
	end)
end)