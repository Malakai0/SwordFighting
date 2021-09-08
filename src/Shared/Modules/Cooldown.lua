local Cooldown = {}

--// Using a shared table cause this is a module.
if (not shared.Cooldowns) then
    shared.Cooldowns = setmetatable({}, {__mode = "v"});

    game:GetService("RunService").Heartbeat:Connect(function()
        for i,v in next, shared.Cooldowns do
            if (not type(v) == 'number') then
                shared.Cooldowns[i] = nil;
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

--- Returns true if the cooldown `Key` is currently active/working.
---@param Key string
---@return boolean
function Cooldown:Working(Key: string)
    return shared.Cooldowns[tostring(Key)] ~= nil;
end

--- Sets cooldown `Key` to last `Seconds` seconds.
---@param Key string
---@param Seconds number
---@return nil
function Cooldown:Set(Key: string, Seconds: number)
    shared.Cooldowns[tostring(Key)] = tick() + Seconds;
end

--- Forces cooldown `Key` to stop working.
---@param Key string
---@return nil
function Cooldown:ForceRemove(Key: string)
    shared.Cooldowns[tostring(Key)] = nil;
end

--- Generates a cooldown to wait `Seconds` seconds. Not really applicable anywhere; use `task.wait()`.
---@param Seconds number
---@return nil
function Cooldown:Wait(Seconds: number)
    local Key = game:GetService("HttpService"):GenerateGUID()
    self:Set(Key, Seconds);
    repeat task.wait() until (not self:Working(Key))
end

return Cooldown