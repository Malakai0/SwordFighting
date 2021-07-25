local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MainController = Knit.CreateController { Name = "MainController" }

function MainController:KnitStart()
    
    local Replicator = Knit.Controllers.Replicator;

    Replicator:AddEvent('Animator', function(Name, State)
        Knit.Shared.ClientFunctions.Animator(Knit.Player.Character, Name, State);
    end)

    --MoveKey, self.CurrentOwner, Recipient, HitPart, newHitData.Damage
    Replicator:AddEvent('Effect', function(MoveKey, Attacker, Recipient, HitPart, Damage)
        Knit.Modules.Effects.DoEffect(MoveKey, Attacker, Recipient, HitPart, Damage)
    end)

end


return MainController