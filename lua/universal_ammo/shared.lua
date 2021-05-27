UniversalAmmo = UniversalAmmo or {}
UNIVERSAL_AMMO_COOLDOWN = 0.33
--[[
	Helper functions

	Yes we could index the tables, but this is
	only ever run to validate config changes,
	so it's not worth the hassle.
]]--

UniversalAmmo.CanEditConfig = function(ply)
	return IsValid(ply) and ply:IsSuperAdmin() or game.SinglePlayer()
end

UniversalAmmo.UniversalAmmoClasses = function()
	return {
		["universal_ammo"] = "universal_ammo",
		["universal_ammo_secondary"] = "universal_ammo_secondary",
		["universal_ammo_infinite"] = "universal_ammo_infinite"
	}
end

UniversalAmmo.GetAmmoClasses = function()
	return table.Copy(game.GetAmmoTypes())
end

UniversalAmmo.GetSWEPClasses = function()
	return table.GetKeys(list.Get("Weapon"))
end

UniversalAmmo.GetSWEPPrintName = function(swepClass)
	local sweps = table.Copy(list.Get("Weapon"))

	if sweps[swepClass] then
		return sweps[swepClass].PrintName
	end
	return "Unknown"
end

UniversalAmmo.IsValidAmmoClass = function(ammoClass)
	return table.HasValue(
		UniversalAmmo.GetAmmoClasses(),
		ammoClass
	)
end

UniversalAmmo.IsValidSWEPClass = function(swepClass)
	return table.HasValue(
		UniversalAmmo.GetSWEPClasses(),
		swepClass
	)
end

UniversalAmmo.StringLikeness = function(str1, str2)
	local score = 0
	local str1Letters = {}
	local str2Letters = {}

	if str1 == str2 then
		score = score + 1
	end

	if isnumber(tonumber(str1)) and isnumber(tonumber(str2)) then
		score = -math.abs(tonumber(str1)-tonumber(str2))
	end

	str1 = string.ToTable(str1)
	str2 = string.ToTable(str2)

	-- Score+ for same chars at index
	for index, char in pairs(str1) do
		-- Identical spots
		if char == str2[index] then
			score = score + 1
		end

		-- Number of each char in string
		if str1Letters[char] == nil then
			str1Letters[char] = 1
		else
			str1Letters[char] = str1Letters[char] + 1
		end
	end

	-- Number of each char in string
	for index, char in pairs(str2) do
		if str2Letters[char] == nil then
			str2Letters[char] = 1
		else
			str2Letters[char] = str2Letters[char] + 1
		end
	end

	-- Compare char counts
	for char, count in pairs(str1Letters) do
		if str2Letters[char] != nil then
			local diff = count - str2Letters[char]
			diff = 1 - math.abs(diff / str2Letters[char])
			score = score + 1
		end
	end

	return score
end

local function average(values)
	local count = 0

	for i, val in pairs(values) do
		count = count + val
	end

	return count / #values
end

-- Look at the ammo type and return average of clip size
UniversalAmmo.GuessGoodAmmoCount = function()
	local sweps = UniversalAmmo.GetSWEPClasses()

	local ammoClipSizes = {}

	local badAmmo = {
		[""] = true,
		["None"] = true,
		["none"] = true,
		["false"] = true,
		["true"] = true
	}

	-- Search in-use clip sizes for ammo types

	for _, swep in pairs(sweps) do
		local data = weapons.Get(swep)

		if data then

			if data.Primary and not badAmmo[data.Primary.Ammo] then
				if data.Primary.ClipSize then
					ammoClipSizes[data.Primary.Ammo] =
						ammoClipSizes[data.Primary.Ammo] or {}

					table.insert(
						ammoClipSizes[data.Primary.Ammo],
						data.Primary.ClipSize
					)
				end
			end

			if data.Secondary and not badAmmo[data.Secondary.Ammo] then
				if data.Secondary.ClipSize and data.Secondary.ClipSize > 0 then
					ammoClipSizes[data.Secondary.Ammo] =
						ammoClipSizes[data.Secondary.Ammo] or {}

					table.insert(
						ammoClipSizes[data.Secondary.Ammo],
						data.Secondary.ClipSize
					)
				end
			end

		end
	end

	-- Average clip sizes

	local adjustedAmmoAverages = {}

	for ammo, clipCounts in pairs(ammoClipSizes) do
		adjustedAmmoAverages[ammo] =
			math.max(1, math.Round(math.Clamp(average(clipCounts) * 2, 1, 80)))
	end

	return adjustedAmmoAverages
