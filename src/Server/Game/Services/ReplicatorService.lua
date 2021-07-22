local Knit = require(game:GetService("ReplicatedStorage").Knit)

--// Acts as a gateway for client events.
local ReplicatorService = Knit.CreateService {
    Name = "ReplicatorService";
    Client = {};
}

local Event: RemoteEvent = game:GetService("ReplicatedStorage").Replicator;

--// Base functions
function ReplicatorService:Fire(Client, Key, ...)
    Event:FireClient(Client, Key, ...)
end

function ReplicatorService:FireAll(Key, ...)
    Event:FireAllClients(Key, ...)
end

--// Custom functions
function ReplicatorService:Animate(Client, AnimationName, State)
    self:Fire(Client, 'Animator', AnimationName, State);
end

function ReplicatorService:AnimateAll(AnimationName, State)
    self:FireAll('Animator', AnimationName, State);
end

return ReplicatorService