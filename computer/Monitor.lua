local class = require("seedless.util.class")

local Monitor = class()

function Monitor:init()
    self.monitor = peripheral.find("monitor")
    if (self.monitor == nil) then error("No monitor attached") end
    self.monitor.setCursorPos(1, 1)
    self.monitor.setTextScale(0.5)
    self.width, self.height = self.monitor.getSize()
end

function Monitor:clear()
    self.monitor.setBackgroundColor(colors.black)
    self.monitor.clear()
end

function Monitor:border(color)
    self.monitor.setBackgroundColor(color)
    self.monitor.setTextColor(colors.white)

    for i = 1, self.width do
        self.monitor.setCursorPos(i, 1)
        self.monitor.write("\127\127")
        self.monitor.setCursorPos(i, self.height)
        self.monitor.write("\127\127")
    end
    for i = 1, self.height do
        self.monitor.setCursorPos(1, i)
        self.monitor.write("\127")
        self.monitor.setCursorPos(self.width, i)
        self.monitor.write("\127")
    end
end

function Monitor:lineBorder(x1, y1, x2, y2, color)
    self.monitor.setBackgroundColor(colors.black)
    self.monitor.setTextColor(color)
    self.monitor.setCursorPos(x1, y1)
    self.monitor.write(string.rep("-", x2 - x1))
    self.monitor.setCursorPos(x1, y2)
    self.monitor.write(string.rep("-", x2 - x1))

    for i = y1, y2 do
        self.monitor.setCursorPos(x1, i)
        self.monitor.write("|")
        self.monitor.setCursorPos(x2, i)
        self.monitor.write("|")
    end
    self.monitor.setCursorPos(x1, y1)
    self.monitor.write("+")
    self.monitor.setCursorPos(x1, y2)
    self.monitor.write("+")
    self.monitor.setCursorPos(x2, y1)
    self.monitor.write("+")
    self.monitor.setCursorPos(x2, y2)
    self.monitor.write("+")
end

function Monitor:fill(x1, y1, x2, y2, color, char)
    char = char or "\127"
    self.monitor.setBackgroundColor(color)
    self.monitor.setTextColor(colors.white)

    for x = x1, x2 do
       for y = y1, y2 do
           self.monitor.setCursorPos(x, y)
           self.monitor.write(char)
       end
    end
end

function Monitor:xLine(number, color, text, char)
    char = char or "\127"
    if (text) then
        self.monitor.setBackgroundColor(colors.black)
        self.monitor.setTextColor(color)
    else
        
        self.monitor.setBackgroundColor(color)
        self.monitor.setTextColor(colors.white)
    end

    for i = 2, self.width - 1 do
        self.monitor.setCursorPos(i, number)
        self.monitor.write(char)
    end
end

function Monitor:yLine(number, color)
    self.monitor.setBackgroundColor(color)
    self.monitor.setTextColor(colors.white)

    for i = 1, self.height do
        self.monitor.setCursorPos(number, i)
        self.monitor.write("\127")
    end
end

function Monitor:writeQuantity(quantity, maxQuantity, x, y, inline)
    self.monitor.setBackgroundColor(colors.black)
    self.monitor.setTextColor(colors.white)

    local topNumber = Util.abbreviateNumber(quantity)
    local bottomNumber = Util.abbreviateNumber(maxQuantity)

    if (inline) then
        self.monitor.setCursorPos(x, y)
    else
        self.monitor.setCursorPos(x - (#topNumber / 2) + 1, y)
    end
    self.monitor.setTextColor(colors.orange)
    self.monitor.write(topNumber)

    self.monitor.setTextColor(colors.gray)
    self.monitor.write(" / ")

    if (not inline) then
        self.monitor.setCursorPos(x - (#bottomNumber / 2) + 1, y + 1)
    end
    self.monitor.setTextColor(colors.lightGray)
    self.monitor.write(bottomNumber)
    
    -- self.monitor.setCursorPos(1, 10)
    -- self.monitor.write("\140\159 \140\159 \159\128\159 \159\140 \159\140\140 \140\140\159 \159\140\159 \159\140\159")
    -- self.monitor.setCursorPos(1, 11)
    -- self.monitor.write("\128\159 \159\140 \140\140\159 \140\159 \159\140\159 \128\128\159 \140\140\159 \159\140\159")
    -- -- self.monitor.write("▄█ ▀█ █░█ █▀ █▄▄ ▀▀█ █▀█ █▀█\n░█ █▄ ▀▀█ ▄█ █▄█ ░░█ ▀▀█ █▄█\n")

end

function Monitor:writeTrend(trend, x, y, inline)
    if (inline) then
        self.monitor.setCursorPos(x, y)
    else
        self.monitor.setCursorPos(x - (#tostring(trend) / 2), y)
    end
    local color = colors.white
    if (trend < 0) then
        color = colors.red
    elseif (trend > 0) then
        color = colors.green
    else 
        color = colors.yellow
    end

    self.monitor.setTextColor(color)
    self.monitor.write(tonumber(string.format("%.1f", trend)))

    self.monitor.setTextColor(colors.gray)
    self.monitor.write(" / ")
    if (not inline) then self.monitor.setCursorPos(x - 3, y + 1) end
    self.monitor.setTextColor(colors.lightGray)
    if (not inline) then self.monitor.write("second") else
    self.monitor.write("s") end
end

local bars = { [0] = "_", [1] = "-", [2] = "\175"}

function Monitor:drawGraph(x, y, w, h, data, max)
    self.monitor.setBackgroundColor(colors.black)
    self.monitor.setTextColor(colors.white)

    for i, n in pairs(data) do
        data[i] = n / max * h
        self.monitor.setCursorPos(x + i, y - data[i])
        local char = data[i] * 3 % 3
        if (n == max) then self.monitor.write("*") else
        self.monitor.write(bars[math.floor(char)]) end
    end
    -- print(textutils.serialise(data))

end

function Monitor:drawNodeSquare(node, x, y)
    self:lineBorder(x, y, x + 13, y + 7, colors.lightGray)
    -- self:fill(x, y, x + 13, y + 7, colors.lightGray, " ")

    self.monitor.setBackgroundColor(colors.black)
    self.monitor.setTextColor(colors.white)
    self.monitor.setCursorPos(x + 1, y + 1)
    self.monitor.write(node.name)
    -- self.monitor.write("New Node")

    self.monitor.setTextColor(colors.green)
    self.monitor.setCursorPos(x + 1, y + 3)
    -- self.monitor.write(node.itemID)
    -- self.monitor.write(Util.firstToUpper(string.sub(node.itemID, string.find(node.itemID, ":") + 1, -1)))
    -- self.monitor.write(Util.firstToUpper(string.sub("minecraft:dirt", string.find('minecraft:', ":") + 1, -1)))
    self.monitor.write(Util.firstToUpper(string.sub(node.itemID, string.find(node.itemID, ":") + 1, -1)))

    -- self:writeQuantity(node.itemCount, node.maxItemCount, x + 1, y + 5)
    -- self:writeQuantity(10, 20, x + 1, y + 5, true)
    self:writeQuantity(node.itemCount, node.maxItemCount, x + 1, y + 5, true)
    -- self:writeTrend(node.nodeHistory.trend, x + 1, y + 5)
    -- self:writeTrend(15, x + 1, y + 6, true)
    self:writeTrend(node.nodeHistory.trend, x + 1, y + 6, true)
end

function Monitor:drawNodeLine(node, x, y)
end

return Monitor