local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MainController = Knit.CreateController { Name = "MainController" }

function MainController:KnitStart()
    
    local Replicator = Knit.Controllers.Replicator;

    Replicator:AddEvent('Animator', function(Name, State)

        local Character = Knit.Player.Character;

        Knit.Shared.ClientFunctions.Animator(Character, Name, State);

    end)

end


return MainController