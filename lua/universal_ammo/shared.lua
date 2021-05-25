UniversalAmmo = UniversalAmmo or {}

--[[
	Helper functions

	Yes we could index the tables, but this is
	only ever run to validate config changes,
	so it's not worth the hassle.
]]--

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
			math.Round(math.Clamp(average(clipCounts) * 2, 1, 80))
	end

	return adjustedAmmoAverages
end

-- SO um, the wiki has
-- GetPrimaryAmmoType, https://wiki.facepunch.com/gmod/Weapon:GetPrimaryAmmoType
-- + same for secondary - skip the whole weapon : ammo type thing?

UniversalAmmo.GetBullets = function(ammoClass)
	local ammoData = UniversalAmmo.Config['ammo']

	if ammoData[ammoClass] then
		return ammoData[ammoClass]
	end
	return 0 -- 0 = not supported
end