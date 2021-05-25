include("shared.lua")

function ENT:Draw()
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
