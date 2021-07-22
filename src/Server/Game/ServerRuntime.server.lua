local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component)

Knit.AddServices(script.Parent.Services);

Knit.Modules = {}
for _,v in next, script.Parent.Modules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Modules[v.Name] = require(v)
    end
end;

Knit.Shared = {}
for _,v in next, game:GetService('ReplicatedStorage').Modules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Shared[v.Name] = require(v)
    end
end

local function CharacterAdded(Character: Model)
    repeat wait() until Character:IsDescendantOf(workspace)

    Character.Parent = workspace.Entities;
    local Sword = game:GetService('ServerStorage').Assets.Sword:Clone();
    Sword.Parent = Character;
    Sword:SetAttribute('Owner', game:GetService("Players"):GetPlayerFromCharacter(Character).UserId)
end

local function PlayerAdded(Player: Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    CharacterAdded(Character)
    Player.CharacterAdded:Connect(CharacterAdded);
end

Knit.Start():Then(function()
    print('Server started!')
    Component.Auto(script.Parent.Components)

    print('Server running version ' .. Knit.Shared.ServerInfo.Version);

    for i,v in next, game:GetService('Players'):GetPlayers() do
        PlayerAdded(v)
    end
    game:GetService('Players').PlayerAdded:Connect(PlayerAdded)
end):Catch(warn);