local Knit = require(game:GetService("ReplicatedStorage").Knit)

--// Acts as a gateway for client events.
local ReplicatorService = Knit.CreateService {
    Name = "ReplicatorService";
    Client = {};
}

local Event: RemoteEvent = game:GetService("ReplicatedStorage").Replicator;

function ReplicatorService:FireOnServer(Client, Key, ...)
    local Func = Knit.Shared.ClientFunctions[Key];
    if (Func) then
        Func(Client, ...);
    end
end

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
        if (Client.Parent == workspace.Entities.NPCs and Knit.Shared.ClientFunctions[Key]) then
            return Knit.Shared.ClientFunctions[Key](Client, ...);
        end
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

--// Sprint Updater
Generate('UpdateSprinting')

return ReplicatorService