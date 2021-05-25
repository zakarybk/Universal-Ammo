AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local coolDown = {}

function ENT:Initialize()
    self:SetModel("models/items/boxmrounds.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    phys:Wake()
end

function ENT:OnTakeDamage(dmg)
	self:Remove()
end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer() and caller.UniversalAmmoCooldown == nil or caller.UniversalAmmoCooldown + 1 < CurTime() then
		local wep = caller:GetActiveWeapon()
		local ammoType = wep:GetPrimaryAmmoType()
		if wep and ammoType and ammoType != -1 then
			local ammo = game.GetAmmoName(wep)
			local amount = UniversalAmmoCFG[ammo] or math.Clamp(caller:GetActiveWeapon():GetMaxClip1() * 2, 1, 80)

			caller:GiveAmmo(amount, ammo)
			self:Remove()
		else
			caller:ChatPrint("Please equip the weapon you wish to refill!")
			caller.UniversalAmmoCooldown = CurTime()
		end
	end
end

-- OnReloaded() no work
-- GetActiveWeapon().TakePrimaryAmmo works
-- spawn menu?