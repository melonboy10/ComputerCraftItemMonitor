local class       = require('seedless.util.class')
local FileManager = require('seedless.computer.FileManager')
local Collection  = require('seedless.hub.Collection')

local os          = _G.os

local Hub = class()
HubScreens = { GRID = "grid", COLLECTION = "collection", LIST = "list"}

function Hub:init(name, collections)
    self.name = name
    self.screen = HubScreens.GRID
    self.scroll = 0;
    self.scrollMax = 1;

    self.collections = { }
    for i = 1, #collections do
        table.insert(self.collections, Collection(collections[i]))
    end

    self.currentCollection = nil
    self.nodes = { }
end

function Hub:update()
    local length = Util.tablelength(self.nodes)
    if (length > 1) then
        if (self.screen == HubScreens.GRID) then
            self.scrollMax = math.floor(length / 4) - 1
        elseif (self.screen == HubScreens.LIST) then
            self.scrollMax = math.floor(length) - 1
        end
    end

    self:updateScreen()

    if (os.clock() % Computer.info.updateTime == 0) then
        self:save()
    end
end

function Hub:touchEvent(event, button, x, y)
    if (self.screen == HubScreens.GRID or self.screen == HubScreens.LIST) then
        if (Util.isIn(x, y, 2, 7, 3, 23)) then
            if (y < 15) then
                self.scroll = self.scroll - 1
                self.scroll = math.max(self.scroll, 0)
            else
                self.scroll = self.scroll + 1
                self.scroll = math.min(self.scroll, self.scrollMax)
            end
        elseif (Util.isIn(x, y, 3, 3, 10, 4)) then
            if (x <= 6) then
                if (self.screen ~= HubScreens.GRID) then
                    self.screen = HubScreens.GRID
                end
            else
                if (self.screen ~= HubScreens.LIST) then
                    self.screen = HubScreens.LIST
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
    if (self.screen == HubScreens.GRID or self.screen == HubScreens.LIST) then
        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.GRID and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(3, 3)
        Computer.monitor.monitor.write("\136\152")
        Computer.monitor.monitor.setCursorPos(3, 4)
        Computer.monitor.monitor.write("\130\130")

        Computer.monitor.monitor.setTextColor(self.screen == HubScreens.LIST and colors.green or colors.lightGray)
        Computer.monitor.monitor.setCursorPos(7, 3)
        Computer.monitor.monitor.write("\132\140")
        Computer.monitor.monitor.setCursorPos(7, 4)
        Computer.monitor.monitor.write("\129\131")

        Computer.monitor.monitor.setTextColor(colors.white)
        Computer.monitor.monitor.setCursorPos(11, 3)
        Computer.monitor.monitor.write(self.screen == HubScreens.GRID and "Grid" or "List")
        Computer.monitor.monitor.setCursorPos(11, 4)
        Computer.monitor.monitor.write("View")

        Computer.monitor.monitor.setCursorPos(2, 7)
        Computer.monitor.monitor.write("\24")
        Computer.monitor.monitor.setCursorPos(2, 23)
        Computer.monitor.monitor.write("\25")

        Computer.monitor:drawVProgressBar(2, 8, 22, self.scroll, self.scrollMax)

        Computer.monitor:xLine(6, colors.gray, true, "\131")
    end

    if (next(self.nodes) == nil) then return end

    if (self.screen == HubScreens.GRID) then
        local i = 0
        local j = 0
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                if (j >= self.scroll * 4) then
                    Computer.monitor:drawNodeSquare(node, i % 4 * 13 + 3, math.floor(i / 4) * 7 + 8)
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
                    Computer.monitor:drawNodeLine(node, 3, i * 3 + 7)
                    i = i + 1
                    if (i > 4) then
                        break
                    end
                end
                j = j + 1
            end
        end
    elseif (self.screen == HubScreens.COLLECTION) then

    end
end

function Hub:serialise()
    local thinHub = { }
    thinHub.name = self.name
    thinHub.collections = { }
    for i = 1, #self.collections do
        table.insert(thinHub.collections, self.collections[i]:serialise())
    end

    return thinHub
end

function Hub:save()
    local ser = self:serialise()
    FileManager.write("Hub", ser)
end

return Hub