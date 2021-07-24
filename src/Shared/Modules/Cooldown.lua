local Cooldown = {}

if (not shared.Cooldowns) then
    shared.Cooldowns = {}
    game:GetService("RunService").Heartbeat:Connect(function()
        for i,v in next, shared.Cooldowns do
            if (not type(v) == 'number') then
                shared.Cooldowns[i] = nil;
                v = nil
                i = nil
                continue
            end
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

function Cooldown:Wait(s)
    local Key = game:GetService("HttpService"):GenerateGUID()
    self:Set(Key, s);
    repeat game:GetService('RunService').Heartbeat:Wait() until (not self:Working(Key))
end

return Cooldown