local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)

local ClientSword = {}
ClientSword.__index = ClientSword

ClientSword.Tag = "Sword"


function ClientSword.new(instance: Model)
    local self = setmetatable({
        Connections = {};
    }, ClientSword)
    self._maid = Maid.new()
    return self
end

function ClientSword:OwnerChanged()
    local CurrentOwner = self.Instance:GetAttribute("Owner");
    if (CurrentOwner == Knit.Player.UserId) then
        self:ActivateController();
    else
        self:DeactivateController();
    end
end

function ClientSword:Reset()
    self.Equipped = false;
end

function ClientSword:ActivateController()
    self:Reset()

    local Input = Knit.Controllers.InputController;
    local SwordService = Knit.GetService('SwordService');

    local Keybinds = {
        ['Q'] = 'ToggleEquip';
        ['LMB'] = 'NormalAttack';
    }

    local BeganConnection = Input:Began(function(Key)

        if (Keybinds[Input:GrabInput(Key)]) then
            SwordService:MovePromise(Keybinds[Input:GrabInput(Key)]):Await();
        end

    end)

    table.insert(self.Connections, BeganConnection);
    self._maid:GiveTask(BeganConnection)
end

function ClientSword:DeactivateController()
    self:Reset()

    for i = 1,#self.Connections do
        self.Connections[i]:Disconnect();
        table.remove(self.Connections, 1)
    end
    self.Connections = {};
end

function ClientSword:Init()
    self:OwnerChanged();
    self._maid:GiveTask(self.Instance:GetAttributeChangedSignal("Owner"):Connect(function()
        self:OwnerChanged();
    end))
end


function ClientSword:Deinit()

end


function ClientSword:Destroy()
    self._maid:Destroy()
end


return ClientSword