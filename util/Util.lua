Util = { }

function Util.printTable(t)
    for key, value in pairs(t) do
        print('\t', key, value)
    end
end

function Util.containsValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function Util.abbreviateNumber(number)
    if (number > 1000000) then
        return math.floor(number / 100000) / 10 .. "m"
    elseif (number > 1000) then
        return math.floor(number / 100) / 10 .. "k"
    else
        return number .. ""
    end
end

function Util.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function Util.write(place, x, y, text)
    local i = 0
    for str in string.gmatch(text, "([^".."\n".."]+)") do
        place.setCursorPos(x, y + i)
        place.write(str)
        i = i + 1
    end
end

Util.colorMap = { ["0"] = colors.white, ["1"] = colors.orange, ["2"] = colors.magenta, ["3"] = colors.lightBlue, 
                  ["4"] = colors.yellow, ["5"] = colors.lime, ["6"] = colors.pink, ["7"] = colors.gray,
                  ["8"] = colors.lightGray, ["9"] = colors.cyan, ["a"] = colors.purple, ["b"] = colors.blue, 
                  ["c"] = colors.brown, ["d"] = colors.green, ["e"] = colors.red, ["f"] = colors.black }

function Util.drawIcon(place, x, y, isTextColor, char, image)
    place.setCursorPos(x, y)
    place.setTextColor(colors.black)
    place.setBackgroundColor(colors.black)
    local n = 1;
    for i = 1, #image do
        local c = image:sub(i,i)
        if (c == "n") then
            place.setCursorPos(x, y + n)
            n = n + 1
        else
            if (isTextColor) then place.setTextColor(Util.colorMap[c]) else
            place.setBackgroundColor(Util.colorMap[c]) end
            place.write(char)
        end
    end
end

function Util.isIn(x, y, x1, y1, x2, y2)
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

function Util.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

return Util