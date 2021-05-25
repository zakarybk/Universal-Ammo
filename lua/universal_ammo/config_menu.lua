UniversalAmmo.Menu = {}
local config = {}
UniversalAmmo.Config = function() return table.Copy(config) end

local function updateConfig(configName, className, value)
	local networkMapping = {
		['ammo'] = "UniversalAmmo_SetAmmoCount",
		['swep.primary'] = "UniversalAmmo_SetPrimaryAmmoForSWEP",
		['swep.secondary'] = "UniversalAmmo_SetSecondaryAmmoForSWEP"
	}
	net.Start(networkMapping[configName])
		net.WriteString(className)
		net.WriteString(tostring(value))
	net.SendToServer()
end

local function numbersToN(n)
	local numbers = {}
	for i=0, n, 1 do
		table.insert(numbers, i)
	end
	return numbers
end

--
-- Menu base
--

local function classListFrame(parent, getClasses, possibleValues, onValueChanged)
	--[[
		A frame with an UpdateRow and AddRow parameter

		[filter]

		class   | value
		----------------------
		[label] | [DTextEntry]
			    |
			    |
	]]--
	local rows = {}

	local panel = vgui.Create("DPanel", parent)
	panel:Dock(FILL)
	panel:DockMargin(5, 0, 5, 5)

	local filterEntry = vgui.Create("DTextEntry", panel)
	filterEntry:Dock(TOP)
	filterEntry:DockMargin(5, 5, 5, 5)
	filterEntry:SetPlaceholderText("filter by class name")
	filterEntry.OnChange = function(self)
		local searchText = self:GetValue()
		-- Hide children from panel
		for i, row in ipairs(rows) do
			row:SetParent(parent)
			row:Hide()
		end
		-- Sort children by search term
		table.sort(
			rows,
			function(a, b)
				return UniversalAmmo.StringLikeness(a.classLabel:GetText(), searchText)
					> UniversalAmmo.StringLikeness(b.classLabel:GetText(), searchText)
			end
		)
		-- Show children in order
		for i, row in ipairs(rows) do
			row:SetParent(filterEntry.FilterPanel)
			row:Show()
			print(row.classLabel:GetText())
		end
	end
	panel.filterEntry = filterEntry

	local scrollPanel = vgui.Create("DScrollPanel", panel)
	scrollPanel:Dock( FILL )
	scrollPanel:DockMargin(5, 5, 5, 5)

	local layout = vgui.Create("DListLayout", scrollPanel)
	layout:Dock(FILL)
	-- layout:DockMargin(5, 5, 5, 5)
	filterEntry.FilterPanel = layout

	local hardHalfWidth = 295 -- Actual width does not exist yet

	local function createRow(className, value)
		local row = vgui.Create("DPanel")
		row:SetSize(0,30)
		row:Dock(FILL)
		row:DockMargin(2, 2, 2, 0)

		local classLabel = vgui.Create("DLabel", row)
		classLabel:SetSize(hardHalfWidth-5, 0)
		classLabel:Dock(LEFT)
		classLabel:SetDark(true)
		classLabel:DockMargin(2, 2, 2, 2)
		classLabel:SetText(className)
		row.classLabel = classLabel

		local valueEntry = vgui.Create("DTextEntry", row)
		valueEntry:SetSize(hardHalfWidth-5, 0)
		valueEntry:Dock(RIGHT)
		valueEntry:DockMargin(2, 2, 2, 2)
		valueEntry:SetText(value)
		valueEntry.OnEnter = function(self)
			onValueChanged(className, self:GetValue())
		end
		valueEntry.GetAutoComplete = function(self, inputText)
			local values = table.Copy(possibleValues)
			table.sort(
				values,
				function(a, b)
					return UniversalAmmo.StringLikeness(a, inputText)
						> UniversalAmmo.StringLikeness(b, inputText)
				end
			)
			return values
		end
		row.valueEntry = valueEntry
		return row
	end

	panel.AddRow = function(className, value)
		local row = createRow(className, value)
		layout:Add(row)
		table.insert(rows, row)
	end

	panel.PopulateRows = function(classAndValue)
		if classAndValue then
			for class, value in pairs(classAndValue) do
				panel.AddRow(class, value)
			end
		end
	end

	panel.UpdateRow = function(className, value)
		for i, row in ipairs(rows) do
			if row.classLabel:GetText() == className then
				row.valueEntry:SetText(value)
				break
			end
		end
	end

	-- for i = 1, 16 do
	-- 	local row = createRow()
	-- 	table.insert(rows, row)
	-- 	layout:Add( row )
	-- end

	return panel
end

UniversalAmmo.Menu.Open = function()

	UniversalAmmo.Menu.Panel = {}

	local frame = vgui.Create("DFrame")
	frame:SetSize(600, 400)
	frame:Center()
	frame:SetTitle("Universal Ammo Config")
	frame:MakePopup()
	UniversalAmmo.Menu.Frame = frame
