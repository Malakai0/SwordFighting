local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component);

local SwordService = Knit.CreateService {
    Name = "SwordService";
    Client = {};
}

function SwordService.Client:ToggleEquip(Player)
    local Sword = self.Server:FindSwordForPlayer(Player)
    if (not Sword) then
        return
    end

    local Object = Component.FromTag('Sword'):GetFromInstance(Sword);

    if (Object.Equipped) then
        Object:Unequip(true);
    else
        Object:Equip(true);
    end
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