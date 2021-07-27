-- Hitbox module

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid);

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Player: Player, Mechanism: Instance)

    local Cast = Knit.Shared.ClientCast;

    local self = setmetatable({
        MoveKey = nil;
        ID = game:GetService("HttpService"):GenerateGUID();
        Player = Player:IsA('Player') and Player;
        Mechanism = Mechanism;
        Params = RaycastParams.new();
        Connections = {};
    }, Hitbox)

    self._maid = Maid.new();

    return self
end

function Hitbox:HitStart(Key, HitCool, ...)
    local Cast = Knit.Shared.ClientCast;
    self.MoveKey = Key;

    self.Object = Cast.new(self.Mechanism, self.Params)
    if self.Player then
        self.Object:SetOwner(self.Player)
    end

    self.Object.Collided:Connect(function(RaycastResult)
        local hitPart = RaycastResult.Instance;

        if (not hitPart) then return end;

        local Character = hitPart.Link.Value:FindFirstAncestorOfClass('Model')

        if (not Character) then return end;

        local TargetPlayer = game:GetService("Players"):GetPlayerFromCharacter(Character)

        if (TargetPlayer and TargetPlayer == self.Player) then
            return
        end

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
            coroutine.wrap(v.Function)(self.MoveKey, hitPart, HitCool)
        end
        Removed = nil;
    end);

    local Params: RaycastParams = self.Params
    Params.FilterType = Enum.RaycastFilterType.Whitelist
    Params.FilterDescendantsInstances = workspace.Entities.Hitboxes:GetChildren();
    self.Params = Params

    return self.Object:Start(...)
end

function Hitbox:HitStop(...)
    self.MoveKey = nil;
    if (self.Object) then
        self.Object:Stop(...)
        self.Object = nil
    end
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