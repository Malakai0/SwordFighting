local Welding = {}

local EmptyCFrame = CFrame.Angles(0,0,0);

function Welding.WeldParts(Name, Part0, Part1, C0, C1)
    local Motor = Instance.new('Motor6D');
    
    Motor.Name = 'WELD:'..Name;
    Motor.C0 = C0 or EmptyCFrame;
    Motor.C1 = C1 or EmptyCFrame;
    Motor.Part0 = Part0;
    Motor.Part1 = Part1;
    Motor.Parent = Part0;

    return Motor;
end

function Welding.RemoveWeld(Part0, Name)
    local Weld = Welding.FindFirstWeld(Part0, Name)
    if (Weld) then
        Weld:Destroy()
    end
end

function Welding.FindFirstWeld(Parent, Name)
    for _, Weld: Motor6D in next, Parent:GetChildren() do
        local MatchedName = Weld.Name == 'WELD:'..Name;
        if (Weld:IsA('Motor6D') and MatchedName) then
            return Weld;
        end
    end
end

return Welding