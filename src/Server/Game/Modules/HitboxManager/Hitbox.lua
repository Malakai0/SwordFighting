-- Hitbox module

local idCache = {}

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid);

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Player: Player, Mechanism: Instance)

    local Cast = Knit.Modules.ClientCast;

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
    local Cast = Knit.Modules.ClientCast;
    self.MoveKey = Key;

    if (not self.Object) then
        self.Object = Cast.new(self.Mechanism, self.Params)
    end
    
    if self.Player then
        self.Object:SetOwner(self.Player)
    end

    self.Object.Collided:Connect(function(hitPart, Position)
        if (not hitPart) then return end;

        local CharacterUID, PartName = table.unpack(string.split(hitPart:GetAttribute('Identifier'), '.'));

        local Character = (function(...)
            for _, Folder: Folder in next, {...} do
                for _, Character: Model in next, Folder:GetChildren() do
                    if (Character:GetAttribute('UID') == CharacterUID) then
                        return Character;
                    end
                end
            end
        end)(workspace.Entities.Players, workspace.Entities.NPCs)

        if (not Character) then return end;

        local TargetPlayer = game:GetService("Players"):GetPlayerFromCharacter(Character)

        if (TargetPlayer and TargetPlayer == self.Player) then
            return
        end

        hitPart.Color = Color3.new(1, 0, 0)
        hitPart.Transparency = 0.3;
        local id = math.random()
        idCache[hitPart] = id

        task.delay(0.5, function()
            if (idCache[hitPart] == id) then
                hitPart.Transparency = 1;
                idCache[hitPart] = nil;
            end
        end)

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
            coroutine.wrap(v.Function)(
                self.MoveKey, Character:FindFirstChild(PartName), HitCool
            )
        end
        Removed = nil;
    end);

    local Params: RaycastParams = self.Params
    Params.FilterType = Enum.RaycastFilterType.Whitelist
    Params.FilterDescendantsInstances = workspace.Entities.Hitboxes:GetChildren();
    self.Params = Params

    self.Object.RaycastParams = Params;

    return self.Object:Start(...)
end

function Hitbox:HitStop(...)
    self.MoveKey = nil;
    if (self.Object) then
        self.Object:Stop()
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