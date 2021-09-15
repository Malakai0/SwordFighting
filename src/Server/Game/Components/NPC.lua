local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Janitor = require(Knit.Util.Janitor)

local NPCPrefabs = game:GetService("ServerStorage").NPCs

local NPC = {}
NPC.__index = NPC

NPC.Tag = "NPC"


function NPC.new(instance)
    local self = setmetatable({
        RespawnTime = 5;
        InitialPosition = CFrame.new();
    }, NPC)
    self._janitor = Janitor.new()
    return self
end

function NPC:SetupModel()
    self.Instance:SetAttribute('UID', game:GetService("HttpService"):GenerateGUID())
    self.Instance:SetAttribute('NPC', true)

    Knit.Modules.HitboxManager.ApplyHitboxToCharacter(self.Instance)
end

function NPC:Update()
    --// Respawning

    if (not self.Instance) then return end;

    local Humanoid = self.Instance:FindFirstChild('Humanoid')
    if (not Humanoid) then return end;

    if (Humanoid.Health <= 0) then --// Respawning.
        if (not self.DiedAt) then
            --// NPC dead!
            self.DiedAt = tick();
            return;
        end;

        if (tick() - self.DiedAt < self.RespawnTime) then return end;
        if (self.Respawning) then return end;
        
        --// Respawn NPC.

        self.Respawning = true;

        local NewModel = NPCPrefabs:FindFirstChild(self.Instance:GetAttribute('NPCType') or 'N/A'):Clone();
        NewModel:WaitForChild'Humanoid'.Health = NewModel.Humanoid.MaxHealth;
        
        NewModel.Parent = workspace.Entities.NPCs;
        self.Instance:Destroy();

        self.Instance = NewModel;
        NewModel:SetPrimaryPartCFrame(self.InitialPosition);

        self.Respawning = false;
        return;
    end;

    if (not self.Sword.Equipped) then
        self.Sword:Equip()
        return;
    end

    if (not self.LastSlashed) then
        self.LastSlashed = tick();
    end

    if (tick() - self.LastSlashed > 1) then
        self.LastSlashed = tick()
        self.Sword:NormalAttack(); --// Awesome!
    end
end

function NPC:Init()
    while true do
        if (self.Instance:IsDescendantOf(workspace) and self.Instance:FindFirstChild('Humanoid')) then
            break;
        end

        workspace.ChildAdded:Wait();
    end

    self:SetupModel();

    self.SwordModel = Knit.Services.SwordService:GiveSwordToNPC(self.Instance);
    self.Sword = Knit.Services.SwordService:FromInstance(self.SwordModel);

    task.wait(.5);

    self.InitialPosition = self.Instance:GetPrimaryPartCFrame();

    self._janitor:Add(game:GetService("RunService").Heartbeat:Connect(function()
        self:Update();
    end), 'Disconnect');
end


function NPC:Deinit()
end


function NPC:Destroy()
    self._janitor:Cleanup()
end


return NPC