-- 	frame.Paint = function( self, w, h )	-- Paint function w, h = how wide and tall it is.
-- 	-- Draws a rounded box with the color faded_black stored above.
-- 	draw.RoundedBox( 2, 0, 0, w, h, Color( 32, 33, 34, 255 ) )
-- 	-- Draws text in the color white.
-- end
	local sheet = vgui.Create( "DPropertySheet", frame )
	sheet:Dock( FILL )
	local ammoPanel = classListFrame(
		sheet,
		UniversalAmmo.GetAmmoClasses(),
		{},
		function(className, value) updateConfig('ammo', className, value) end
	)
	-- PrintTable(UniversalAmmo.Config)
	ammoPanel.PopulateRows(config['ammo'])
	sheet:AddSheet("Ammo", ammoPanel, "icon16/box.png")
	UniversalAmmo.Menu.Panel['ammo'] = ammoPanel

	local heldAmmoPanel = vgui.Create("DPanel", ammoPanel)
	heldAmmoPanel:Dock(BOTTOM)
	heldAmmoPanel:DockMargin(5, 0, 5, 5)

	local primaryAmmoBtn = vgui.Create("DButton", heldAmmoPanel)
	primaryAmmoBtn:SetText("Primary: ")
	primaryAmmoBtn:SetSize(250, 20)
	primaryAmmoBtn:Dock(LEFT)
	primaryAmmoBtn.DoClick = function()
		local wep = LocalPlayer():GetActiveWeapon()
		local primary = wep:GetPrimaryAmmoType()
		if primary ~= -1 then
			ammoPanel.filterEntry:SetText(game.GetAmmoName(primary))
			ammoPanel.filterEntry:OnChange()
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
	secondaryAmmoBtn:SetSize(250, 20)
	secondaryAmmoBtn:Dock(RIGHT)
	secondaryAmmoBtn.DoClick = function()
		local wep = LocalPlayer():GetActiveWeapon()
		local secondary = wep:GetSecondaryAmmoType()
		if secondary ~= -1 then
			ammoPanel.filterEntry:SetText(game.GetAmmoName(secondary))
			ammoPanel.filterEntry:OnChange()
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

	-- timer.Simple(10, function() frame:Remove() end)

	-- make frames -- ammo:SetParent(frame)
	--UniversalAmmo.Menu.Frame = 
end

timer.Simple(1.5, function()
	UniversalAmmo.Menu.Open()
	-- UniversalAmmo.Menu.LoadConfig(UniversalAmmo.Config)
end)

UniversalAmmo.Menu.Close = function()
	UniversalAmmo.Menu.Frame:Remove()
end

UniversalAmmo.Menu.IsOpen = function()
	return UniversalAmmo.Menu.Frame ~= nil
end

--
-- Load data
--

-- UniversalAmmo.Menu.LoadConfig = function(config)
-- 	-- Can only update an open menu
-- 	if not UniversalAmmo.Menu.IsOpen() then
-- 		return
-- 	end

-- 	config['ammo'] = {['test_ammo'] = 15, ['test_ammo2'] = 15, ['test_ammo3'] = 15}

-- 	PrintTable(config)

-- 	for configName, tbl in pairs(config) do
-- 		for className, value in pairs(tbl) do
-- 			print(configName, className, value)
-- 			if UniversalAmmo.Menu.Panel[configName] then
-- 				UniversalAmmo.Menu.Panel[configName].AddRow(
-- 					className,
-- 					value
-- 				)
-- 			end
-- 		end
-- 	end
-- end
net.Receive("UniversalAmmo_DownloadConfig", function()
	timer.Remove("UniversalAmmo_DownloadConfig")
	config = net.ReadTable()
	LocalPlayer():ChatPrint("Loaded config")
	PrintTable(UniversalAmmo.Config())
end)
timer.Create("UniversalAmmo_DownloadConfig", 1, 0, function()
	local ply = LocalPlayer()

	if IsValid(ply) then
		timer.Simple(0.5, function()
		net.Start("UniversalAmmo_DownloadConfig")
		net.SendToServer()
	end)
	end
end)

--
-- Update data
--

UniversalAmmo.Menu.UpdateConfig = function(configName, className, value)
	config[configName] = config[configName] or {}
	config[configName][className] = value
	-- Can only update an open menu
	if UniversalAmmo.Menu.IsOpen() then
		UniversalAmmo.Menu.Panel[configName].UpdateRow(className, value)
	end
	hook.Run('UniversalAmmo_OnConfigChanged',
		configName,
		className,
		value
	)
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

-- hook.Add( "AddToolMenuCategories", "CustomCategory", function()
-- 	spawnmenu.AddToolCategory( "Utilities", "Stuff", "#Stuff" )
-- end )

-- hook.Add( "PopulateToolMenu", "CustomMenuSettings", function()
-- 	spawnmenu.AddToolMenuOption( "Utilities", "Stuff", "Custom_Menu", "#My Custom Menu", "", "", function( panel )
-- 		panel:ClearControls()
-- 		panel:NumSlider( "Gravity", "sv_gravity", 0, 600 )
-- 		-- Add stuff here
-- 	end )
-- end )