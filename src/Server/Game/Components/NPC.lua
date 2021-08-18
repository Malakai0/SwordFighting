local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)

local Component = require(Knit.Util.Component);

local NPC = {}
NPC.__index = NPC

NPC.Tag = "NPC"


function NPC.new(instance)
    local self = setmetatable({
        
    }, NPC)
    self._maid = Maid.new()
    return self
end

function NPC:Update()
    
end

function NPC:Init()

    self._maid:GiveTask(self.Instance.Humanoid.Died:Connect(function()
        self.Instance:SetAttribute('UID', nil)
        self.Instance:SetAttribute('NPC', false)
        self:Destroy()
    end))

    self.Instance:SetAttribute('UID', game:GetService("HttpService"):GenerateGUID())
    self.Instance:SetAttribute('NPC', true)

    Knit.Modules.HitboxManager.ApplyHitboxToCharacter(self.Instance)

    self._maid:GiveTask(game:GetService("RunService").Heartbeat:Connect(function()
        self:Update()
    end))
end


function NPC:Deinit()
end


function NPC:Destroy()
    self._maid:Destroy()
end


return NPC