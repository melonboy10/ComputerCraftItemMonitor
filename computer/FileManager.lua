local fs        = _G.fs
local textutils = _G.textutils

local FileManager = { }

function FileManager.read(name)
    local file = fs.open("seedless/saves/" .. name .. ".txt", "r")

    if (file == nil) then
        -- print("No File Found for " .. name)
        return nil
    else
        local lines = ""
        while true do
            local line = file.readLine()
            if not line then break end
            lines = lines .. line
        end
        file.close()

        if (lines == "") then return nil end
        return lines
    end
end

function FileManager.write(name, table)
    local file = fs.open("seedless/saves/" .. name .. ".txt", "w")
    file.write(textutils.serialise(table))
    file.close()
end

return FileManager