local Effects = {}

local attackerInfo = function(ProvidedAttacker)
    return {
        Player = ProvidedAttacker;
        NPC = ProvidedAttacker.Parent == workspace.Entities.NPC;
    }
end

local function RandLerp(Min, Max)
    return Min + math.abs((Max - Min)) * math.random()
end

local function GeneratePositionWithOffset(Position: Vector3, MinOffset: Vector3, MaxOffset: Vector3)
    local MiO, MaO = MinOffset, MaxOffset or -MinOffset;
    return Position + Vector3.new(RandLerp(MiO.X, MaO.X), RandLerp(MiO.Y, MaO.Y), RandLerp(MiO.Z, MaO.Z));
end

function Effects.NormalAttack(Attacker, Recipient, PartHit, Damage)
    print(Attacker.Player.Name .. ' attacked ' .. Recipient.Player.Name .. ' for ' .. Damage .. ' damage.')
end

function Effects.DoEffect(Name, A, R, ...)
    return Effects[Name](attackerInfo(A), attackerInfo(R), ...);
end

return Effects