local NPCSpawn = {}
NPCSpawn.__index = NPCSpawn

NPCSpawn.Tag = "NPCSpawn"

local NPCPrefabs = game:GetService("ServerStorage").NPCs

function NPCSpawn.new(instance)
    local self = setmetatable({

    }, NPCSpawn)
    return self
end

function NPCSpawn:Init()
    self.Instance.Transparency = 1;
    
    local NPCType = self.Instance:GetAttribute('NPCType');
    local Model = NPCPrefabs:FindFirstChild(NPCType or 'N/A'):Clone();

    Model.Parent = workspace.Entities.NPCs;

    Model:SetPrimaryPartCFrame(self.Instance.CFrame)

    self.Model = Model;
end

function NPCSpawn:Destroy()

end

return NPCSpawn