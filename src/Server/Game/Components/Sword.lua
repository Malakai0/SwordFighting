local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Janitor = require(Knit.Util.Janitor)
local Signal = require(Knit.Util.Signal);

local function GrabModules()
    return Knit.Services.ReplicatorService,
           Knit.Shared.SharedData,
           Knit.Shared.Welding,
           Knit.Modules.HitboxManager
end

local function FramesToSeconds(n)
    return (1/60) * n
end

local function WaitFrames(n)
    return Knit.Shared.Cooldown:Wait(FramesToSeconds(n))
end

local Sword = {}
Sword.__index = Sword

Sword.Tag = "Sword"

local SwordSlashTimings = {
    Start = {
        10,
        10,
        0
    };

    Stop = {
        15,
        15,
        20
    };
}

function Sword.new()
    local self = setmetatable({
        UID = game:GetService("HttpService"):GenerateGUID();

        CurrentOwner = nil;
        NPC = false;
        Hitbox = nil;
        Equipped = false;

        Active = false;

        Signals = {
            HitStart = Signal.new();
            HitStop = Signal.new();
            OnHit = Signal.new();
        };

        TemporaryMoveInfo = {
            SwingIndex = 1;
            HitCools = {};
        };
    }, Sword)
    self._janitor = Janitor.new()
    return self
end

--// Cool shit

function Sword:NormalAttack(ShouldIgnoreCooldown)
    if (not self:CheckCharacter()) then
        return
    end

    if (not self.Equipped) then
        return
    end

    if (Knit.Shared.Cooldown:Working(self:GetCoolKey('NormalAttack')) and (not ShouldIgnoreCooldown)) then
        return
    end

    Knit.Shared.Cooldown:Set(self:GetCoolKey('NormalAttack'), 1)

    local Replicator, Data, _, _ = GrabModules()

    local SwingIndex = self.TemporaryMoveInfo.SwingIndex;
    Replicator:FireOnServer(self.CurrentOwner, 'Animator', 'Sword/Slash'..SwingIndex, Data.AnimationStates.Active)

    WaitFrames(SwordSlashTimings.Start[SwingIndex]) -- Until actual slash begins

    local FramesToWait = SwordSlashTimings.Stop[SwingIndex];
    local WithCompensationOfAnimation = FramesToWait - (FramesToWait/20);

    local IsNPC = self.NPC ~= nil;

    self.Hitbox:HitStart(IsNPC, 'NormalAttack', FramesToSeconds(WithCompensationOfAnimation))
    self.Signals.HitStart:Fire('NormalAttack')

    local Trail: Trail = self.Instance.Katana.PhysicalHitbox.Trail

    Trail.Enabled = true;

    WaitFrames(WithCompensationOfAnimation) -- How long the slash animation is, with conpensation.

    Trail.Enabled = false;

    self.Hitbox:HitStop()
    self.Signals.HitStop:Fire()

    self.TemporaryMoveInfo.SwingIndex = SwingIndex == 3 and 1 or SwingIndex+1;
end

function Sword:ToggleEquip()
    if (self.Equipped) then
        self:Unequip(true);
    else
        self:Equip(true);
    end
end

function Sword:Equip(playAnimations, ignoreCool)
    if (not self:CheckCharacter()) then
        return
    end;

    if (self.Equipped == true) then
        return
    end

    if (Knit.Shared.Cooldown:Working(self:GetCoolKey('EQUIP')) and (not ignoreCool)) then
        return
    end
    
    self.Equipped = true;

    local Replicator, Data, Welding, _ = GrabModules()

    local Offsets = Data.Offsets;

    local Character = self.NPC or self.CurrentOwner.Character;
    local Torso = Character:FindFirstChild('Torso')
    local RightArm = Character:FindFirstChild('Right Arm')

    if (playAnimations) then
        Replicator:FireOnServer(self.CurrentOwner, 'Animator', 'Sword/Unequip', Data.AnimationStates.Inactive)
        Replicator:FireOnServer(self.CurrentOwner, 'Animator', 'Sword/Equip', Data.AnimationStates.Active)
    end

    WaitFrames(playAnimations and 10 or 0) -- Until hand is on handle.

    Welding.RemoveWeld(self.Instance.Katana.PrimaryPart, 'Sheath');
    Welding.WeldParts('Sheath', Torso, self.Instance.Sheath, Offsets.TorsoSheath)

    Welding.RemoveWeld(Torso, 'Sword')
    Welding.WeldParts('Sword', RightArm, self.Instance.Katana.PrimaryPart, Offsets.RightArmSword)

    Knit.Shared.Cooldown:Set(self:GetCoolKey('EQUIP'), 1)
