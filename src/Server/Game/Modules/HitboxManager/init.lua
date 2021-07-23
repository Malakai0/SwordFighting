local Knit = require(game:GetService("ReplicatedStorage").Knit)

local HitboxManager = {}
local HitboxModule = require(script.Hitbox);

-- This really does nothing. Like at all. Just thought it was funny.
local Name = ''
for i = 1, math.random(2,#'HumanoidRootPart') do
    Name = Name .. string.char(math.random(65,91))
end

HitboxManager.HitboxName = Name;

function HitboxManager.ApplyHitboxToCharacter(Character: Model)
    local Welding = Knit.Shared.Welding;

    local HitboxModel = game:GetService("ServerStorage").Assets.Hitbox;

    for _, Part: BasePart in next, HitboxModel:GetChildren() do
        if (Part:IsA('BasePart') and Character:FindFirstChild(Part.Name)) then
            local TargetPart = Character[Part.Name];

            local HitboxPart = Part:Clone()
            HitboxPart.Name = HitboxManager.HitboxName;
            HitboxPart.Parent = TargetPart;
            Welding.WeldParts('Hitbox', TargetPart, HitboxPart);
        end
    end
end

HitboxManager.CreateHitboxForInstance = HitboxModule.new;

return HitboxManager