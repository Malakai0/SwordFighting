local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)

local function GrabModules()
    return Knit.Services.ReplicatorService,
           Knit.Shared.SharedData,
           Knit.Shared.Welding,
           Knit.Modules.HitboxManager
end

local function waitFrames(n)
    return wait((1/60)*n)
end

local Sword = {}
Sword.__index = Sword

Sword.Tag = "Sword"


function Sword.new(instance)
    local self = setmetatable({
        CurrentOwner = nil;
        Hitbox = nil;
        Equipped = false;

        TemporaryMoveInfo = {
            SwingIndex = 0;
        };
    }, Sword)
    self._maid = Maid.new()
    return self
end

--// Cool shit

function Sword:NormalAttack()
    if (not self:CheckCharacter()) then
        return
    end

    if (not self.Equipped) then
        return
    end

    if (Knit.Shared.Cooldown:Working(self:GetCoolKey('NormalAttack'))) then
        return
    end

    Knit.Shared.Cooldown:Set(self:GetCoolKey('NormalAttack'), 1)

    local Replicator, Data, _, _ = GrabModules()

    Replicator:Animate(self.CurrentOwner, 'Sword/Slash', Data.AnimationStates.Active)

    waitFrames(11) -- Until actual slash begins

    self.Hitbox:HitStart('NormalAttack')

    waitFrames(10) -- How long the slash is

    self.Hitbox:HitStop()
end

function Sword:ToggleEquip()
    if (self.Equipped) then
        self:Unequip(true);
    else
        self:Equip(true);
    end
end

function Sword:Equip(playAnimations)
    if (not self:CheckCharacter()) then
        return
    end;

    if (self.Equipped == true) then
        return
    end

    if (Knit.Shared.Cooldown:Working('EQUIP')) then
        return
    end

    Knit.Shared.Cooldown:Set(self:GetCoolKey('EQUIP'), 1)
    
    self.Equipped = true;

    local Replicator, Data, Welding, _ = GrabModules()

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

    if (Knit.Shared.Cooldown:Working('EQUIP')) then
        return
    end

    Knit.Shared.Cooldown:Set(self:GetCoolKey('EQUIP'), 1)

    self.Equipped = false;

    local Replicator, Data, Welding, _ = GrabModules()

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

function Sword:GetCoolKey(Key)
    if not self.CurrentOwner then return end;
    return self.CurrentOwner.UserId .. ':' .. tostring(Key)
end

function Sword:OnHit(MoveKey: string, HitPart: BasePart, Humanoid: Humanoid, Group: string)

    local IsHitbox = HitPart:GetAttribute('Hitbox') == true;
    if (not IsHitbox) then return end;

    local Replicator, Data, _, _ = GrabModules()
    local LimbType = Data.GetLimbTypeFromInstance(HitPart)
    local Damage = LimbType and Data.BaseDamageValues[MoveKey][LimbType]
    if (not Damage) then return end;

    local Recipient = Players:GetPlayerFromCharacter(Humanoid.Parent) or Humanoid.Parent;
    local newHitData = Data.GenerateHitData(MoveKey, self.CurrentOwner, Recipient, Damage);

    local HurtFunc = function()
        Humanoid:TakeDamage(newHitData.Damage)

        Replicator:EffectAll(MoveKey, self.CurrentOwner, Recipient, HitPart, newHitData.Damage);
    end

    local ServerMove = Knit.Modules.ServerMove;
    if (ServerMove[MoveKey]) then
        ServerMove[MoveKey](HurtFunc, self.CurrentOwner, Recipient, newHitData.Damage)
    else
        HurtFunc()
    end;

    HurtFunc = nil;
end

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

    self.Instance.Katana.Hitbox:SetNetworkOwnershipAuto();

    -- Welds broken already.
    if (not RightArm or not Torso) then
        return;
    end
    
    --// Attempt to remove all possible welds.
    --// If this gets big I'll make it more neat.
    local _, _, Welding, _ = GrabModules()
    Welding.RemoveWeld(Torso, 'Sheath')
    Welding.RemoveWeld(Torso, 'Sword')
    Welding.RemoveWeld(RightArm, 'Hitbox')
end

function Sword:InitializeSword()

    if (not self:CheckCharacter()) then
        return;
    end

    if (self.Hitbox) then
        self.Hitbox:Destroy()
        self.Hitbox = nil;
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

    self:Equip(false)
    self:Unequip(false)

    local _,_,_,HitboxManager = GrabModules()
    self.Hitbox = HitboxManager.CreateHitboxForInstance(self.Instance.Katana.Hitbox);

    self.Hitbox:OnHit(function(...)
        self:OnHit(...);
    end)

    self.Instance.Katana.Hitbox:SetNetworkOwner(self.CurrentOwner);

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
    if (self.Hitbox) then
        self.Hitbox:Destroy()
        self.Hitbox = nil;
    end
end


return Sword