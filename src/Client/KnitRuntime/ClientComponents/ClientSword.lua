local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Janitor = require(Knit.Util.Janitor)

local ClientSword = {}
ClientSword.__index = ClientSword

ClientSword.Tag = "Sword"


function ClientSword.new(instance: Model)
    local self = setmetatable({
        Connections = {};
    }, ClientSword)
    self._janitor = Janitor.new()
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
    self._janitor:Add(BeganConnection, 'Disconnect')
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

    self._janitor:Add(self.Instance:GetAttributeChangedSignal("Owner"):Connect(function()
        self:OwnerChanged();
    end), 'Disconnect')
end


function ClientSword:Deinit()

end


function ClientSword:Destroy()
    self._janitor:Cleanup()
end


return ClientSword