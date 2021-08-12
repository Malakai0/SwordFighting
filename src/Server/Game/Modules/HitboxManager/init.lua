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

    local Humanoid: Humanoid = Character:WaitForChild'Humanoid';

    local Welding = Knit.Shared.Welding;

    local HitboxModel = game:GetService("ServerStorage").Assets.Hitbox;

    local HitboxParts = {};

    for _, Part: BasePart in next, HitboxModel:GetChildren() do
        if (Part:IsA('BasePart') and Character:FindFirstChild(Part.Name)) then
            local TargetPart = Character[Part.Name];

            local Link = Instance.new('ObjectValue')
            Link.Name = 'Link'

            local HitboxPart = Part:Clone()
            HitboxPart.Name = HitboxManager.HitboxName;
            Link.Value = TargetPart
            Link.Parent = HitboxPart
        
            Link:GetPropertyChangedSignal('Value'):Connect(function()
                HitboxPart:Destroy()
            end)

            HitboxPart.Parent = workspace.Entities.Hitboxes;
            Welding.WeldParts('Hitbox', TargetPart, HitboxPart);
            table.insert(HitboxParts, HitboxPart)
        end
    end

    local Connection;
    Connection = Humanoid.Died:Connect(function()
        Connection:Disconnect()

        for i,v in next, HitboxParts do
            v:Destroy()
            v = nil
        end
        HitboxParts = nil;
    end)
end

HitboxManager.CreateHitboxForInstance = HitboxModule.new;

return HitboxManager