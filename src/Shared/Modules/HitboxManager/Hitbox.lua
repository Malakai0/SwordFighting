-- Hitbox module
-- Makes it easier for me to

local Knit = require(game:GetService("ReplicatedStorage").Knit)

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(Mechanism: Instance)

    local RaycastHitbox = Knit.Shared.RaycastHitbox;

    local self = setmetatable({
        ID = game:GetService("HttpService"):GenerateGUID();
        Object = RaycastHitbox.new(Mechanism);
    }, Hitbox)

    self.Object.DetectionMode = RaycastHitbox.DetectionMode.Default;

    return self
end


function Hitbox:Destroy()
    
end


return Hitbox