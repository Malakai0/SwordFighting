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

function SwordService.Client:Move(Player, MoveKey, ...)
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

    local Object = Component.FromTag('Sword'):GetFromInstance(Sword);

    if (Object[MoveKey]) then
        Object[MoveKey](Object, unpack(self.Server:GenerateArgs(Player, MoveKey, ...)))
    end
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