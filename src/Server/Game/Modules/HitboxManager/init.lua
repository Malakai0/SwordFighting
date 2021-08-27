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

    local CharacterUID = Character:GetAttribute("UID");

    if (not CharacterUID) then
        return warn('Invalid instance for hitbox: ' .. Character.Name);
    end

    for _, Part: BasePart in next, HitboxModel:GetChildren() do
        if (Part:IsA('BasePart') and Character:FindFirstChild(Part.Name)) then
            local TargetPart = Character[Part.Name];

            local HitboxPart = Part:Clone()
            HitboxPart.Name = HitboxManager.HitboxName;

            HitboxPart:SetAttribute('Identifier', string.format("%s.%s", CharacterUID, Part.Name));

            HitboxPart.Parent = workspace.Entities.Hitboxes;
            Welding.WeldParts('Hitbox', TargetPart, HitboxPart);
            table.insert(HitboxParts, HitboxPart)
        end
    end

    local Connection;
    Connection = Humanoid:GetPropertyChangedSignal('Health'):Connect(function()
        if (Humanoid.Health <= 0) then
            Connection:Disconnect()

            task.wait(1)

            for i,v in next, HitboxParts do
                v:Destroy()
                v = nil
            end
            HitboxParts = nil;
        end
    end)

    return Connection;
end

HitboxManager.CreateHitboxForInstance = HitboxModule.new;

return HitboxManager