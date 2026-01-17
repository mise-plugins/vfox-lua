--- Compiles and installs Lua from source
--- @param ctx table Context provided by vfox
function PLUGIN:PostInstall(ctx)
    local http = require("http")
    local json = require("json")

    local version = ctx.version
    local installDir = ctx.rootPath
    local sdkPath = installDir .. "/" .. version

    -- Determine OS-specific make target
    local os_type = RUNTIME.osType
    local make_target = "guess"

    if os_type == "darwin" then
        make_target = "macosx"
    elseif os_type == "linux" then
        -- For Lua < 5.4, use "linux", otherwise "guess"
        local major, minor = string.match(version, "^(%d+)%.(%d+)")
        if major and minor then
            local ver_num = tonumber(major) * 100 + tonumber(minor)
            if ver_num < 504 then
                make_target = "linux"
            end
        end
    end

    -- Find the extracted directory
    local sourceDir = sdkPath .. "/lua-" .. version

    -- Build Lua
    local major = tonumber(string.match(version, "^(%d+)"))
    local buildCmd

    if major and major >= 5 then
        -- Lua 5.x: use make local target
        buildCmd = string.format(
            "cd '%s' && make %s && make local",
            sourceDir, make_target
        )
    else
        -- Older versions
        buildCmd = string.format(
            "cd '%s' && make && make install INSTALL_ROOT=install",
            sourceDir
        )
    end

    local status = os.execute(buildCmd)
    if status ~= 0 and status ~= true then
        error("Failed to build Lua: make failed")
    end

    -- Copy built files to install location
    local copyCmd
    local major_minor = string.match(version, "^(%d+%.%d+)")
    local ver_num = 0
    if major_minor then
        local maj, min = string.match(major_minor, "^(%d+)%.(%d+)")
        if maj and min then
            ver_num = tonumber(maj) * 100 + tonumber(min)
        end
    end

    if ver_num >= 502 then
        -- Lua 5.2+: files are in install/
        copyCmd = string.format("cp -r '%s/install/'* '%s/'", sourceDir, sdkPath)
    elseif ver_num >= 500 then
        -- Lua 5.0-5.1: files are in current directory after make local
        copyCmd = string.format("cp -r '%s/bin' '%s/include' '%s/lib' '%s/man' '%s/' 2>/dev/null || cp -r '%s/install/'* '%s/'",
            sourceDir, sourceDir, sourceDir, sourceDir, sdkPath, sourceDir, sdkPath)
    else
        -- Older versions
        copyCmd = string.format("cp -r '%s/install/'* '%s/'", sourceDir, sdkPath)
    end

    status = os.execute(copyCmd)
    if status ~= 0 and status ~= true then
        error("Failed to copy Lua files")
    end

    -- Install LuaRocks for Lua 5.x
    if major and major >= 5 then
        -- Get latest LuaRocks version from GitHub
        local luarocksVersion = "3.11.1" -- Default fallback

        local resp, err = http.get({
            url = "https://api.github.com/repos/luarocks/luarocks/tags?per_page=1",
        })

        if err == nil and resp.status_code == 200 then
            local data = json.decode(resp.body)
            if data ~= nil and type(data) == "table" and #data > 0 then
                local tag = data[1]["name"]
                if tag then
                    -- Remove 'v' prefix if present
                    luarocksVersion = string.gsub(tag, "^v", "")
                end
            end
        end

        -- Download and install LuaRocks
        local luarocksUrl = "https://luarocks.org/releases/luarocks-" .. luarocksVersion .. ".tar.gz"
        local luarocksArchive = sdkPath .. "/luarocks.tar.gz"

        local downloadCmd = string.format("curl -L '%s' -o '%s'", luarocksUrl, luarocksArchive)
        status = os.execute(downloadCmd)
        if status ~= 0 and status ~= true then
            -- LuaRocks installation is optional, don't fail
            return
        end

        local extractCmd = string.format("cd '%s' && tar xzf luarocks.tar.gz", sdkPath)
        status = os.execute(extractCmd)
        if status ~= 0 and status ~= true then
            return
        end

        local luarocksDir = sdkPath .. "/luarocks-" .. luarocksVersion
        local configureCmd = string.format(
            "cd '%s' && ./configure --with-lua='%s' --with-lua-include='%s/include' --with-lua-lib='%s/lib' --prefix='%s/luarocks'",
            luarocksDir, sdkPath, sdkPath, sdkPath, sdkPath
        )
        status = os.execute(configureCmd)
        if status ~= 0 and status ~= true then
            return
        end

        local bootstrapCmd = string.format("cd '%s' && make bootstrap", luarocksDir)
        status = os.execute(bootstrapCmd)
        -- Don't check status, LuaRocks is optional
    end

    -- Clean up source directory to save space
    local cleanCmd = string.format("rm -rf '%s' '%s/luarocks.tar.gz' '%s/luarocks-'*", sourceDir, sdkPath, sdkPath)
    os.execute(cleanCmd)
end
