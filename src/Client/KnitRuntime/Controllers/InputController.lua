local Knit = require(game:GetService("ReplicatedStorage").Knit)

local InputController = Knit.CreateController { Name = "InputController" }

local UIS = game:GetService("UserInputService")

function InputController:GrabInput(Key: InputObject)
    local Code, Type = Key.KeyCode, Key.UserInputType
    if (Type == Enum.UserInputType.MouseButton1) then
        return 'LMB'
    elseif (Type == Enum.UserInputType.MouseButton2) then
        return 'RMB'
    elseif (Type == Enum.UserInputType.MouseButton3) then
        return 'MMB';
    elseif (Type == Enum.UserInputType.Keyboard or tostring(Type):find('Gamepad')) then
        return (tostring(Code):sub(#"Enum.KeyCode."+1));
    elseif (Type == Enum.UserInputType.MouseMovement) then
        return 'MouseMovement';
    end
end

function InputController:CheckInput(Key: InputObject, Expected)
    local Code, Type = Key.KeyCode, Key.UserInputType
    if (Type == Enum.UserInputType.MouseButton1) then
        return Expected == 'LMB' or Expected == Type;
    elseif (Type == Enum.UserInputType.MouseButton2) then
        return Expected == 'RMB' or Expected == Type;
    elseif (Type == Enum.UserInputType.MouseButton3) then
        return Expected == 'MMB' or Expected == Type;
    elseif (Type == Enum.UserInputType.Keyboard or tostring(Type):find('Gamepad')) then
        return Expected == Code or (Expected:upper() == tostring(Code):sub(#"Enum.KeyCode."+1));
    elseif (Type == Enum.UserInputType.MouseMovement) then
        return Expected == Type or Expected == 'MouseMovement';
    end
end

function InputController:Began(Function)
    return UIS.InputBegan:Connect(function(Key, IC)
        if (IC) then return end;

        Function(Key);
    end);
end

function InputController:Ended(Function)
    return UIS.InputEnded:Connect(function(Key, IC)
        if (IC) then return end;

        Function(Key);
    end);
end

function InputController:Changed(Function)
    return UIS.InputChanged:Connect(function(Key, IC)
        if (IC) then return end;

        Function(Key);
    end);
end


return InputController