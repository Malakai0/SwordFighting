local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MainController = Knit.CreateController { Name = "MainController" }

local SPRINT_KEY = 'LeftControl'

function MainController:KnitStart()

    local Replicator = Knit.Controllers.Replicator;
    local InputController = Knit.Controllers.InputController;
    local CharacterState = Knit.Shared.CharacterState;

    local ClientService = Knit.GetService('ClientService');

    Replicator:AddEvent('Animator', function(Name, State)
        Knit.Shared.ClientFunctions.Animator(Knit.Player.Character, Name, State);
    end)

    Replicator:AddEvent('Effect', function(MoveKey, Attacker, Recipient, HitPart, Damage)
        Knit.Modules.Effects.DoEffect(MoveKey, Attacker, Recipient, HitPart, Damage)
    end)

    --// Character stuff.
    --// We hold a client-sided character state for GUI updates.
    local Character = Knit.Player.Character or Knit.Player.CharacterAdded:Wait()
    MainController.ClientCharacterState = CharacterState.new(Character);

    Knit.Player.CharacterAdded:Connect(function(Character)
        MainController.ClientCharacterState = CharacterState.new(Character);
    end)

    InputController:Began(function(Key)

        if (InputController:GrabInput(Key) == SPRINT_KEY and Knit.Player.Character and MainController.ClientCharacterState) then
            if (MainController.ClientCharacterState.Stamina >= CharacterState.MIN_VAL) then
                ClientService:SetSprinting(true)
            end
        end

    end)

    InputController:Ended(function(Key)
        
        if (InputController:GrabInput(Key) == SPRINT_KEY and Knit.Player.Character and MainController.ClientCharacterState) then
            ClientService:SetSprinting(false)
        end

    end)

    Replicator:AddEvent('UpdateSprinting', function(Value, Stamina)
        if (MainController.ClientCharacterState) then
            MainController.ClientCharacterState.Stamina = Stamina;
            MainController.ClientCharacterState:SetSprinting(Value)
        end
    end)

    game:GetService("RunService").Heartbeat:Connect(function()
        if (MainController.ClientCharacterState) then
            MainController.ClientCharacterState:Update()
        end
    end)

end


return MainController