local Cooldown = {}

shared.Cooldowns = shared.Cooldowns or {}

if (not shared.Cooldowns) then
    game:GetService("RunService").Heartbeat:Connect(function()
        for i,v in next, shared.Cooldowns do
            if (tick() >= v) then
                shared.Cooldowns[i] = nil;
                v = nil;
                i = nil;
            end
        end
    end)
end

function Cooldown:Working(Key)
    return shared.Cooldowns[tostring(Key)] ~= nil;
end

function Cooldown:Set(Key, Seconds)
    shared.Cooldowns[tostring(Key)] = tick() + Seconds;
end

function Cooldown:ForceRemove(Key)
    shared.Cooldowns[tostring(Key)] = nil;
end

return Cooldown