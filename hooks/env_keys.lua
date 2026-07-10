--- Returns environment variables for Lua
--- @param ctx table Context provided by vfox
--- @return table Environment configuration
function PLUGIN:EnvKeys(ctx)
    local version = require("version")

    local sdkInfo = ctx.sdkInfo["lua"]
    local installDir = sdkInfo.path:gsub("\\", "/")
    local v = version.parse(sdkInfo.version)
    local shortVersion = v and (v.major .. "." .. v.minor)

    local envs = {
        { key = "PATH", value = installDir .. "/bin" },
        { key = "PATH", value = installDir .. "/luarocks" },
        { key = "PATH", value = installDir .. "/luarocks/bin" },
    }

    -- Set LUA_INIT for package paths (similar to asdf-lua)
    if shortVersion then
        local soext = (RUNTIME.osType == "windows") and "dll" or "so"

        local packagePath = string.format(
            "package.path = package.path .. ';%s/share/lua/%s/?.lua;%s/share/lua/%s/?/init.lua;%s/luarocks/share/lua/%s/?.lua;%s/luarocks/share/lua/%s/?/init.lua'",
            installDir,
            shortVersion,
            installDir,
            shortVersion,
            installDir,
            shortVersion,
            installDir,
            shortVersion
        )
        local packageCpath = string.format(
            "package.cpath = package.cpath .. ';%s/lib/lua/%s/?.%s;%s/luarocks/lib/lua/%s/?.%s'",
            installDir,
            shortVersion,
            soext,
            installDir,
            shortVersion,
            soext
        )

        table.insert(envs, {
            key = "LUA_INIT",
            value = packagePath .. "\n" .. packageCpath,
        })
    end

    return envs
end
