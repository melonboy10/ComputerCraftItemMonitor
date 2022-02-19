local FileManager = require("seedless.computer.FileManager")
local NodeHistory = require("seedless.node.NodeHistory")
local Node        = require("seedless.node.Node")
local Hub         = require("seedless.hub.Hub")
local Monitor     = require("seedless.computer.Monitor")

local os        = _G.os
local term      = _G.term
local textutils = _G.textutils

Computer = { timer = 0 }
ComputerType = { HUB = "hub", NODE = "node"}
ComputerScreens = { SETUP = "setup", STATS = "stats" }
local defaultComputerInfo = { computerType = nil, timerID = nil, updateTime = 10 }

function Computer.start()
    peripheral.find("modem", rednet.open)
    Computer.modem = peripheral.find("modem")
    if (Computer.modem == nil) then error("No modem attached") end
    Computer.monitor = Monitor()

    local computerInfo = FileManager.read("ComputerInfo")
    if (computerInfo == nil) then
        Computer.info = defaultComputerInfo
        Computer.screen = ComputerScreens.SETUP
    else
        Computer.info = textutils.unserialise(computerInfo)

        if (Computer.info.computerType == ComputerType.NODE) then
            Computer.setUpNode()
        elseif (Computer.info.computerType == ComputerType.HUB) then
            Computer.setUpHub()
        end
    end

    os.startTimer(0.5)
    Computer.newTimer = false
    while true do
        if (Computer.newTimer) then 
            -- rednet.receive(nil, 10)
            Computer.timer = os.startTimer(Computer.info.updateTime)
            -- os.startTimer(0.2)
            Computer.newTimer = false
        end

        local event, button, x, y, message  = os.pullEventRaw()
        if (event == "timer") then
            Computer.newTimer = true
            os.cancelTimer(Computer.timer)
            Computer.drawGUI()
            Computer.save()
        elseif (event == "monitor_touch") then
            Computer.touchEvent(event, button, x, y)
            if (Computer.system ~= nil) then Computer.system:touchEvent(event, button, x, y) end
        elseif (event == "mouse_click") then
            Computer.touchEvent(event, button, x, y)
        elseif (event == "rednet_message") then
            if (Computer.info.computerType == ComputerType.HUB) then
                -- print(x)
                local nodeTableThing = textutils.unserialise(x)
                if (nodeTableThing ~= nil) then
                    -- print(textutils.serialise(nodeTableThing))
                    Computer.system.nodes[nodeTableThing.nodeID] = nodeTableThing;
                    Computer.system:update()
                end
            end
        elseif (event == "terminate") then
            Computer.monitor.monitor.clear()
            Computer.monitor.monitor.setCursorPos(4, 8)
            Computer.monitor.monitor.write("Shutdown")
            Computer.save()
            error("Shutting down")
        end
    end
end

