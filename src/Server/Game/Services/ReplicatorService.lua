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

local function Generate(Key, ClientKey)
    ClientKey = ClientKey or Key;
    ReplicatorService[Key] = function(self, Client, ...)
        self:Fire(Client, ClientKey, ...);
    end

    ReplicatorService[Key .. 'All'] = function(self, ...)
        self:FireAll(ClientKey, ...)
    end
end

--// Animate
Generate('Animate', 'Animator');

--// Client Effects
Generate('Effect');

return ReplicatorService