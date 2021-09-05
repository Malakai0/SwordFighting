local Preloader = {Queue = {}}

local ContentProvider = game:GetService("ContentProvider");

--- Returns true if the Instance provided is classified as an Asset by Roblox.
---@param Asset Instance
---@return boolean IsAsset
function Preloader:IsAsset(Asset: Instance)
    if (typeof(Asset) ~= 'Instance') then return false end
    
    return Asset:IsA('Decal') or Asset:IsA('Sound') or
           Asset:IsA('Animation');
end

--- Adds an Asset to the queue to preload. Internally checks if the Instance is an asset.
---@param Asset Instance
---@return nil
function Preloader:AddToQueue(Asset: Instance)
    if (self:IsAsset(Asset)) then
        table.insert(self.Queue, Asset);
    end
end

--- Adds an Array to the queue. Internally checks each instance.
---@param List table
---@return nil
function Preloader:AddArrayToQueue(List: Array)
    for _, Asset: Instance in next, List do
        self:AddToQueue(Asset); -- All checks done there :^)
    end
end

--- Preloads all assets and flushes the queue.
---@param Callback function
---@return nil
function Preloader:Preload(Callback)
    for i = 1, #self.Queue do
        local Item = self.Queue[1];
        ContentProvider:PreloadAsync({Item}, function(Content, Status)
            if (Callback) then
                Callback(Item, Status)
            end
        end)
        table.remove(self.Queue, 1);
    end
end

return Preloader