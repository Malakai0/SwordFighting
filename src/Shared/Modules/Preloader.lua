local Preloader = {Queue = {}}

local ContentProvider = game:GetService("ContentProvider");

--- Returns true if the Instance provided is classified as an Asset by Roblox.
---@param Instance Asset
---@return boolean IsAsset
function Preloader:IsAsset(Asset: Instance)
    if (typeof(Asset) ~= 'Instance') then return false end
    
    return Asset:IsA('Decal') or Asset:IsA('Sound') or
           Asset:IsA('Animation');
end

--- Adds an Asset to the queue to preload. Internally checks if the Instance is an asset.
---@param Instance Asset
---@return nil
function Preloader:AddToQueue(Asset: Instance)
    if (self:IsAsset(Asset)) then
        table.insert(self.Queue, Asset);
        self:Preload()
    end
end

--- Adds an Array to the queue. Internally checks each instance.
function Preloader:AddArrayToQueue(List: Array)
    for _, Asset: Instance in next, List do
        self:AddToQueue(Asset); -- All checks done there :^)
    end
end

--- Preloads all assets and flushes the queue.
---@param function Callback
function Preloader:Preload(Callback)
    ContentProvider:PreloadAsync(self.Queue, function(Content, Status)
        table.remove(self.Queue, table.find(Content)) -- Flush queue.
        Callback(Content, Status)
    end);
end

return Preloader