end

function Sword:Unequip(playAnimations, ignoreCool)
    if (not self:CheckCharacter()) then
        return
    end;

    if (self.Equipped == false) then
        return
    end

    if (Knit.Shared.Cooldown:Working(self:GetCoolKey('EQUIP')) and (not ignoreCool)) then
        return
    end

    self.Equipped = false;

    local Replicator, Data, Welding, _ = GrabModules()

    local Offsets = Data.Offsets;

    local Character = self.NPC or self.CurrentOwner.Character;
    local Torso = Character:FindFirstChild('Torso')
    local RightArm = Character:FindFirstChild('Right Arm')

    if (playAnimations) then
        Replicator:FireOnServer(self.CurrentOwner, 'Animator', 'Sword/Equip', Data.AnimationStates.Inactive)
        Replicator:FireOnServer(self.CurrentOwner, 'Animator', 'Sword/Unequip', Data.AnimationStates.Active)
    end

    WaitFrames(playAnimations and 10 or 0) -- Until sword is in sheath.

    Welding.RemoveWeld(RightArm, 'Sword')
    Welding.WeldParts('Sword', Torso, self.Instance.Katana.PrimaryPart, Offsets.TorsoSword)

    WaitFrames(playAnimations and 0 or 0) -- Until sheath is back to original position.

    Welding.RemoveWeld(Torso, 'Sheath')
    Welding.WeldParts('Sheath', self.Instance.Katana.PrimaryPart, self.Instance.Sheath, Offsets.SwordSheath)

    Knit.Shared.Cooldown:Set(self:GetCoolKey('EQUIP'), 1)
end

--// Back end stuff

function Sword:GetCoolKey(Key)
    return self.UID .. ':' .. tostring(Key)
end

function Sword:GetDamageCoolKey(CharacterModel, Key)
    return string.format("%s:%s:%s", self.UID, CharacterModel:GetAttribute('UID'), Key);
end

function Sword:OnHit(MoveKey: string, HitPart: BasePart)
    local Replicator, Data, _, _ = GrabModules()
    local LimbType = Data.GetLimbTypeFromInstance(HitPart)
    local Damage = LimbType and Data.BaseDamageValues[MoveKey][LimbType]
    if (not Damage) then return end;

    local Humanoid = HitPart.Parent:FindFirstChild('Humanoid')
    if (not Humanoid) then return end;
    if (Humanoid.Health <= 0) then return end;

    local Recipient = Players:GetPlayerFromCharacter(Humanoid.Parent) or Humanoid.Parent;
    local NewHitData = Data.GenerateHitData(MoveKey, self.CurrentOwner, Recipient, Damage);

    local HurtFunc = function(CustomDamage: number)
        Humanoid:TakeDamage(CustomDamage or NewHitData.Damage)

        Replicator:EffectAll(MoveKey, self.CurrentOwner, Recipient, HitPart, CustomDamage or NewHitData.Damage);
    end

    local ServerMove = Knit.Modules.ServerMove;
    local MoveFunction = ServerMove[MoveKey];
    if (MoveFunction) then
        MoveFunction(HurtFunc, self.CurrentOwner, Recipient, NewHitData.Damage)
    else
        HurtFunc()
    end;

    HurtFunc = nil; --// Clear memory.
end

