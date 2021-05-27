AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Universal Secondary Ammo"
ENT.Author = "Zak"

ENT.Category = "Universal Ammo"
ENT.Spawnable = true

if SERVER then
	ENT.Initialize = UniversalAmmo.Secondary.Initialize

	function ENT:OnTakeDamage(dmg)
		self:Remove()
	end

	ENT.Use = UniversalAmmo.Secondary.Use
end

if CLIENT then
	ENT.Draw = UniversalAmmo.EntDraw
end