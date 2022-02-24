local class       = require('seedless.util.class')
local FileManager = require('seedless.computer.FileManager')
local Collection  = require('seedless.hub.Collection')

local os          = _G.os

local Hub = class()
HubScreens = { GRID = "grid", COLLECTION = "collection", COLLECTION_LIST = "collection_list", COLLECTION_GRAPHS_GRID = "collection_graphs_grid", COLLECTION_GRAPHS_OVERLAP = "collection_graphs_overlap", LIST = "list", NODE = "node"}

function Hub:init(name, collections)
    self.name = name
    self.screen = HubScreens.GRID
    self.scroll = 0;
    self.scrollMax = 1;

    self.collections = collections

    self.currentCollection = nil
    self.nodes = { }
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
        if (Util.isIn(x, y, 2, 7, 2, 23)) then
            if (y < 15) then
                self.scroll = self.scroll - 1
                self.scroll = math.max(self.scroll, 0)
            else
                self.scroll = self.scroll + 1
                self.scroll = math.min(self.scroll, self.scrollMax)
            end
        elseif (Util.isIn(x, y, 3, 3, 54, 4)) then
            if (x <= 5) then
                self.screen = HubScreens.GRID
            elseif (x <= 9) then
                self.screen = HubScreens.LIST
            elseif (x <= 13) then
                self.screen = HubScreens.COLLECTION_LIST
            elseif (x <= 17 and self.screen == HubScreens.COLLECTION_LIST) then
                table.insert(self.collections, Collection("New Collection", { }))
            elseif (x >= 52) then
                self.trashEnabled = not self.trashEnabled
            end
        elseif (Util.isIn(x, y, 3, 6, 54, 22)) then
            local nodeIndex = nil
            if (self.screen == HubScreens.GRID) then
                local nodeX = math.floor((x - 3) / 13)
                local nodeY = math.floor((y - 7) / 8)
                nodeIndex = nodeX + nodeY * 4 + self.scroll * 4
            elseif (y < 22) then
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
        if (Util.isIn(x, y, 2, 7, 2, 23) and self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
            if (y < 15) then
                self.scroll = self.scroll - 1
                self.scroll = math.max(self.scroll, 0)
            else
                self.scroll = self.scroll + 1
                self.scroll = math.min(self.scroll, self.scrollMax)
            end
        elseif (Util.isIn(x, y, 3, 3, 54, 4)) then
            if (x <= 5) then
                if (self.screen == HubScreens.NODE) then
                    self.screen = HubScreens.GRID
                else
                    self.screen = HubScreens.COLLECTION_LIST
                end
            end
            if (self.screen ~= HubScreens.NODE) then
                if (x >= 52) then
                    self.screen = HubScreens.COLLECTION_GRAPHS_OVERLAP
                elseif (x >= 48) then
                    self.screen = HubScreens.COLLECTION_GRAPHS_GRID
                elseif (x >= 44) then
                    self.screen = HubScreens.GRID
                    self.addingNodeToCollection = true
                end
            end
        end
    end

    self:update()
end

function Hub:updateScreen()
    if (Computer.monitor == nil) then return end

    Computer.monitor:clear()
    Computer.monitor:border(colors.green)
    Computer.monitor.monitor.setBackgroundColor(colors.black)
    Computer.monitor:xLine(6, colors.gray, true, "\131")

    if (self.screen == HubScreens.GRID or self.screen == HubScreens.LIST or self.screen == HubScreens.COLLECTION_LIST) then
        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.GRID and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(3, 3)
        Computer.monitor:write("\136\152")
        Computer.monitor.monitor.setCursorPos(3, 4)
        Computer.monitor:write("\130\130")

        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.LIST and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(7, 3)
        Computer.monitor:write("\132\140")
        Computer.monitor.monitor.setCursorPos(7, 4)
        Computer.monitor:write("\129\131")

        Computer.monitor.monitor.setTextColor(colors.black)
        Computer.monitor.monitor.setBackgroundColor(self.screen == HubScreens.COLLECTION_LIST and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(11, 3)
        Computer.monitor:write("\131\143")
        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.COLLECTION_LIST and colors.green or colors.lightGray)
        Computer.monitor.monitor.setBackgroundColor(colors.black)
        Computer.monitor.monitor.setCursorPos(11, 4)
        Computer.monitor:write("\131\131")

        if (self.screen == HubScreens.COLLECTION_LIST) then
            Computer.monitor.monitor.setTextColor(colors.black)
            Computer.monitor.monitor.setBackgroundColor(colors.lightGray)
            Computer.monitor.monitor.setCursorPos(15, 3)
            Computer.monitor:write("\135")
            Computer.monitor.monitor.setTextColor(colors.lightGray)
            Computer.monitor.monitor.setBackgroundColor(colors.black)
            Computer.monitor:write("\144")
            Computer.monitor.monitor.setCursorPos(15, 4)
            Computer.monitor:write("\130 ")
        end

        Computer.monitor.monitor.setTextColor(colors.white)
        Computer.monitor.monitor.setCursorPos(2, 7)
        Computer.monitor:write("\24")
        Computer.monitor.monitor.setCursorPos(2, 23)
        Computer.monitor:write("\25")

        Computer.monitor:drawVProgressBar(2, 8, 22, self.scroll, self.scrollMax)

        Computer.monitor.monitor.setTextColor(self.trashEnabled and colors.red or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(52, 3)
        Computer.monitor:write("\136\142\140")
        Computer.monitor.monitor.setCursorPos(52, 4)
        Computer.monitor:write(" \143\133")
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_GRID or self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP) then
        if (self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
            Computer.monitor.monitor.setTextColor(colors.white)
            Computer.monitor.monitor.setCursorPos(2, 7)
            Computer.monitor:write("\24")
            Computer.monitor.monitor.setCursorPos(2, 23)
            Computer.monitor:write("\25")

            Computer.monitor:drawVProgressBar(2, 8, 22, self.scroll, self.scrollMax)
        end
        
        Computer.monitor.monitor.setCursorPos(15, 3)
        Computer.monitor:write(self.currentCollection.name)
        Computer.monitor.monitor.setCursorPos(15, 4)
        Computer.monitor:write("Nodes: " .. Util.tablelength(self.currentCollection.nodeIDs))

        Computer.monitor.monitor.setTextColor(colors.lightGray)
        Computer.monitor.monitor.setCursorPos(4, 3)
        Computer.monitor:write("\152\129")
        Computer.monitor.monitor.setCursorPos(4, 4)
        Computer.monitor:write("\130\132")

        Computer.monitor.monitor.setTextColor(colors.black)
        Computer.monitor.monitor.setBackgroundColor(colors.lightGray)
        Computer.monitor.monitor.setCursorPos(45, 3)
        Computer.monitor:write("\135")
        Computer.monitor.monitor.setTextColor(colors.lightGray)
        Computer.monitor.monitor.setBackgroundColor(colors.black)
        Computer.monitor:write("\144")
        Computer.monitor.monitor.setCursorPos(45, 4)
        Computer.monitor:write("\130 ")

        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.COLLECTION_GRAPHS_GRID and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(49, 3)
        Computer.monitor:write("\134\140")
        Computer.monitor.monitor.setCursorPos(49, 4)
        Computer.monitor:write("\134\134")

        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.COLLECTION_GRAPHS_OVERLAP and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(53, 3)
        Computer.monitor:write("\140\152")
        Computer.monitor.monitor.setCursorPos(53, 4)
        Computer.monitor:write("\131\138")
    end

    if (self.screen == HubScreens.GRID) then
        local i = 0
        local j = 0
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                if (j >= self.scroll * 4) then
                    Computer.monitor:drawNodeSquare(node, i % 4 * 13 + 3, math.floor(i / 4) * 7 + 8, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i > 7) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.LIST) then
        local i = 0
        local j = 0
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                if (j >= self.scroll) then
                    Computer.monitor:drawNodeLine(node, 3, i * 3 + 7, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i > 4) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.COLLECTION_LIST) then
        local i = 0
        local j = 0
        for index, collection in pairs(self.collections) do
            if (collection ~= nil) then
                if (j >= self.scroll) then
                    Computer.monitor:drawCollectionLine(collection, 3, i * 3 + 7, self.trashEnabled and colors.red or colors.lightGray)
                    i = i + 1
                    if (i > 4) then
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
            Computer.monitor.monitor.setTextColor(colors.lightGray)
            Computer.monitor.monitor.setCursorPos(4, 3)
            Computer.monitor:write("\152\129")
            Computer.monitor.monitor.setCursorPos(4, 4)
            Computer.monitor:write("\130\132")

            Computer.monitor.monitor.setBackgroundColor(colors.black)
            Computer.monitor.monitor.setTextColor(colors.white)
            Computer.monitor.monitor.setCursorPos(3, 7)
            Computer.monitor.monitor.write(self.currentNode.name)

            Computer.monitor.monitor.setTextColor(colors.green)
            Computer.monitor.monitor.setCursorPos(3, 8)
            local str = string.sub(self.currentNode.itemID, string.find(self.currentNode.itemID, ":") + 1, -1)
            str = str:gsub("_+", " ")
            str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
            Computer.monitor.monitor.write(str)

            Computer.monitor:writeQuantity(self.currentNode.itemCount, self.currentNode.maxItemCount, 25, 7)
            Computer.monitor:writeTrend(self.currentNode.nodeHistory.trend, 40, 7)
            
            Computer.monitor:drawGraph(1, 23, 54, 14, self.currentNode.nodeHistory.quantityHistory, self.currentNode.maxItemCount)
        end
    elseif (self.screen == HubScreens.COLLECTION_GRAPHS_GRID) then
        if (self.currentCollection == nil) then
            self.screen = HubScreens.COLLECTION_LIST
        else
            local i = 0
            local j = 0
            for nodeID1, nodeID in pairs(self.currentCollection.nodeIDs) do
                local node = self.nodes[nodeID]
                if (node ~= nil) then
                    if (j >= self.scroll * 4) then
                        local x = i % 4 * 13 + 3
                        local y = math.floor(i / 4) * 7 + 8

                        Computer.monitor:lineBorder(x, y, x + 13, y + 7, colors.lightGray)
                        Computer.monitor:drawGraph(x, y + 6, 11, 3, node.nodeHistory.quantityHistory, node.maxItemCount, 2 ^ i)
                        Computer.monitor.monitor.setCursorPos(x + 1, y + 1)
                        Computer.monitor.monitor.setTextColor(colors.white)
                        Computer.monitor:write(node.name)
                        
                        Computer.monitor.monitor.setTextColor(colors.green)
                        Computer.monitor.monitor.setCursorPos(x + 1, y + 2)
                        local str = string.sub(node.itemID, string.find(node.itemID, ":") + 1, -1)
                        str = str:gsub("_+", " ")
                        str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
                        str = string.sub(str, 1, 12)
                        Computer.monitor.monitor.write(str)
                        i = i + 1
                        if (i > 7) then
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
                    Computer.monitor:drawGraph(1, 23, 54, 16, node.nodeHistory.quantityHistory, node.maxItemCount, 2 ^ i)
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