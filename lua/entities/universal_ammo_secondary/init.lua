AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/items/boxmrounds.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetColor(Color(255,110,20))
    local phys = self:GetPhysicsObject()
    phys:Wake()
end

function ENT:OnTakeDamage(dmg)
	self:Remove()
end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer()
		and caller.UniversalAmmoCooldown == nil
		or caller.UniversalAmmoCooldown + UNIVERSAL_AMMO_COOLDOWN < CurTime() then

		caller.UniversalAmmoCooldown = CurTime()
		local swep = caller:GetActiveWeapon()

		if swep and IsValid(swep) then
			local ammoType = swep:GetSecondaryAmmoType()

			if ammoType and ammoType ~= -1 then
				local ammo = game.GetAmmoName(ammoType)
				local amount = UniversalAmmo.GetBullets(ammo)

				caller:GiveAmmo(amount, ammo)
				self:Remove()
			else
				caller:ChatPrint("Held weapon doesn't take secondary ammo!")
				caller.UniversalAmmoCooldown = CurTime()
			end
		end
	end
end