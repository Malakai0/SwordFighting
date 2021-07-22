local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)

local function GrabModules()
    return Knit.Services.ReplicatorService,
           Knit.Shared.SharedData,
           Knit.Shared.Welding
end

local Sword = {}
Sword.__index = Sword

Sword.Tag = "Sword"


function Sword.new(instance)
    local self = setmetatable({
        CurrentOwner = nil;
        Equipped = false;
    }, Sword)
    self._maid = Maid.new()
    return self
end

--// Cool shit

function Sword:NormalAttack()
    -- TODO.
end

function Sword:Equip(playAnimations)
    if (not self:CheckCharacter()) then
        return
    end;

    if (self.Equipped == true) then
        return
    end
    
    self.Equipped = true;

    local Replicator, Data, Welding = GrabModules()

    local Offsets = Data.Offsets;

    local Character = self.CurrentOwner.Character;
    local Torso = Character:FindFirstChild('Torso')
    local RightArm = Character:FindFirstChild('Right Arm')

    if (playAnimations) then
        Replicator:Animate(self.CurrentOwner, 'Sword/Unequip', Data.AnimationStates.Inactive)
        Replicator:Animate(self.CurrentOwner, 'Sword/Equip', Data.AnimationStates.Active)
    end

    wait(playAnimations and 0 or 0) -- Until hand is on handle.

    Welding.RemoveWeld(self.Instance.Katana.Hitbox, 'Sheath');
    Welding.WeldParts('Sheath', Torso, self.Instance.Sheath, Offsets.TorsoSheath)

    Welding.RemoveWeld(Torso, 'Sword')
    Welding.WeldParts('Sword', RightArm, self.Instance.Katana.Hitbox, Offsets.RightArmSword)
end

function Sword:Unequip(playAnimations)
    if (not self:CheckCharacter()) then
        return
    end;

    if (self.Equipped == false) then
        return
    end

    self.Equipped = false;

    local Replicator, Data, Welding = GrabModules()

    local Offsets = Data.Offsets;

    local Character = self.CurrentOwner.Character;
    local Torso = Character:FindFirstChild('Torso')
    local RightArm = Character:FindFirstChild('Right Arm')

    if (playAnimations) then
        Replicator:Animate(self.CurrentOwner, 'Sword/Equip', Data.AnimationStates.Inactive)
        Replicator:Animate(self.CurrentOwner, 'Sword/Unequip', Data.AnimationStates.Active)
    end

    wait(playAnimations and 0 or 0) -- Until sword is in sheath.

    Welding.RemoveWeld(RightArm, 'Sword')
    Welding.WeldParts('Sword', Torso, self.Instance.Katana.Hitbox, Offsets.TorsoSword)

    wait(playAnimations and 0 or 0) -- Until sheath is back to original position.

    Welding.RemoveWeld(Torso, 'Sheath')
    Welding.WeldParts('Sheath', self.Instance.Katana.Hitbox, self.Instance.Sheath, Offsets.SwordSheath)
end

--// Back end stuff

function Sword:CheckCharacter()
    if (not self.CurrentOwner) then
        return false;
    end;

    local Success = true;
    local Character = self.CurrentOwner.Character;

    if (not Character) then
        self:SetOwnerId(0);
        Success = false;
    else
        local RightArm = Character:FindFirstChild('Right Arm')
        local Torso = Character:FindFirstChild('Torso')

        if (not RightArm or not Torso) then
            self:SetOwnerId(0);
        end
    end

    return Success;
end

function Sword:SetOwnerId(Id)
    self.Instance:SetAttribute('Owner', Id)
end

function Sword:GetOwnerId()
    return self.Instance:GetAttribute('Owner');
end

function Sword:DetectCharacter()
    local Character = self.Instance.Parent;
    if (not Character) then
        return
    end

    local Player = Players:GetPlayerFromCharacter(Character)
    if (Player) then
        self:SetOwnerId(Player.UserId)
    end
end

function Sword:DeinitializeSword(Player: Player)

    if (not Player.Character) then
        return;
    end

    local Character = Player.Character;
    local RightArm = Character:FindFirstChild('Right Arm')
    local Torso = Character:FindFirstChild('Torso')

    -- Welds broken already.
    if (not RightArm or not Torso) then
        return;
    end
    
    --// Attempt to remove all possible welds.
    --// If this gets big I'll make it more neat.
    local _, _, Welding = GrabModules()
    Welding.RemoveWeld(Torso, 'Sheath')
    Welding.RemoveWeld(Torso, 'Sword')
    Welding.RemoveWeld(RightArm, 'Hitbox')
end

function Sword:InitializeSword()

    if (not self:CheckCharacter()) then
        return;
    end

    local Player = self.CurrentOwner

    local Character = Player.Character;
    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    local RightArm = Character:FindFirstChild('Right Arm')
    local Torso = Character:FindFirstChild('Torso')

    -- Can't create welds.
    if (not Humanoid or not RightArm or not Torso) or (Humanoid and Humanoid.Health <= 0) then
        return self:SetOwnerId(0)
    end

    self._maid:GiveTask(Humanoid.Died:Connect(function()
        self:SetOwnerId(0);
    end))

    self:Unequip(false)
end

function Sword:OwnerChanged()
    local CurrentOwner = self.Instance:GetAttribute("Owner");
    local Player = Players:GetPlayerByUserId(CurrentOwner)

    if (self.CurrentOwner) then
        self:DeinitializeSword(self.CurrentOwner)
    end

    self.CurrentOwner = Player;

    if (Player) then
        self:InitializeSword()
    end
end

function Sword:Init()
    self:OwnerChanged();
    self:DetectCharacter()
    self._maid:GiveTask(self.Instance:GetAttributeChangedSignal("Owner"):Connect(function()
        self:OwnerChanged();
    end))
    self._maid:GiveTask(self.Instance:GetPropertyChangedSignal('Parent'):Connect(function()
        self:DetectCharacter()
    end))
end


function Sword:Deinit()
end


function Sword:Destroy()
    self._maid:Destroy()
end


return Sword