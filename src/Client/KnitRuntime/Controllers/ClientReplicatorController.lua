local Knit = require(game:GetService("ReplicatedStorage").Knit)

local Replicator = Knit.CreateController { Name = "Replicator" }

function Replicator:AddEvent(Key, Function)
    self.Events[Key] = Function;
end

function Replicator:KnitInit()
    self.Events = {};
    local Event = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Replicator")
    
    Event.OnClientEvent:Connect(function(Key, ...)
        local Function = self.Events[Key]
        if (Function) then
            Function(...);
        else
           warn('Error! Failed to call client function: ' .. tostring(Key)) 
        end
    end)
end


return Replicator