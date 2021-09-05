local Knit = require(game:GetService("ReplicatedStorage").Knit)

local GuiController = Knit.CreateController { Name = "GuiController" }

GuiController.Character = nil;
GuiController.PlayerGui = nil;

function GuiController:InitLoadingGui()
    local ClientService = Knit.GetService('ClientService')

    local LoadingGui = self.PlayerGui:WaitForChild'Loading'
    LoadingGui.Enabled = true;

    repeat
        if (ClientService:IsReady()) then
            break
        end

        task.wait(.5)
    until nil
    
    task.wait(1)

    LoadingGui.LoadingPhase.Visible = false;

    task.wait(1)

    LoadingGui.Enabled = false;
    LoadingGui.LoadingPhase.Visible = true; --// Just for tidy-ness sake.
end

function GuiController:UpdateHealthGui(Humanoid, Gui)
    local Fraction = (Humanoid.Health / Humanoid.MaxHealth)
    Gui.Bar:TweenSize(UDim2.new(Fraction, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5)
    Gui.Indicator.Text = string.format('%.1f', Fraction*100) .. '%';

    return true;
end

function GuiController:UpdateStaminaGui(Gui)
    local MainController = Knit.Controllers.MainController;
    if (not MainController.ClientCharacterState) then
        return false
    end

    local Fraction = (MainController.ClientCharacterState.Stamina / 100);
    Gui.Bar:TweenSize(UDim2.new(Fraction, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5)
    Gui.Indicator.Text = string.format('%.1f', Fraction*100) .. '%';

    return true;
end

function GuiController:InitPlayerStateGui()

    local PlayerGui = self.PlayerGui;
    local PlayerState = PlayerGui:WaitForChild'PlayerState';

    local Health, Stamina = PlayerState:WaitForChild'Health', PlayerState:WaitForChild'Stamina';

    --// Health.
    local Humanoid = self.Character:WaitForChild'Humanoid';

    if (not Humanoid) then
        return warn('Failed to find Humanoid, cannot update Player State GUI.')
    end

    self:UpdateHealthGui(Humanoid, Health);

    --// Stamina.
    self:UpdateStaminaGui(Stamina)

    --// GUI updater :^)
    self.PlayerStateUpdater = game:GetService("RunService").Heartbeat:Connect(function()
        if (not Humanoid or not Stamina or not Health) then
            return self.PlayerStateUpdater:Disconnect()
        end

        local Success = self:UpdateStaminaGui(Stamina) and self:UpdateHealthGui(Humanoid, Health);

        if (not Success) then
            return self.PlayerStateUpdater:Disconnect();
        end
    end)

end

function GuiController:KnitStart()

    self.Character = Knit.Player.Character or Knit.Player.CharacterAdded:Wait()
    self.PlayerGui = Knit.Player:WaitForChild'PlayerGui';

    Knit.Player.CharacterAdded:Connect(function(Character)
        if (self.PlayerStateUpdater) then
            self.PlayerStateUpdater:Disconnect();
        end

        self.Character = Character;
        self.PlayerGui = Knit.Player:WaitForChild'PlayerGui';

        self:InitPlayerStateGui()
    end);

    task.spawn(function() self:InitLoadingGui() end)
    self:InitPlayerStateGui()

end

return GuiController