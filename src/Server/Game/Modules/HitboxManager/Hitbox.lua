-- Hitbox module

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid);

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Mechanism: Instance, DetectionMode: number)

    local RaycastHitbox = Knit.Shared.RaycastHitbox;

    local self = setmetatable({
        MoveKey = nil;
        ID = game:GetService("HttpService"):GenerateGUID();
        Object = RaycastHitbox.new(Mechanism);
        Connections = {};
    }, Hitbox)

    self._maid = Maid.new();

    local DetectionNumber = math.clamp(tonumber(DetectionMode) or 1, 1, 3);
    self.Object.DetectionMode = (DetectionMode and DetectionNumber) or RaycastHitbox.DetectionMode.Default;

    self.Object.OnHit:Connect(function(hitPart, humanoid, _, group)
        local Removed = 0;
        for i,v in next, self.Connections do
            if (type(v.Function) ~= 'function') then
                v.Function = nil;
                v.ID = nil;
                v = nil;
                table.remove(self.Connections, i - Removed);
                Removed += 1;
                continue
            end
            coroutine.wrap(v.Function)(self.MoveKey, hitPart, humanoid, group)
        end
        Removed = nil;
    end)

    self._maid:GiveTask(self.Object.OnHit[1]);

    return self
end

function Hitbox:HitStart(Key, ...)
    self.MoveKey = Key;
    return self.Object:HitStart(...)
end

function Hitbox:HitStop(...)
    self.MoveKey = nil;
    return self.Object:HitStop(...)
end

function Hitbox:OnHit(func)
    assert(type(func) == 'function', "Argument #1 of OnHit must be a function!")

    local ID = game:GetService("HttpService"):GenerateGUID()
    table.insert(self.Connections, {
        Function = func;
        ID = ID;
    })

    return ID;
end

function Hitbox:Disconnect(ID)
    for i,v in next, self.Connections do
        if (v.ID == ID) then
            v.Function = nil;
            v.ID = nil
            v = nil;
            self.Connections[i] = nil;
            i = nil;
        end
    end
end

function Hitbox:Destroy()
    for i,v in next, self.Connections do
        if not (type(v) == 'table') then continue end;
        if (not v.ID) then continue end;
        self:Disconnect(v.ID)
    end
    self._maid:Destroy();
end


return Hitbox