function Sword:CheckCharacter()
    if (not self.CurrentOwner) then
        return false;
    end;

    local Success = true;
    local Character = self.NPC or self.CurrentOwner.Character;

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
    elseif (Character:GetAttribute('NPC') == true) then
        self:SetOwnerId(Character:GetAttribute('UID'));
        self.NPC = Character
    end
end

function Sword:DeinitializeSword(Character)

    if (not Character) then
        return;
    end

    local RightArm = Character:FindFirstChild('Right Arm')
    local Torso = Character:FindFirstChild('Torso')

    self.Instance.Katana.PrimaryPart:SetNetworkOwnershipAuto();

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

    self.NPC = false;
    self.Equipped = false;

    if (self.Hitbox) then
        self.Hitbox:Destroy()
        self.Hitbox = nil;
    end
end

function Sword:InitializeSword()

    if (not self:CheckCharacter()) then
        return;
    end

    if (self.Hitbox) then
        self.Hitbox:Destroy()
        self.Hitbox = nil;
    end

    local Character;

    if (self.NPC) then
        Character = self.NPC
    else
        local Player = self.CurrentOwner
        Character = Player.Character;
    end

    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    local RightArm = Character:FindFirstChild('Right Arm')
    local Torso = Character:FindFirstChild('Torso')

    -- Can't create welds.
    if (not Humanoid or not RightArm or not Torso) or (Humanoid and Humanoid.Health <= 0) then
        return self:SetOwnerId(0)
    end

    self._janitor:Add(Humanoid.Died:Connect(function()
        self:SetOwnerId(0);
    end), 'Disconnect')

    self:Equip(false, true)
    self:Unequip(false, true)

    local _, _, _, HitboxManager = GrabModules()
    self.Hitbox = HitboxManager.CreateHitboxForInstance(self.CurrentOwner, self.Instance.Katana.PhysicalHitbox);

    local ClientService = Knit.Services.ClientService;

    self.Hitbox:OnHit(function(MoveKey, CollidePart, HitCool)
        if (not CollidePart) then return end;

        local CharacterModel = CollidePart.Parent;

        local Player = game:GetService("Players"):GetPlayerFromCharacter(CharacterModel)
        if (Player and ClientService:IsInvincible(Player)) then
            return;
        end

        local Key = self:GetDamageCoolKey(CharacterModel, MoveKey);

        if (Knit.Shared.Cooldown:Working(Key)) then
            return
        end

        Knit.Shared.Cooldown:Set(Key, HitCool);

        self:OnHit(MoveKey, CollidePart);
    end)

    if (not self.NPC) then
        self.Instance.Katana.PrimaryPart:SetNetworkOwner(self.CurrentOwner);
    end

end

function Sword:OwnerChanged()
    local CurrentOwner = self.Instance:GetAttribute("Owner");
    local Player = type(CurrentOwner) == 'number' and Players:GetPlayerByUserId(CurrentOwner)
    
    if (not Player and self.Instance.Parent:GetAttribute('NPC') == true) then
        if (self.Instance.Parent.Humanoid.Health <= 0) then
            return
        end
        self:DetectCharacter()
        Player = self.Instance.Parent;
    end

    if (self.CurrentOwner) then
        self:DeinitializeSword(self.NPC or self.CurrentOwner.Character)
    end

    self.CurrentOwner = Player;

    if (Player) then
        self:InitializeSword()
    end
end

function Sword:Init()
    self:OwnerChanged();
    self:DetectCharacter()

    self._janitor:Add(self.Instance:GetAttributeChangedSignal("Owner"):Connect(function()
        self:OwnerChanged();
    end), 'Disconnect')

    self._janitor:Add(self.Instance:GetPropertyChangedSignal('Parent'):Connect(function()
        self:DetectCharacter()
    end), 'Disconnect')
end


function Sword:Deinit()
end


function Sword:Destroy()
    self._janitor:Cleanup()
    if (self.Hitbox) then
        self.Hitbox:Destroy()
        self.Hitbox = nil;
    end
end


return Sword