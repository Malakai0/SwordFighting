local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Effects = {}

local TweenService = game:GetService("TweenService")
local GlobalInfo = TweenInfo.new(.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

local attackerInfo = function(ProvidedAttacker)
    return {
        Player = ProvidedAttacker;
        NPC = ProvidedAttacker.Parent == workspace.Entities.NPCs;
    }
end

local function RandLerp(Min, Max)
    local t = math.random()
    return (1 - t) * Min + t * Max;
end

local function GeneratePositionWithOffset(Position: CFrame, MinOffset: CFrame, MaxOffset: CFrame)
    local MiO, MaO = MinOffset, (MaxOffset) or (-MinOffset);
    return CFrame.new(RandLerp(MiO.X, MaO.X), RandLerp(MiO.Y, MaO.Y), RandLerp(MiO.Z, MaO.Z))
end

function Effects.DamageIndicator(MoveKey, Part, Damage)
    local WasCritical = Damage >= Knit.Shared.SharedData.BaseDamageValues[MoveKey].CriticalDamage
    
    local BillboardGui = Instance.new('BillboardGui')
    BillboardGui.Name = Part.Name;
    BillboardGui.AlwaysOnTop = true;
    BillboardGui.Size = UDim2.new(1, 0, 1, 0);

    local TextLabel = Instance.new('TextLabel')
    TextLabel.TextColor3 = WasCritical and Color3.fromRGB(214, 212, 78) or Color3.fromRGB(255, 50, 50)
    TextLabel.Text = Damage .. (WasCritical and '!' or '');
    TextLabel.Position = UDim2.new(0,0,0,0)
    TextLabel.Size = UDim2.new(1,0,1,0)
    TextLabel.BorderSizePixel = 0;
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.Parent = BillboardGui

    local Head = Part.Parent.Head;
    local MinOffset, MaxOffset = CFrame.new(-3,0,0), CFrame.new(3,1,0);

    local Position = GeneratePositionWithOffset(Head.CFrame, MinOffset, MaxOffset)
    BillboardGui.StudsOffsetWorldSpace = Vector3.new(Position.X, Position.Y, Position.Z);

    local Tween = TweenService:Create(BillboardGui, GlobalInfo, {
        StudsOffsetWorldSpace = BillboardGui.StudsOffsetWorldSpace + Vector3.new(0, 3, 0);
    })

    local Tween2 = TweenService:Create(TextLabel, GlobalInfo, {
        TextTransparency = 1;
    })

    Tween.Completed:Connect(function()
        delay(.25, function()
            BillboardGui:Destroy()
        end)
    end)

    BillboardGui.Parent = Part;

    Tween:Play()
    Tween2:Play();
end

function Effects.NormalAttack(Attacker, Recipient, PartHit, Damage)
    Effects.DamageIndicator('NormalAttack', PartHit, Damage);
end

function Effects.DoEffect(Name, A, R, ...)
    return Effects[Name](attackerInfo(A), attackerInfo(R), ...);
end

return Effects