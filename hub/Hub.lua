local class       = require('seedless.util.class')
local FileManager = require('seedless.computer.FileManager')
local Collection  = require('seedless.hub.Collection')

local os          = _G.os

local Hub = class()
HubScreens = { GRID = "grid", COLLECTION = "collection", LIST = "list"}

function Hub:init(name, collections)
    self.name = name
    self.screen = HubScreens.GRID

    self.collections = { }
    for i = 1, #collections do
        table.insert(self.collections, Collection(collections[i]))
    end

    self.currentCollection = nil
    self.nodes = { }
end

function Hub:update()
    self:updateScreen()

    if (os.clock() % Computer.info.updateTime == 0) then
        self:save()
    end
end

function Hub:touchEvent()
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

        Computer.monitor:xLine(6, colors.gray, true, "\131")
    end

    if (next(self.nodes) == nil) then return end

    if (self.screen == HubScreens.GRID) then
        local i = 0
        for nodeID, node in pairs(self.nodes) do
            if (node ~= nil) then
                Computer.monitor:drawNodeSquare(node, i % 4 * 13 + 3, math.floor(i / 4) * 7 + 7)
                i = i + 1
            end
        end
        -- Computer.monitor:drawNodeSquare({ }, 3, 7)
        -- Computer.monitor:drawNodeSquare({ }, 16, 7)
        -- Computer.monitor:drawNodeSquare({ }, 29, 7)
        -- Computer.monitor:drawNodeSquare({ }, 42, 7)
        -- Computer.monitor:drawNodeSquare({ }, 3, 7)
        -- Computer.monitor:drawNodeSquare({ }, 3, 7)
    elseif (self.screen == HubScreens.LIST) then

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