function Computer.touchEvent(event, button, x, y)
    if (y == 1) then
        if (x == 3) then
            Computer.info.updateTime = math.max(Computer.info.updateTime - 1, 1)
            Computer.drawGUI()
        elseif (x == #("< " .. Computer.info.updateTime .. " >") + 2) then
            Computer.info.updateTime = Computer.info.updateTime + 1
            Computer.drawGUI()
        end
    end

    if (event == "monitor_touch") then
        
    elseif (event == "mouse_click") then
        if (Computer.screen == ComputerScreens.SETUP) then
            if (Util.isIn(x, y, 5, 10, 19, 18) and Computer.monitor.width >= 29 and Computer.monitor.height >= 12) then
                Computer.setUpHub()
            elseif (Util.isIn(x, y, 35, 10, 42, 18)) then
                Computer.setUpNode()
            end
        end
    end
end

function Computer.save()
    if (Computer.system ~= nil) then Computer.system:save() end
    if (Computer.info.computerType ~= nil) then
        FileManager.write("ComputerInfo", Computer.info)
    end
end

function Computer.setUpNode()
    local nodeTable = FileManager.read("Node")
    if (nodeTable == nil) then
        Computer.system = Node("New Node", os.clock())
        Computer.system:save()
    else
        nodeTable = textutils.unserialise(nodeTable)
        Computer.system = Node(nodeTable.name, nodeTable.nodeID, nodeTable.nodeHistory.quantityHistory, nodeTable.nodeHistory.trend)
    end

    Computer.info.computerType = ComputerType.NODE
    Computer.system:update()
    Computer.screen = ComputerScreens.STATS
    Computer.drawGUI()
end

function Computer.setUpHub()
    local hubTable = FileManager.read("Hub") -- This will read the hub data (holds collections(seperate collections for each hub) and sorting info)
    if (hubTable == nil) then
        Computer.system = Hub("New Hub", { })
        Computer.system:save()
    else
        hubTable = textutils.unserialise(hubTable)
        Computer.system = Hub(hubTable.name, hubTable.collections)
    end

    Computer.info.computerType = ComputerType.HUB
    Computer.system:update()
    Computer.screen = ComputerScreens.STATS
    Computer.drawGUI()
end

function Computer.drawGUI()
    local w, h = term.getSize()

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    paintutils.drawBox(1, 1, w, h, colors.green)
    term.setCursorPos(1, 1)
    term.write("\167")

    if (Computer.screen == ComputerScreens.SETUP) then
        local hubCompatable = Computer.monitor.width >= 29 and Computer.monitor.height >= 12

        
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lime)
        Util.write(term, 2, 2, 
        " _______                __ __ \n"..
        "|   _   |-----.-----.--|  |  |-----.-----.-----. \n"..
        "|   L___|  -__|  -__|  _  |  |  -__|__ --|__ --| \n"..
        "|____   |_____|_____|_____|__|_____|_____|_____| \n"..
        "|:  I   | \n" ..
        "|::.. . | \n" ..
        "`-------'")

        term.setTextColor(colors.yellow)
        Util.write(term, 12, 6, 
        "___ \n"..
        " | _|_ _ __    |V| _ __  o _|_ _  __ \n"..
        "_|_ |_(/_|||   | |(_)| | |  |_(_) |")

        Util.drawIcon(term, 5, 10, not hubCompatable, "\127", 
        "55555555555555n" ..
        "5dddeee444ddd5n" ..
        "5dddeee444ddd5n" ..
        "5444444eee4445n" ..
        "5444444eee4445n" ..
        "5eee444dddddd5n" ..
        "5eee444dddddd5n" ..
        "55555555555555")

        Util.drawIcon(term, 35, 10, false, "\127", 
        "5555555n" ..
        "5ffff05n" ..
        "5f0f0f5n" ..
        "50f0ff5n" ..
        "5ddddd5n" ..
        "5ddddd5n" ..
        "5ddddd5n" ..
        "5555555")

        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(20, 12)
        term.write("< Setup Hub")
        term.setCursorPos(22, 14)
        term.write("Setup Node >")

--"___                                 "
--" | _|_ _ __    |V| _ __  o _|_ _  __"
--"_|_ |_(/_|||   | |(_)| | |  |_(_) | "
--".-. .-. .-. .  .   .  . .-. . . .-. .-. .-. .-. "
--" |   |  |-  |\/|   |\/| | | |\|  |   |  | | |(  "
--"`-'  '  `-' '  `   '  ` `-' ' ` `-'  '  `-' ' ' "
-- "╦┌┬┐┌─┐┌┬┐  ╔╦╗┌─┐┌┐┌┬┌┬┐┌─┐┬─┐"
-- "║ │ ├┤ │││  ║║║│ │││││ │ │ │├┬┘"
-- "╩ ┴ └─┘┴ ┴  ╩ ╩└─┘┘└┘┴ ┴ └─┘┴└─"
--   ___ _               __  __          _ _
--  |_ _| |_ ___ _ __   |  \/  |___ _ _ (_) |_ ___ _ _
--   | ||  _/ -_) '  \  | |\/| / _ \ ' \| |  _/ _ \ '_|
--  |___|\__\___|_|_|_| |_|  |_\___/_||_|_|\__\___/_|
    elseif (Computer.screen == ComputerScreens.STATS) then    
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        
        term.setCursorPos(3, 1)
        term.setBackgroundColor(colors.green)
        term.setTextColor(colors.white)
        term.write("< " .. Computer.info.updateTime .. " >")
        term.write(" " .. Computer.system.name)

        term.setCursorPos(4, 3)
        term.write("Stats and stuff go here")
        
    end
end

return Computer
