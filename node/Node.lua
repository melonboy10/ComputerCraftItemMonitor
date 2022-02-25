local class       = require('seedless.util.class')
local NodeHistory = require('seedless.node.NodeHistory')
local FileManager = require('seedless.computer.FileManager')

local os        = _G.os

local Node = class()
local monitor

local drawersBlacklist = { "storagedrawers:compacting_drawers_3", "storagedrawers:controller", "storagedrawers:controller_slave" }
local upgradeNumber = {
    ["obsidian"] = 2,
    ["iron"] = 4,
    ["gold"] = 8,
    ["diamond"] = 16,
    ["emerald"] = 32
}

function Node:init(name, id, quantityHistory, trend)
    self.name = name
    self.nodeID = id
    self.itemID = ""
    self.itemCount = 0
    self.maxItemCount = 0

    self.inventory = { }
    self.inventoryType = ""
    self.blockID = ""

    self.nodeHistory = NodeHistory(self, quantityHistory, trend)
    
    monitor = Computer.monitor
end

function Node:readBlockData()
    
    self.inventoryType, tmp = peripheral.getType("top")
    if (self.inventoryType == nil) then error("No inventory found [`blockReader`,`inventory`,`fluid_inventory`]") end
    if (tmp ~= nil) then
        self.blockID = self.inventoryType
        self.inventoryType = tmp
    end
    self.inventory = peripheral.wrap("top")

    if (self.inventoryType == "blockReader") then
        self.blockID = self.inventory.getBlockName()
        if (string.find(self.blockID, "storagedrawers") ~= nil and not Util.containsValue(drawersBlacklist, self.blockID)) then
            local data = self.inventory.getBlockData();

            if (data.Drawers[0].Item == nil) then error("No items in the drawer. (Only allows the first slot, Remember to lock the drawer)") end
            self.itemID = data.Drawers[0].Item.id
            self.itemCount = data.Drawers[0].Count

            local multiplier = 0;
            if (data.Upgrades[0] ~= nil) then
                for i = 0, #data.Upgrades do
                    local grade = string.sub(data.Upgrades[i].id, 16, -1);
                    grade = string.sub(grade, 0, #grade - 16)
                    multiplier = multiplier + (upgradeNumber[grade] or 0)
                end
            end

            if (multiplier == 0) then multiplier = 1 end
            
            local half = string.find(self.blockID, "half") ~= nil
            local slots = string.sub(self.blockID, -1, -1)
            self.maxItemCount = 64 * ((half and 16 or 32) * multiplier / slots) --change 64 to item max stack

        else
            error("Not a valid Storage Drawer (Cannot be ['storagedrawers:compacting_drawers_3', 'storagedrawers:controller', 'storagedrawers:controller_slave'])")
        end

    elseif (self.inventoryType == "inventory") then
        local list = self.inventory.list()
        if (self.itemID == "" and list[1] == nil) then error("No items in container") end

        self.itemCount = 0
        for i, item in pairs(list) do
            if (item ~= nil and self.itemID == "") then
                self.itemID = item.name
                self.maxItemCount = self.inventory.size() * self.inventory.getItemLimit(i)
            end
            if (item.name == self.itemID) then
                self.itemCount = self.itemCount + item.count
            end
        end
    elseif (self.inventoryType == "fluid_inventory") then

    else
        error("No valid block types on top! Only found " .. self.inventoryType)
    end

    
end

function Node:update()
    self:readBlockData()
    self.nodeHistory:update()
    self:updateScreen()
end

function Node:touchEvent(event, button, x, y)
    self:update()
end

function Node:updateScreen()
    if (monitor ~= nil) then

        monitor:clear()
        local color = colors.black
        if (self.nodeHistory.trend < 0 or self.itemCount == 0) then
            color = colors.red
        elseif (self.nodeHistory.trend > 0 or self.itemCount == self.maxItemCount) then
            color = colors.green
        else 
            color = colors.yellow
        end
        
        monitor:border(color)

        if (monitor.width > 16) then
            monitor:writeQuantity(self.itemCount, self.maxItemCount, monitor.width / 4, monitor.height - 13)
            monitor:writeTrend(self.nodeHistory.trend / Computer.info.updateTime, monitor.width / 4 * 3, monitor.height - 13)
        else
            monitor:writeQuantity(self.itemCount, self.maxItemCount, monitor.width / 2, monitor.height - 13)
        end

        monitor:drawGraph(2, monitor.height - 15, monitor.width, monitor.height - 17, self.nodeHistory.quantityHistory, self.maxItemCount)

        if (monitor.height > 10) then
            monitor:fill(1, monitor.height - 10, 17, monitor.height, color)
        end
    end
end

function Node:serialise()
    local thinNode = { }
    thinNode.name = self.name
    thinNode.nodeID = self.nodeID
    
    thinNode.itemID = self.itemID 
    thinNode.itemCount = self.itemCount 
    thinNode.maxItemCount = self.maxItemCount 
    thinNode.inventoryType = self.inventoryType 
    thinNode.blockID = self.blockID 

    thinNode.nodeHistory = self.nodeHistory:serialise()

    return thinNode
end

function Node:save()
    local ser = self:serialise()
    FileManager.write("Node", ser)
    rednet.broadcast(textutils.serialise(ser))
end

return Node