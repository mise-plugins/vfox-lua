local os_type = RUNTIME.osType

local M = {}

M.sep = (os_type == "windows") and "\\" or "/"

function M.cp(src, dst)
    if os_type == "windows" then
        local f = io.open(src, "rb")
        if not f then
            return false, "source not found: " .. src
        end
        local content = f:read("*a")
        f:close()
        f = io.open(dst, "wb")
        if not f then
            return false, "cannot write: " .. dst
        end
        f:write(content)
        f:close()
        return true
    else
        local ok = os.execute("cp '" .. src .. "' '" .. dst .. "' 2>/dev/null")
        if ok ~= 0 and ok ~= true then
            return false, "cp failed: " .. src .. " -> " .. dst
        end
        return true
    end
end

function M.mkdir(path)
    if os_type == "windows" then
        os.execute("mkdir " .. path .. " 2>nul")
    else
        os.execute("mkdir -p '" .. path .. "' 2>/dev/null")
    end
end

function M.mv(src, dst)
    if os_type == "windows" then
        local ok, _ = pcall(os.rename, src, dst)
        if not ok then
            M.cp(src, dst)
            os.execute("del /f /q " .. src .. " 2>nul")
        end
    else
        local ok = os.execute("mv '" .. src .. "' '" .. dst .. "' 2>/dev/null")
        if ok ~= 0 and ok ~= true then
            M.cp(src, dst)
            os.execute("rm -rf '" .. src .. "' 2>/dev/null")
        end
    end
end

function M.listdir(path)
    local entries = {}
    if os_type == "windows" then
        local f = io.popen("dir /b " .. path .. " 2>nul")
        if f then
            for entry in f:lines() do
                table.insert(entries, entry)
            end
            f:close()
        end
    else
        local f = io.popen("ls -1 '" .. path .. "' 2>/dev/null")
        if f then
            for entry in f:lines() do
                table.insert(entries, entry)
            end
            f:close()
        end
    end
    return entries
end

function M.exists(path)
    local f, _, code = io.open(path)
    if code == 13 or code == 5 then
        return true
    end
    if f then
        f:close()
        return true
    end
    return false
end

function M.rm(path)
    if os_type == "windows" then
        os.execute("rmdir /s /q " .. path .. " 2>nul")
        os.execute("del /f /q " .. path .. " 2>nul")
    else
        os.execute("rm -rf '" .. path .. "' 2>/dev/null")
    end
end

return M
