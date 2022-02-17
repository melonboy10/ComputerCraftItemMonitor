--[[
GitHub downloading utility for CC.
Developed by apemanzilla.
 
This requires ElvishJerricco's JSON parsing API.
Direct link: http://pastebin.com/raw.php?i=4nRg9CHU
]]--

local user = "melonboy10"
local repo = "SeedlessItemMonitor"
local branch = "master"
local path = "seedless"
 
local function save(data,file)
    local file = shell.resolve(file:gsub("%%20"," "))
    if not (fs.exists(string.sub(file,1,#file - #fs.getName(file))) and fs.isDir(string.sub(file,1,#file - #fs.getName(file)))) then
        if fs.exists(string.sub(file,1,#file - #fs.getName(file))) then fs.delete(string.sub(file,1,#file - #fs.getName(file))) end
        fs.makeDir(string.sub(file,1,#file - #fs.getName(file)))
    end
    local f = fs.open(file,"w")
    f.write(data)
    f.close()
end
 
local function download(url, file)
    save(http.get(url).readAll(),file)
end
 
if not json then
    download("http://pastebin.com/raw.php?i=4nRg9CHU","json")
    os.loadAPI("json")
end
 
print("Downloading files from GitHub...")
local data = json.decode(http.get("https://api.github.com/repos/"..user.."/"..repo.."/git/trees/"..branch.."?recursive=1").readAll())
if data.message and data.message:find("API rate limit exceeded") then error("Out of API calls, try again later") end
if data.message and data.message == "Not found" then error("Invalid repository", 2) else
    for k,v in pairs(data.tree) do
        -- Make directories
        if v.type == "tree" then
            fs.makeDir(fs.combine(path, v.path))
        end
    end
    local drawProgress
    local _, y = term.getCursorPos()
    local wide, _ = term.getSize()
    term.setCursorPos(1, y)
    term.write("[")
    term.setCursorPos(wide - 6, y)
    term.write("]")
    drawProgress = function(done, max)
        local value = done / max
        term.setCursorPos(2,y)
        term.write(("="):rep(math.floor(value * (wide - 8))))
        local percent = math.floor(value * 100) .. "%"
        term.setCursorPos(wide - percent:len(),y)
        term.write(percent)
    end

    local filecount = 0
    local downloaded = 0
    local paths = {}
    local failed = {}
    for k,v in pairs(data.tree) do
        -- Send all HTTP requests (async)
        if (v.path ~= "README.md" and v.path ~= ".gitignore" and v.path ~= "Installer.lua") then
            if v.type == "blob" then
                v.path = v.path:gsub("%s","%%20")
                local url = "https://raw.github.com/"..user.."/"..repo.."/"..branch.."/"..v.path, fs.combine(path, v.path)
                http.request(url)
                if (v.path == "startup.lua") then
                    paths[url] = fs.combine("", v.path)
                else
                    paths[url] = fs.combine(path, v.path)
                end
                filecount = filecount + 1
            end
        end
    end
    while downloaded < filecount do
        local e, a, b = os.pullEvent()
        if e == "http_success" then
            save(b.readAll(), paths[a])
            downloaded = downloaded + 1
            drawProgress(downloaded, filecount)
        elseif e == "http_failure" then
            -- Retry in 3 seconds
            failed[os.startTimer(3)] = a
        elseif e == "timer" and failed[a] then
            http.request(failed[a])
        end
    end
end
print("Done")