AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local equipSounds = {
	"ambient/levels/labs/electric_explosion1.wav",
	"ambient/levels/labs/electric_explosion2.wav",
	"ambient/levels/labs/electric_explosion3.wav",
	"ambient/levels/labs/electric_explosion4.wav",
	"ambient/levels/labs/electric_explosion5.wav"
}

function ENT:Initialize()
    self:SetModel("models/items/boxmrounds.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetColor(Color(255,191,10))
    self:SetRenderMode(RENDERMODE_WORLDGLOW)
	self:SetKeyValue("renderfx", kRenderFxStrobeFaster)
    local phys = self:GetPhysicsObject()
    phys:Wake()
end

function ENT:OnTakeDamage(dmg)
	self:Remove()
end

local function makeSWEPPrimaryAmmoInfinite(ply, swep, ammoType)
	local ammo = game.GetAmmoName(ammoType)

	local originalTake = swep.TakePrimaryAmmo
	swep.IsUniversalAmmoInfinite = true

	swep.TakePrimaryAmmo = function(self, amount, ...)
		swep.UniversalAmmoGiveBack = swep.UniversalAmmoGiveBack and swep.UniversalAmmoGiveBack + amount or 0
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

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer()
		and caller.UniversalAmmoCooldown == nil
		or caller.UniversalAmmoCooldown + UNIVERSAL_AMMO_COOLDOWN < CurTime() then

		caller.UniversalAmmoCooldown = CurTime()
		local swep = caller:GetActiveWeapon()

		if swep and IsValid(swep) then
			local ammoType = swep:GetPrimaryAmmoType()

			if ammoType and ammoType ~= -1 then
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