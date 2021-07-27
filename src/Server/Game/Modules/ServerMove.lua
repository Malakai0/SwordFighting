local ServerMove = {}
local Knit = require(game:GetService("ReplicatedStorage").Knit)

function ServerMove.NormalAttack(HurtFunc, Player, Recipient, Damage)
    return HurtFunc();
end

return ServerMove