end

UniversalAmmo.GetBullets = function(ammoClass)
	local ammoData = UniversalAmmo.Config()['ammo']

	if ammoData[ammoClass] then
		return ammoData[ammoClass]
	end
	return 0 -- 0 = not supported
end

if CLIENT then
	UniversalAmmo.EntDraw = function(self)
	    self:DrawModel()

	    local Pos = self:GetPos()
	    local Ang = self:GetAngles()

	 	Ang:RotateAroundAxis(Ang:Right(), 270)
	    Ang:RotateAroundAxis(Ang:Up(), 90)

	    cam.Start3D2D(Pos + Ang:Up() * 5.65, Ang, 0.10)
	        draw.SimpleText("Universal","HUDNumber5",0,-80,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	        draw.SimpleText("Ammo","HUDNumber5",0,-50,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	    cam.End3D2D()
	end

	local function makeEntUniversalAmmo(ent)
		ent.Draw = UniversalAmmo.EntDraw
	end

	net.Receive("UniversalAmmo_MarkEntAsUniversalAmmo", function(len)
		local ent = net.ReadEntity()

		if IsValid(ent) then
			makeEntUniversalAmmo(ent)
		end
	end)
end

if SERVER then
	--
	-- Grouping functions here for hacky DarkRP ammo support
	--
	--[[
		universal_ammo
	]]--
	UniversalAmmo.Primary = {}

	UniversalAmmo.Primary.Use = function(self, activator, caller)
		if IsValid(caller) and caller:IsPlayer()
			and caller.UniversalAmmoCooldown == nil
			or caller.UniversalAmmoCooldown + UNIVERSAL_AMMO_COOLDOWN < CurTime() then

			caller.UniversalAmmoCooldown = CurTime()
			local swep = caller:GetActiveWeapon()

			if swep and IsValid(swep) then
				local ammoType = swep:GetPrimaryAmmoType()

				if ammoType and ammoType ~= -1 then
					-- Prevent pickup if not allowed for swep
					local ammo = game.GetAmmoName(ammoType)
					local amount = UniversalAmmo.GetBullets(ammo) * (self.amountGiven or 1) -- allow ammo stacking
					if amount == 0 then
						caller:ChatPrint("Sorry, this weapon cannot use universal ammo!")
					else
						caller:GiveAmmo(amount, ammo)
						self:Remove()
					end
				else
					caller:ChatPrint("Please equip the weapon you wish to refill!")
					caller.UniversalAmmoCooldown = CurTime()
				end
			end
		end
	end

	UniversalAmmo.Primary.Initialize = function(self)
	    self:SetModel("models/items/boxmrounds.mdl")
	    self:PhysicsInit(SOLID_VPHYSICS)
	    self:SetMoveType(MOVETYPE_VPHYSICS)
	    self:SetSolid(SOLID_VPHYSICS)
	    local phys = self:GetPhysicsObject()
	    phys:Wake()
	end

	--[[
		universal_ammo_secondary
	]]--
	UniversalAmmo.Secondary = {}

	UniversalAmmo.Secondary.Use = function(self, activator, caller)
		if IsValid(caller) and caller:IsPlayer()
			and caller.UniversalAmmoCooldown == nil
			or caller.UniversalAmmoCooldown + UNIVERSAL_AMMO_COOLDOWN < CurTime() then

			caller.UniversalAmmoCooldown = CurTime()
			local swep = caller:GetActiveWeapon()

			if swep and IsValid(swep) then
				local ammoType = swep:GetSecondaryAmmoType()

				if ammoType and ammoType ~= -1 then
					-- Prevent pickup if not allowed for swep
					local ammo = game.GetAmmoName(ammoType)
					local amount = UniversalAmmo.GetBullets(ammo) * (self.amountGiven or 1) -- allow ammo stacking
					if amount == 0 then
						caller:ChatPrint("Sorry, this weapon cannot use universal ammo!")
					else
						caller:GiveAmmo(amount, ammo)
						self:Remove()
					end
				else
					caller:ChatPrint("Held weapon doesn't take secondary ammo!")
					caller.UniversalAmmoCooldown = CurTime()
				end
			end
		end
	end

	UniversalAmmo.Secondary.Initialize = function(self)
		UniversalAmmo.Primary.Initialize(self)
		self:SetColor(Color(255,110,20))
	end

	--[[
		universal_ammo_infinite
	]]--
	UniversalAmmo.Infinite = {}

	local equipSounds = {
		"ambient/levels/labs/electric_explosion1.wav",
		"ambient/levels/labs/electric_explosion2.wav",
		"ambient/levels/labs/electric_explosion3.wav",
		"ambient/levels/labs/electric_explosion4.wav",
		"ambient/levels/labs/electric_explosion5.wav"
	}

	local function makeSWEPPrimaryAmmoInfinite(ply, swep, ammoType)
		local ammo = game.GetAmmoName(ammoType)

		-- Fill the clip
		swep:SetClip1(swep:GetMaxClip1())

		-- Watch weapon to return used ammo
		swep.IsUniversalAmmoInfinite = true

		local originalTake = swep.TakePrimaryAmmo
		swep.TakePrimaryAmmo = function(self, amount, ...)
			swep.UniversalAmmoGiveBack = swep.UniversalAmmoGiveBack and swep.UniversalAmmoGiveBack + amount or 1
			return originalTake(self, amount, ...)
		end

		local originalReload = swep.Reload

		swep.Reload = function(...)
			local usedAmmo = swep.UniversalAmmoGiveBack
			if usedAmmo then
				ply:GiveAmmo(usedAmmo, ammo)
				swep.UniversalAmmoGiveBack = 0
			end
			return originalReload(...)
		end
	end

	UniversalAmmo.Infinite.Use = function(self, activator, caller)
		if IsValid(caller) and caller:IsPlayer()
			and caller.UniversalAmmoCooldown == nil
			or caller.UniversalAmmoCooldown + UNIVERSAL_AMMO_COOLDOWN < CurTime() then

			caller.UniversalAmmoCooldown = CurTime()
			local swep = caller:GetActiveWeapon()

			if swep and IsValid(swep) then
				local ammoType = swep:GetPrimaryAmmoType()

				if ammoType and ammoType ~= -1 then
					-- Prevent pickup if not allowed for swep
					local ammo = game.GetAmmoName(ammoType)
					local amount = UniversalAmmo.GetBullets(ammo) * (self.amountGiven or 1) -- allow ammo stacking
					if amount == 0 then
						caller:ChatPrint("Sorry, this weapon cannot use universal ammo!")
						return
					end

					if not swep.IsUniversalAmmoInfinite then
						-- Don't want something to be infinite?
						local pleaseNo = hook.Run("UniversalAmmo_PreventInfinite", caller, swep, ammoType)

						if pleaseNo then
							caller:ChatPrint("Sorry, this weapon cannot use infinite ammo!")
							return
						end

						-- Sound and effect
						self:EmitSound(table.Random(equipSounds), 100, 100, 1, CHAN_AUTO)
						local effectdata = EffectData()
						effectdata:SetOrigin(self:GetPos())
						effectdata:SetScale(0.2)
						util.Effect("HelicopterMegaBomb", effectdata)

						-- Actual logic
						makeSWEPPrimaryAmmoInfinite(caller, swep, ammoType)
						self:Remove()
					else
						caller:ChatPrint("Weapon already equiped with infinite ammo!")
					end
				else
					caller:ChatPrint("Held weapon doesn't take primary ammo!")
					caller.UniversalAmmoCooldown = CurTime()
				end
			end
		end
	end

	UniversalAmmo.Infinite.Initialize = function(self)
		UniversalAmmo.Primary.Initialize(self)
		self:SetColor(Color(255,191,10))
	    self:SetRenderMode(RENDERMODE_WORLDGLOW)
		self:SetKeyValue("renderfx", kRenderFxStrobeFaster)
	end
end

