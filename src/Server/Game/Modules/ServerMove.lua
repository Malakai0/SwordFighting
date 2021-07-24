local ServerMove = {}
local Knit = require(game:GetService("ReplicatedStorage").Knit)

function ServerMove.NormalAttack(HurtFunc, Player, Recipient, Damage)
    HurtFunc();
end

return ServerMove