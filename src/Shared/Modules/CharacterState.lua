local Knit = require(game:GetService("ReplicatedStorage").Knit)

local CharState = {}
CharState.__index = CharState

local SPRINT_TIME = 15; --// In seconds, of course.
local SPRINT_INCREMENT = 0.2 + (1.8 * math.random()); --// Make increment random, cause why not?
local SPRINT_UPDATE_FREQUENCY = SPRINT_TIME / (100 / SPRINT_INCREMENT); --// Interval of time to update the stamina.

CharState.WALK_SPEED = 16;
CharState.SPRINT_SPEED = 22;
CharState.MIN_VAL = 10;

function CharState.new(Character: Model)
    if (not Character or (not Character:WaitForChild'Humanoid')) then return end;

    return setmetatable({
        Character = Character;
        Stamina = 100;
        EquippedWeapon = "NULL";
        IsSprinting = false;
        LastUpdatedStamina = 0;
        StoppedSprinting = 0;
    }, CharState)
end

function CharState:Update()
    local CanUpdate = tick() - self.LastUpdatedStamina >= SPRINT_UPDATE_FREQUENCY;
    local Sprinting = self.IsSprinting;
    local ShouldRecoverStamina = not Sprinting and tick() - self.StoppedSprinting >= 2;

    local StaminaChange = 0;

    if (self.Stamina <= .2) then
        self.Stamina = 0;
        self:SetSprinting(false)
    end

    if (CanUpdate) then
        StaminaChange = ShouldRecoverStamina and SPRINT_INCREMENT or Sprinting and -SPRINT_INCREMENT or 0
        self.LastUpdatedStamina = tick();
    end

    local Humanoid: Humanoid = self.Character and self.Character:FindFirstChild'Humanoid'
    if (Humanoid and Humanoid.Health > 0 and game:GetService'RunService':IsServer()) then
        Humanoid.WalkSpeed = self.IsSprinting and CharState.SPRINT_SPEED or CharState.WALK_SPEED;
    end

    self.Stamina = math.clamp(self.Stamina + StaminaChange, 0, 100);
end

function CharState:SetSprinting(sprintingVal: boolean)

    local Humanoid: Humanoid = self.Character and self.Character:FindFirstChild'Humanoid'
    if (not Humanoid) then
        return
    end

    if (sprintingVal and (self.Stamina <= CharState.MIN_VAL or Humanoid.Health <= 0)) then
        return false;
    end

    if (not sprintingVal and self.IsSprinting) then
        --print(self.StartedSprinting - tick())
        self.StoppedSprinting = tick();
    end

    self.IsSprinting = not (not sprintingVal); --// So we get a boolean, just to be neat :^).

    local Player = game:GetService("Players"):GetPlayerFromCharacter(self.Character)
    if (game:GetService'RunService':IsServer() and Player) then
        Knit.Services.ReplicatorService:UpdateSprinting(Player, self.IsSprinting, self.Stamina);
    end

    if (self.IsSprinting) then
        self.StartedSprinting = tick()
    end

    return true;
end

return CharState;