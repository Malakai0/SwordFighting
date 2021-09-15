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

function Hitbox:HitStart(OnServer: boolean, Key: string, HitCool: number, ...)
    local Cast = Knit.Modules.ClientCast;
    self.MoveKey = Key;

    if (self.Object) then
        self.Object:Stop();
        self.Object.Raycast:HitStop()
    else
        self.Object = Cast.new(self.Mechanism, self.Params)
    end
    
    if self.Player then
        self.Object:SetOwner(self.Player)
    end

    if (self.Connection) then
        self.Connection:Disconnect();
        self.Connection = nil;
    end

    self.Connection = self.Object.Collided:Connect(function(hitPart)
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
        if (not Character:FindFirstChild'Humanoid') then return end;
        if (Character.Humanoid.Health <= 0) then return end;

        if (self.Mechanism:IsDescendantOf(Character)) then
            return
        end

        local TargetPlayer = game:GetService("Players"):GetPlayerFromCharacter(Character)

        if (TargetPlayer and TargetPlayer == self.Player) then
            return
        end

        hitPart.Color = Color3.new(1, 0, 0)
        hitPart.Transparency = 0.3;
        local id = math.random()
        idCache[hitPart] = id

        task.delay(0.5, function()
            if (hitPart and idCache[hitPart] == id) then
                hitPart.Transparency = 1;
                idCache[hitPart] = nil;
            end
        end)

        for _,v in next, self.Connections do
            task.spawn(v.Function, Key, Character:FindFirstChild(PartName), HitCool)
        end
    end);

    local Params: RaycastParams = self.Params
    Params.FilterType = Enum.RaycastFilterType.Whitelist
    Params.FilterDescendantsInstances = {workspace.Entities.Hitboxes};
    self.Params = Params

    self.Object:EditRaycastParams(Params);

    if (OnServer) then
        self.Object.Raycast:HitStart();
    end

    return self.Object:Start(HitCool, ...)
end

function Hitbox:HitStop()
    self.MoveKey = nil;
    if (self.Object) then
        if (self.Object.Raycast) then
            self.Object.Raycast:HitStop();
        end
        self.Object:Stop()
    end

    if (self.Connection) then
        self.Connection:Disconnect();
        self.Connection = nil;
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

    if (self.Connection) then
        self.Connection:Disconnect();
        self.Connection = nil;
    end

    if (self.Object) then
        if (self.Object.Raycast) then
            self.Object.Raycast:Destroy();
        end
        self.Object:Destroy()
    end

    for i,v in next, self.Connections do
        if not (type(v) == 'table') then continue end;
        if (not v.ID) then continue end;
        self:Disconnect(v.ID)
    end
    
    self._maid:Destroy();
end


return Hitbox