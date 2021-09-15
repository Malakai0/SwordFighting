local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component);

local SwordService = Knit.CreateService {
    Name = "SwordService";
    Client = {};
}

local ValidMoves = {
    'ToggleEquip';
    'NormalAttack';
}

function SwordService:FromInstance(Sword: Model)
    return Component.FromTag('Sword'):GetFromInstance(Sword);
end

function SwordService.Client:Move(Player: Player, MoveKey: string, ...)
    local Sword = self.Server:FindSwordForPlayer(Player)
    if (not Sword) then
        return
    end

    if not (type(MoveKey) == 'string') then
        return
    end

    if (not table.find(ValidMoves, MoveKey)) then
        return
    end

    local Object = self.Server:FromInstance(Sword);

    if (Object.Active) then
        return
    end

    if (Object[MoveKey]) then
        Object.Active = true;
        Object[MoveKey](Object, unpack(self.Server:GenerateArgs(Player, MoveKey, ...)))
        Object.Active = false;
    end
end

function SwordService:GiveSwordToCharacter(Character: Model)
    local Sword: Model = game:GetService('ServerStorage').Assets.Sword:Clone();
    Sword.Parent = Character;

    self:FromInstance(Sword):DetectCharacter();

    return Sword;
end

function SwordService:GiveSwordToNPC(NPC: Model)
    return self:GiveSwordToCharacter(NPC);
end

function SwordService:GiveSwordToPlayer(Player: Player)
    local Character: Model = Player.Character;
    if (not Character) then return end;

    return self:GiveSwordToCharacter(Character);
end

function SwordService:GenerateArgs(Player, MoveKey, ...)
    local Args = {}

    --// Logic

    return Args;
end

function SwordService:FindSwordForPlayer(Player)
    if (not Player.Character) then
        return
    end

    local Sword = Player.Character:FindFirstChild('Sword')
    local Owner = Sword and Sword:GetAttribute('Owner')

    if (Owner == Player.UserId) then
        return Sword;
    end
end

return SwordService