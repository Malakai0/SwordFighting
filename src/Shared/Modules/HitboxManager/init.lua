local Knit = require(game:GetService("ReplicatedStorage").Knit)

local HitboxManager = {}
local HitboxModule = require(script.Hitbox);

-- This really does nothing. Like at all. Just thought it was funny.
local Name = ''
for i = 1, math.random(2,#'HumanoidRootPart') do
    Name = Name .. string.char(math.random(65,91))
end

HitboxManager.HitboxName = Name;

function HitboxManager.ApplyHitbox(Character: Model)
    local Welding = Knit.Shared.Welding;
    for _, Part: BasePart in next, Character:GetChildren() do
        if (Part:IsA('BasePart')) then
            local HitboxPart = Part:Clone()
            HitboxPart.Name = 'Hitbox';
            HitboxPart.Transparency = 1;
            HitboxPart.CanCollide = false;
            HitboxPart.CanTouch = false; -- We use raycasting.
            HitboxPart.Size = HitboxPart.Size + Vector3.new(1,1,1);
            HitboxPart.CFrame = Part.CFrame;
            HitboxPart.Parent = Part;
            Welding.WeldParts(Part.Name .. 'Hitbox', Part, HitboxPart);
        end
    end
end

function HitboxManager.CreateHitbox(Name)

end

return HitboxManager