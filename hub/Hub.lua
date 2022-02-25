local class       = require('seedless.util.class')
local FileManager = require('seedless.computer.FileManager')
local Collection  = require('seedless.hub.Collection')

local os          = _G.os

local Hub = class()
HubScreens = { GRID = "grid", COLLECTION = "collection", COLLECTION_LIST = "collection_list", COLLECTION_GRAPHS_GRID = "collection_graphs_grid", COLLECTION_GRAPHS_OVERLAP = "collection_graphs_overlap", LIST = "list", NODE = "node"}
local monitor

function Hub:init(name, collections)
    self.name = name
    self.screen = HubScreens.GRID
    self.scroll = 0;
    self.scrollMax = 1;

    self.collections = collections

    self.currentCollection = nil
    self.nodes = { }
    
    monitor = Computer.monitor
end

function Hub:update()
    self:updateScreen()
    self:save()
end

function Hub:updateVariables()
    local length = Util.tablelength(self.nodes)
    if (length > 1) then
        if (self.screen == HubScreens.GRID) then
            self.scrollMax = math.floor(length / 4) - 1
        elseif (self.screen == HubScreens.LIST) then
            self.scrollMax = math.floor(length) - 1
        end
    end

    -- if (os.clock() % Computer.info.updateTime == 0) then
    -- end
end

