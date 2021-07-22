local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MainController = Knit.CreateController { Name = "MainController" }

local AnimationFolder = game:GetService("ReplicatedStorage"):WaitForChild('Animations')

local CachedAnimations = {};

function MainController:KnitStart()
    
    local Replicator = Knit.Controllers.Replicator;

    Replicator:AddEvent('Animator', function(Name, State)

        local Character = Knit.Player.Character;
        local Humanoid = Character and Character:FindFirstChildOfClass'Humanoid'
        if (not Humanoid) then
            return;
        end

        local Split = string.split(Name, '/');
        local Folder = AnimationFolder;
        local LastName = '';

        if (#Split > 1) then
            for I = 1, #Split do
                if (I == #Split - 1) then
                    break;
                end;

                local Text = Split[I]
                Folder = Folder:FindFirstChild(Text)
                LastName = Text;
            end
            
            if (not Folder) then
                return warn("Could not find folder '" .. LastName .. "'.")
            end
        end

        LastName = nil;

        local Animation: Animation = Folder:FindFirstChild(Split[#Split]);

        if (not Animation) then
            return warn("Could not find animation '" .. Split[#Split] .. "'.")
        end

        local Animator: Animator = Humanoid:FindFirstChild('Animator');
        local AnimationTrack: AnimationTrack = CachedAnimations[Animation]
        if (not AnimationTrack) then
            AnimationTrack = Animator:LoadAnimation(Animation)
            CachedAnimations[Animation] = AnimationTrack
        end

        local Priority = AnimationTrack.Priority
        if (Animation:FindFirstChild('Priority')) then
            Priority = Enum.AnimationPriority[Animation.Priority.Value];
        end

        AnimationTrack.Priority = Priority

        local Data = Knit.Shared.SharedData
        if (State == Data.AnimationStates.Active) then
            AnimationTrack:Play()
        else
            AnimationTrack:Stop()
        end
    end)

end


return MainController