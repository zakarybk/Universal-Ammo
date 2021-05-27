-- Do you like my DarkRP hack?

if SERVER then
	function UniversalAmmo.loadServerDarkRPStuff()
		util.AddNetworkString("UniversalAmmo_MarkEntAsUniversalAmmo")
		util.AddNetworkString("UniversalAmmo_SetDarkRPAmmo")

		local universalAmmoTypes = UniversalAmmo.UniversalAmmoClasses()

		local function makeEntUniversalAmmo(ent)
			if ent.ammoType == "universal_ammo" then
				UniversalAmmo.Primary.Initialize(ent)
				ent.Use = UniversalAmmo.Primary.Use

			elseif ent.ammoType == "universal_ammo_secondary" then
				UniversalAmmo.Secondary.Initialize(ent)
				ent.Use = UniversalAmmo.Secondary.Use

			elseif ent.ammoType == "universal_ammo_infinite" then
				UniversalAmmo.Infinite.Initialize(ent)
				ent.Use = UniversalAmmo.Infinite.Use
				ent.StartTouch = function() end -- cannot stack infinite ammo
			end

			net.Start("UniversalAmmo_MarkEntAsUniversalAmmo")
				net.WriteEntity(ent)
			net.Send(player.GetAll())
		end

		-- https://github.com/FPtje/DarkRP/blob/8c0035710adefa47c1dbffc9ae65461f66ae73f4/gamemode/modules/base/sv_purchasing.lua#L428
		hook.Add("playerBoughtAmmo", "UniversalAmmo", function(ply, found, ammo, cost)
			if IsValid(ammo) and universalAmmoTypes[ammo.ammoType] then
				makeEntUniversalAmmo(ammo)
			end
		end)

		-- Edit ammo in buy menu
		net.Receive("UniversalAmmo_SetDarkRPAmmo", function(len, ply)
			if UniversalAmmo.CanEditConfig(ply) and not UniversalAmmo.IsConfigLocked() then
				local uniAmmos = universalAmmoTypes

				local ammoClass = net.ReadString()
				local tbl = util.JSONToTable(net.ReadString())
				local printName = tbl.printName
				local price = math.abs(tonumber(tbl.price))
				local enabled = tbl.enabled

				if uniAmmos[ammoClass] then
					UniversalAmmo.UpdateConfigRow(
						'darkrp',
						ammoClass,
						{
							['printName'] = printName,
							['price'] = price,
							['enabled'] = enabled
						}
					)

					ply:ChatPrint("Updated " .. ammoClass .. " in buy menu with name = "
						.. printName .. " and price = " .. tostring(price)
						.. " and is " .. (enabled and "enabled" or "disabled") .. " for buying")
				end
			end
		end)
	end
end

if CLIENT or SERVER then
	hook.Add("loadCustomDarkRPItems", "UniversalAmmo", function()
		-- Use hook reference instead of gamemode because people like
		-- to use the DarkRP gamemode as a base
		if SERVER then UniversalAmmo.loadServerDarkRPStuff() end

		-- Universal Ammo config is loaded at an undefined time
		timer.Create("UniversalAmmo_LoadDarkRP", 1, 30, function()
			local config = UniversalAmmo.Config()

			if config['darkrp'] and table.Count(config['darkrp']) > 0 then
				for className, ammoData in pairs(config['darkrp']) do
					if tobool(ammoData.enabled) then
						DarkRP.createAmmoType(className, {
						    name = ammoData.printName,
						    model = "models/Items/BoxMRounds.mdl",
						    price = tonumber(ammoData.price),
						    amountGiven = 1 -- allow universal ammo to stack
						})
						print("Universal Ammo DarkRP: Creating " .. className .. " ammo")
					end
				end
				timer.Remove("UniversalAmmo_LoadDarkRP")
			end
		end)

		hook.Add("PopulateToolMenu", "UniversalAmmo_DarkRP", function()
			spawnmenu.AddToolMenuOption("Utilities", "Universal_Ammo", "DarkRP", "DarkRP", "", "", function(panel)
				panel:ClearControls()
				panel:ControlHelp("These settings require a server restart to take effect!")
				-- This is a lie, but I cannot be bothered to update the UI here when these settings change
				-- maybe once, the whole time the addon is on the server
				panel:Help("So these settings are also not synced between clients until a restart has taken place.")

				local function updateDarkRPAmmo(className, printName, price, enabled)
					UniversalAmmo.UpdateServerConfig(
						'darkrp',
						className,
						{
							['printName'] = printName,
							['price'] = price,
							['enabled'] = enabled
						}
					)
				end

				for _, className in SortedPairs(UniversalAmmo.UniversalAmmoClasses()) do
					local config = UniversalAmmo.Config()['darkrp'][className]
					-- enable / disable
					local checkbox = panel:CheckBox("Add " .. className .. " to the buy menu.")
					checkbox.OnChange = function(self, bVal)
						local config = UniversalAmmo.Config()['darkrp'][className]
						updateDarkRPAmmo(className, config.printName, config.price, bVal)
					end
					checkbox:SetChecked(config.enabled)

					-- printName
					local printName = panel:TextEntry("Print Name: ")
					printName:SetText(config.printName)
					printName.OnEnter = function(self)
						local config = UniversalAmmo.Config()['darkrp'][className]
						updateDarkRPAmmo(className, self:GetValue(), config.price, config.enabled)
					end
					printName.OnLoseFocus = function( self )
						if tostring(self:GetValue()) ~= config['darkrp'][className] then
							local config = UniversalAmmo.Config()['darkrp'][className]
							updateDarkRPAmmo(className, config.printName, self:GetValue(), config.enabled)
						end
					end

					-- price
					local price = panel:TextEntry("Price: ")
					price:SetNumeric(true)
					price:SetText(tonumber(config.price))
					price.OnEnter = function(self)
						local config = UniversalAmmo.Config()['darkrp'][className]
						updateDarkRPAmmo(className, config.printName, self:GetValue(), config.enabled)
					end
					price.OnLoseFocus = function( self )
						if tostring(self:GetValue()) ~= UniversalAmmo.Config()['darkrp'][className] then
							local config = UniversalAmmo.Config()['darkrp'][className]
							updateDarkRPAmmo(className, config.printName, self:GetValue(), config.enabled)
						end
					end
				end
			end)
		end)
	end)
end