function Hub:touchEvent(event, button, x, y)
    self:updateVariables()

    if (self.screen == HubScreens.GRID or self.screen == HubScreens.LIST or self.screen == HubScreens.COLLECTION_LIST) then
        if (Util.isIn(x, y, 2, 7, 2, monitor.height - 1)) then -- Scroll Box
            if (y < (monitor.height - 8) / 2 + 8) then
                self.scroll = self.scroll - 1
                self.scroll = math.max(self.scroll, 0)
            else
                self.scroll = self.scroll + 1
                self.scroll = math.min(self.scroll, self.scrollMax)
            end
        elseif (Util.isIn(x, y, 3, 3, monitor.width - 2, 4)) then -- Top Box
            if (x <= 5) then
                self.screen = HubScreens.GRID
            elseif (x <= 9) then
                self.screen = HubScreens.LIST
            elseif (x <= 13) then
                self.screen = HubScreens.COLLECTION_LIST
            elseif (x <= 17 and self.screen == HubScreens.COLLECTION_LIST) then
                table.insert(self.collections, Collection("New Collection", { }))
            elseif (x >= monitor.width - 5) then
                self.trashEnabled = not self.trashEnabled
            end
        elseif (Util.isIn(x, y, 3, 6, monitor.width - 2, monitor.height - 2)) then -- Content Box
            local nodeIndex = nil
            if (self.screen == HubScreens.GRID) then
                local nodeX = math.floor((x - 3) / 13)
                local nodeY = math.floor((y - 7) / 8)
                nodeIndex = nodeX + nodeY * 4 + self.scroll * 4
            elseif (y < monitor.height - 2) then
                local nodeY = math.floor((y - 7) / 3)
                nodeIndex = nodeY + self.scroll
            end
            if (nodeIndex ~= nil) then
                local i = 0
                local list = (self.screen == HubScreens.COLLECTION_LIST and self.collections or self.nodes)
                for id, node in pairs(list) do
                    if (i == nodeIndex) then
                        if (self.trashEnabled) then
                            if (self.screen == HubScreens.COLLECTION_LIST) then
                                self.collections[id] = nil
                            else
                                self.nodes[id] = nil
                            end
                        else
                            if (self.screen == HubScreens.COLLECTION_LIST) then
                                self.screen = HubScreens.COLLECTION_GRAPHS_GRID
                                self.currentCollection = self.collections[id]
                            else
                                if (self.addingNodeToCollection) then
                                    self.screen = HubScreens.COLLECTION_LIST
                                    self.addingNodeToCollection = false
                                    self.currentCollection.nodeIDs[id] = id
                                else
                                    self.screen = HubScreens.NODE
                                    self.currentNode = self.nodes[id]
                                end
                            end
                        end
                        break
                    end
                    i = i + 1
                end
            end
        end
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_GRID or self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP or self.screen == HubScreens.NODE) then
        if (Util.isIn(x, y, 2, 7, 2, monitor.height - 1) and self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
            if (y < (monitor.height - 8) / 2 + 8) then
                self.scroll = self.scroll - 1
                self.scroll = math.max(self.scroll, 0)
            else
                self.scroll = self.scroll + 1
                self.scroll = math.min(self.scroll, self.scrollMax)
            end
        elseif (Util.isIn(x, y, 3, 3, monitor.width - 2, 4)) then -- Top Box
            if (x <= 5) then
                if (self.screen == HubScreens.NODE) then
                    self.screen = HubScreens.GRID
                else
                    self.screen = HubScreens.COLLECTION_LIST
                end
            end
            if (self.screen ~= HubScreens.NODE) then
                if (x >= monitor.width - 5) then
                    self.screen = HubScreens.COLLECTION_GRAPHS_OVERLAP
                elseif (x >= monitor.width - 9) then
                    self.screen = HubScreens.COLLECTION_GRAPHS_GRID
                elseif (x >= monitor.width - 15) then
                    self.screen = HubScreens.GRID
                    self.addingNodeToCollection = true
                end
            end
        end
    end

    self:update()
end

function Hub:updateScreen()
    if (monitor == nil) then return end
    
    monitor:clear()
    monitor:border(colors.green)
    monitor:setBackgroundColor(colors.black)
    monitor:xLine(6, colors.gray, true, "\131")

    if (self.screen == HubScreens.GRID or self.screen == HubScreens.LIST or self.screen == HubScreens.COLLECTION_LIST) then
        monitor:setTextColor(self.screen == HubScreens.GRID and colors.green or colors.lightGray)
        monitor:setCursorPos(3, 3)
        monitor:write("\136\152")
        monitor:setCursorPos(3, 4)
        monitor:write("\130\130")

        monitor:setTextColor(self.screen == HubScreens.LIST and colors.green or colors.lightGray)
        monitor:setCursorPos(7, 3)
        monitor:write("\132\140")
        monitor:setCursorPos(7, 4)
        monitor:write("\129\131")

        monitor:setColors(colors.black, self.screen == HubScreens.COLLECTION_LIST and colors.green or colors.lightGray)
        monitor:setCursorPos(11, 3)
        monitor:write("\131\143")
        monitor:setColors(self.screen == HubScreens.COLLECTION_LIST and colors.green or colors.lightGray, colors.black)
        monitor:setCursorPos(11, 4)
        monitor:write("\131\131")

        if (self.screen == HubScreens.COLLECTION_LIST) then
            monitor:setColors(colors.black, colors.lightGray)
            monitor:setCursorPos(15, 3)
            monitor:write("\135")
            monitor:setColors(colors.lightGray, colors.black)
            monitor:write("\144")
            monitor:setCursorPos(15, 4)
            monitor:write("\130 ")
        end

        monitor:setTextColor(colors.white)
        monitor:setCursorPos(2, 7)
        monitor:write("\24")
        monitor:setCursorPos(2, monitor.height - 1)
        monitor:write("\25")

        monitor:drawVProgressBar(2, 8, monitor.height - 2, self.scroll, self.scrollMax)

        monitor:setTextColor(self.trashEnabled and colors.red or colors.lightGray)
        monitor:setCursorPos(monitor.width - 5, 3)
        monitor:write("\136\142\140")
        monitor:setCursorPos(monitor.width - 5, 4)
        monitor:write(" \143\133")
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_GRID or self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP) then
        if (self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
            monitor:setTextColor(colors.white)
            monitor:setCursorPos(2, 7)
            monitor:write("\24")
            monitor:setCursorPos(2, monitor.height - 1)
            monitor:write("\25")

            monitor:drawVProgressBar(2, 8, monitor.height - 2, self.scroll, self.scrollMax)
        end
        
        monitor:setTextColor(colors.white)
        monitor:setCursorPos(monitor.width / 2 - #self.currentCollection.name / 2, 3)
        monitor:write(self.currentCollection.name)
        monitor:setCursorPos(monitor.width / 2 - #self.currentCollection.name / 2, 4)
        monitor:write("Nodes: " .. Util.tablelength(self.currentCollection.nodeIDs))

        monitor:setTextColor(colors.lightGray)
        monitor:setCursorPos(4, 3)
        monitor:write("\152\129")
        monitor:setCursorPos(4, 4)
        monitor:write("\130\132")

        monitor:setColors(colors.black, colors.lightGray)
        monitor:setCursorPos(monitor.width - 12, 3)
        monitor:write("\135")
        monitor:setColors(colors.lightGray, colors.black)
        monitor:write("\144")
        monitor:setCursorPos(monitor.width - 12, 4)
        monitor:write("\130 ")

        monitor:setTextColor(self.screen == HubScreens.COLLECTION_GRAPHS_GRID and colors.green or colors.lightGray)
        monitor:setCursorPos(monitor.width - 8, 3)
        monitor:write("\134\140")
        monitor:setCursorPos(monitor.width - 8, 4)
        monitor:write("\134\134")

        monitor:setTextColor(self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP and colors.green or colors.lightGray)
        monitor:setCursorPos(monitor.width - 4, 3)
        monitor:write("\140\152")
        monitor:setCursorPos(monitor.width - 4, 4)
        monitor:write("\131\138")
    end

    if (self.screen == HubScreens.GRID) then
        local i = 0
        local j = 0
        local maxH = math.floor((monitor.height - 8) / 7)
        local maxW = math.floor((monitor.width - 2) / 13)
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                if (j >= self.scroll * maxW) then
                    monitor:drawNodeSquare(node, i % maxW * 13 + 3, math.floor(i / maxW) * 7 + 8, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i >= maxH * maxW) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.LIST) then
        local i = 0
        local j = 0
        local max = math.floor((monitor.height - 7) / 3)
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                if (j >= self.scroll) then
                    monitor:drawNodeLine(node, 3, i * 3 + 7, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i >= max) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.COLLECTION_LIST) then
        local i = 0
        local j = 0
        local max = math.floor((monitor.height - 7) / 3)
        for index, collection in pairs(self.collections) do
            if (collection ~= nil) then
                if (j >= self.scroll) then
                    monitor:drawCollectionLine(collection, 3, i * 3 + 7, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i >= max) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.NODE) then
        if (self.currentNode == nil) then
            self.screen = HubScreens.GRID
        else
            monitor:setTextColor(colors.lightGray)
            monitor:setCursorPos(4, 3)
            monitor:write("\152\129")
            monitor:setCursorPos(4, 4)
            monitor:write("\130\132")

            monitor:setColors(colors.white, colors.black)
            monitor:setCursorPos(3, 7)
            monitor.monitor.write(self.currentNode.name)

            monitor:setTextColor(colors.green)
            monitor:setCursorPos(3, 8)
            local str = string.sub(self.currentNode.itemID, string.find(self.currentNode.itemID, ":") + 1, -1)
            str = str:gsub("_+", " ")
            str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
            monitor.monitor.write(str)

            monitor:writeQuantity(self.currentNode.itemCount, self.currentNode.maxItemCount, monitor.width / 2, 7)
            monitor:writeTrend(self.currentNode.nodeHistory.trend, monitor.width / 4 * 3, 7)
            
            monitor:drawGraph(1, monitor.height - 1, monitor.width - 3, monitor.height - 11, self.currentNode.nodeHistory.quantityHistory, self.currentNode.maxItemCount)
        end
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
        if (self.currentCollection == nil) then
            self.screen = HubScreens.COLLECTION_LIST
        else
            local i = 0
            local j = 0
            local maxH = math.floor((monitor.height - 8) / 7)
            local maxW = math.floor((monitor.width - 2) / 13)
            for nodeID1, nodeID in pairs(self.currentCollection.nodeIDs) do
                local node = self.nodes[nodeID]
                if (node ~= nil) then
                    if (j >= self.scroll * maxW) then
                        local x = i % maxW * 13 + 3
                        local y = math.floor(i / maxW) * 7 + 8

                        monitor:lineBorder(x, y, x + 13, y + 7, colors.lightGray)
                        monitor:drawGraph(x, y + 6, 11, 3, node.nodeHistory.quantityHistory, node.maxItemCount, 2 ^ i)
                        monitor:setCursorPos(x + 1, y + 1)
                        monitor:setTextColor(colors.white)
                        monitor:write(node.name)
                        
                        monitor:setTextColor(colors.green)
                        monitor:setCursorPos(x + 1, y + 2)
                        local str = string.sub(node.itemID, string.find(node.itemID, ":") + 1, -1)
                        str = str:gsub("_+", " ")
                        str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
                        str = string.sub(str, 1, 12)
                        monitor.monitor.write(str)
                        i = i + 1
                        if (i > maxH * maxW) then
                            break
                        end
                    end
                    j = j + 1
                end
            end
        end
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP) then
        if (self.currentCollection == nil) then
            self.screen = HubScreens.COLLECTION_LIST
        else
            local i = 0
            for nodeID1, nodeID in pairs(self.currentCollection.nodeIDs) do
                local node = self.nodes[nodeID]
                if (node ~= nil) then
                    monitor:drawGraph(1, monitor.height - 1, monitor.width - 3, monitor.height - 11, node.nodeHistory.quantityHistory, node.maxItemCount, 2 ^ i)
                    i = i + 1
                end
            end
        end
    end
end

function Hub:serialise()
    local thinHub = { }
    thinHub.name = self.name
    thinHub.collections = self.collections

    return thinHub
end

function Hub:save()
    local ser = self:serialise()
    FileManager.write("Hub", ser)
end

return Hub