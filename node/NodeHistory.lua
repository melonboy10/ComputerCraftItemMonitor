local class = require("seedless.util.class")
local Util  = require("seedless.util.Util")

local NodeHistory = class()

function NodeHistory:init(node, history, trend)
    self.node = node

    self.quantityHistory = history or { [0] = 0, [1] = 0 }
    self.trend = trend or 0
end

function NodeHistory:update()
    -- self.quantityHistory[Util.tablelength(self.quantityHistory)] = self.node.itemCount
    -- self.quantityHistory
    table.insert(self.quantityHistory, self.node.itemCount);
    if (Util.tablelength(self.quantityHistory) > 60) then self.quantityHistory[0] = nil; end

    self.trend = self.quantityHistory[#self.quantityHistory] - self.quantityHistory[#self.quantityHistory - 1]
end

function NodeHistory:serialise()
    return { quantityHistory = self.quantityHistory, trend = self.trend }
end

return NodeHistory