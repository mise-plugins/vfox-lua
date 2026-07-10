--- Compiles and installs Lua from source using the zig build system.
--- @param ctx table Context provided by vfox
--- @field ctx.sdkInfo table SDK information with version and path
function PLUGIN:PostInstall(ctx)
    local platform = require("platform")
    local version = require("version")
    local cmd = require("cmd")
    local http = require("http")
    local json = require("json")

    local sdkInfo = ctx.sdkInfo["lua"]
    local luaVersion = sdkInfo.version
    local sdkPath = sdkInfo.path
    local sep = platform.sep

    local function join(...)
        return table.concat({ ... }, sep)
    end

    local plug = RUNTIME.pluginDirPath

    -- Copy build.zig and readline shim into extracted source tree
    platform.mkdir(join(sdkPath, "readline"))

    local files = {
        "build.zig",
        "build.zig.zon",
        "lib/readline_shim.c",
        "lib/readline/readline.h",
        "lib/readline/history.h",
    }
    for _, f in ipairs(files) do
        local normal = f:gsub("/", sep)
        if not platform.cp(join(plug, normal), join(sdkPath, normal)) then
            error("Failed to copy " .. f)
        end
    end

    -- Build Lua via zig (compiles liblua.a, lua, luac, and installs headers)
    local ok, out = pcall(
        cmd.exec,
        "zig build --build-file " .. sdkPath .. sep .. "build.zig -Dreadline --prefix " .. sdkPath .. sep .. "install",
        { cwd = sdkPath }
    )
    if not ok then
        error("zig build failed:\n" .. out)
    end

    -- Move build artifacts from install/ to sdkPath root
    local installDir = join(sdkPath, "install")
    for _, entry in ipairs(platform.listdir(installDir)) do
        platform.mv(join(installDir, entry), join(sdkPath, entry))
    end

    -- Remove build artifacts and source files
    for _, item in ipairs({ "install", "zig-out", ".zig-cache", "zig-pkg", "build.zig", "build.zig.zon", "readline" }) do
        platform.rm(join(sdkPath, item))
    end

    -- Install LuaRocks for Lua 5.x
    local ver = version.parse(luaVersion)
    if ver and ver.major >= 5 then
        -- Get latest LuaRocks version from GitHub releases
        local luarocksVersion = "3.11.1" -- Default fallback

        local resp, err = http.get({
            url = "https://api.github.com/repos/luarocks/luarocks/releases/latest",
        })

        if err == nil and resp.status_code == 200 then
            local data = json.decode(resp.body)
            if data ~= nil and type(data) == "table" then
                local tag = data["tag_name"]
                if tag then
                    -- Remove 'v' prefix if present
                    luarocksVersion = string.gsub(tag, "^v", "")
                end
            end
        end

        -- Download and install LuaRocks
        local luarocksUrl = "https://github.com/luarocks/luarocks/archive/refs/tags/v" .. luarocksVersion .. ".tar.gz"
        local luarocksArchive = sdkPath .. sep .. "luarocks.tar.gz"

        local archiver = require("archiver")
        local _, dlerr = http.download_file({ url = luarocksUrl }, luarocksArchive)
        if dlerr then
            error("failed to download luarocks: " .. tostring(dlerr))
        end

        archiver.decompress(luarocksArchive, sdkPath)

        local luarocksDir = sdkPath .. sep .. "luarocks-" .. luarocksVersion

        if RUNTIME.osType == "windows" then
            -- Windows: use install.bat provided by LuaRocks
            local libName = "lua" .. luaVersion:match("^(%d+%.%d+)") .. ".lib"
            platform.cp(sdkPath .. sep .. "lib" .. sep .. "lua.lib", sdkPath .. sep .. "lib" .. sep .. libName)
            local ok, out = pcall(
                cmd.exec,
                sdkPath
                    .. sep
                    .. "bin"
                    .. sep
                    .. "lua.exe install.bat /LUA "
                    .. sdkPath
                    .. " /P "
                    .. sdkPath
                    .. sep
                    .. "luarocks /NOADMIN /NOREG /F",
                { cwd = luarocksDir }
            )
            if not ok then
                error("luarocks install failed:\n" .. out)
            end
        else
            -- Unix: configure + make bootstrap
            local ok, out = pcall(
                cmd.exec,
                "./configure --with-lua='"
                    .. sdkPath
                    .. "' --with-lua-include='"
                    .. sdkPath
                    .. "/include' --with-lua-lib='"
                    .. sdkPath
                    .. "/lib' --prefix='"
                    .. sdkPath
                    .. "/luarocks'",
                { cwd = luarocksDir }
            )
            if ok then
                local ok2, out2 = pcall(cmd.exec, "make bootstrap", { cwd = luarocksDir })
                if not ok2 then
                    error("luarocks build failed:\n" .. out2)
                end
            end
        end

        -- Clean up LuaRocks source and archive
        platform.rm(luarocksArchive)
        if platform.exists(luarocksDir) then
            platform.rm(luarocksDir)
        end
    end

    -- Clean up Lua source files, keeping only bin/, lib/, include/, share/
    for _, item in ipairs({ "src", "doc", "Makefile", "README" }) do
        platform.rm(sdkPath .. sep .. item)
    end
end
