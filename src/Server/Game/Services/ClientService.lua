local Knit = require(game:GetService("ReplicatedStorage").Knit)

--// Acts as a gateway for client events.
local ClientService = Knit.CreateService {
    Name = "ClientService";
    Client = {};
}

ClientService.READY_FOR_CLIENTS = false;

ClientService.CharacterStates, ClientService.ClientStates = {}, {};

function ClientService:CharacterAdded(Character: Model)
    repeat wait() until Character:IsDescendantOf(workspace) and Character:FindFirstChild('Torso') and Character:FindFirstChild('Right Arm')

    local Player = game:GetService("Players"):GetPlayerFromCharacter(Character);

    self.CharacterStates[Player] = Knit.Shared.CharacterState.new(Character);

    Character:SetAttribute('UID', game:GetService('HttpService'):GenerateGUID())
    Character.Parent = workspace.Entities.Players;

    Knit.Services.SwordService:GiveSword(Player);

    Knit.Modules.HitboxManager.ApplyHitboxToCharacter(Character);

    local Connection;
    Connection = Character:WaitForChild'Humanoid'.Died:Connect(function()
        Connection:Disconnect();

        self.CharacterStates[Player] = nil;
    end)

end

function ClientService:PlayerAdded(Player: Player)

    self.ClientStates[Player] = Knit.Shared.ClientState.new(Player);
    self.ClientStates[Player]:Start();

    self.ClientStates[Player]:SetInvincible(true);

    task.delay(2, function()
        if (self.ClientStates[Player]) then
            self.ClientStates[Player]:SetInvincible(false);
        end
    end)

    local Character = Player.Character or Player.CharacterAdded:Wait()
    self:CharacterAdded(Character)
    Player.CharacterAdded:Connect(function(...)
        self:CharacterAdded(...);
    end);
end

function ClientService:PlayerRemoving(Player: Player)
    if (self.CharacterStates[Player]) then
        self.CharacterStates[Player] = nil;
    end

    if (self.ClientStates[Player]) then
        self.ClientStates[Player]:Stop();
        self.ClientStates[Player] = nil;
    end
end

function ClientService:IsInvincible(Player: Player)
    if (not self.ClientStates[Player]) then
        return false;
    end
    
    return self.ClientStates[Player].Invincible;
end

function ClientService:KnitStart()

    game:GetService("RunService").Heartbeat:Connect(function()
        for I,V in next, self.ClientStates do
            task.spawn(V.Update, V);
        end

        for I,V in next, self.CharacterStates do
            task.spawn(V.Update, V);
        end
    end)

    for i,v in next, game:GetService('Players'):GetPlayers() do
        self:PlayerAdded(v)
    end

    game:GetService('Players').PlayerAdded:Connect(function(...)
        self:PlayerAdded(...)
    end)

    game:GetService'Players'.PlayerRemoving:Connect(function(...)
        self:PlayerRemoving(...)
    end)

    print('Ready for clients!')
    ClientService.READY_FOR_CLIENTS = true;
end

function ClientService.Client:SetSprinting(Player: Player, ShouldSprint: boolean)
    if (type(ShouldSprint) ~= 'boolean') then
        return;
    end

    if (self.Server.CharacterStates[Player]) then
        return self.Server.CharacterStates[Player]:SetSprinting(ShouldSprint)
    end
end

function ClientService.Client:IsReady()
    return ClientService.READY_FOR_CLIENTS;
end

return ClientService