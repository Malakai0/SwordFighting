local ServerMove = {}
local Knit = require(game:GetService("ReplicatedStorage").Knit)

function ServerMove.NormalAttack(HurtFunc, Player, Recipient, Damage)
    HurtFunc();
    print('Server damage: ' .. Damage);
end

return ServerMove