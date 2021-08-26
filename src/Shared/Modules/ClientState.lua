local ClientState = {}
ClientState.__index = ClientState

function ClientState.new(Player: Player)
    local self = setmetatable({
        Player = Player;
        Invincible = false;
    }, ClientState)

    return self;
end

function ClientState:SetInvincible(isInvincible: boolean)
    self.Invincible = not (not isInvincible); --// Convert to boolean.
end

function ClientState:Update()
    
end

--// When player joins.
function ClientState:Start()

end

--// When player leaves.
function ClientState:Stop()

end

return ClientState;