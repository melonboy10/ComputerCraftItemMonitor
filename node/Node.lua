local class       = require('util.class')
local NodeHistory = require('node.NodeHistory')
local FileManager = require('computer.FileManager')

local os        = _G.os

local Node = class()

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

    -- print(textutils.serialise( peripheral.getNames()))
    -- for i, side in pairs(peripheral.getNames()) do
    --     local type = peripheral.getType(side)
    --     if (type == "inventory" or type == "blockReader" or type == "fluid_inventory") then
    --         print (true)
    --     end
    -- end
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

    -- if (os.clock() % Computer.info.updateTime == 0) then
        self:save()
    -- end
end

function Node:touchEvent(event, button, x, y)
    self:update()
end

function Node:updateScreen()
    if (Computer.monitor ~= nil) then

        Computer.monitor:clear()
        local color = colors.black
        if (self.nodeHistory.trend < 0 or self.itemCount == 0) then
            color = colors.red
        elseif (self.nodeHistory.trend > 0 or self.itemCount == self.maxItemCount) then
            color = colors.green
        else 
            color = colors.yellow
        end
        
        Computer.monitor:border(color)

        if (Computer.monitor.width > 16) then
            Computer.monitor:writeQuantity(self.itemCount, self.maxItemCount, Computer.monitor.width / 4, Computer.monitor.height - 13)
            Computer.monitor:writeTrend(self.nodeHistory.trend / Computer.info.updateTime, Computer.monitor.width / 4 * 3, Computer.monitor.height - 13)
        else
            Computer.monitor:writeQuantity(self.itemCount, self.maxItemCount, Computer.monitor.width / 2, Computer.monitor.height - 13)
        end

        local width = Computer.monitor.width - 3
        local data = {}
        for i = 0, width, 1 do
            data[i] = self.nodeHistory.quantityHistory[#self.nodeHistory.quantityHistory - width + i]
        end

        Computer.monitor:drawGraph(2, Computer.monitor.height - 15, width, Computer.monitor.height - 17, data, self.maxItemCount)

        if (Computer.monitor.height > 6) then
            Computer.monitor:fill(1, Computer.monitor.height - 10, 17, Computer.monitor.height, color)
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
    print("saving")
    local ser = self:serialise()
    FileManager.write("Node", ser)
    rednet.broadcast(textutils.serialise(ser))
end

return Node