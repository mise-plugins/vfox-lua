PLUGIN = {
    name = "lua",
    version = "0.1.0",
    homepage = "https://github.com/mise-plugins/vfox-lua",
    license = "MIT",
    description = "Lua version manager - compiles from source",
    minRuntimeVersion = "0.3.0",
    notes = {
        "Compiles Lua from source. Requires zig compiler (auto-installed via mise).",
        "Automatically installs LuaRocks for Lua 5.x versions.",
    },

    -- System prerequisites checked by mise before installing (see the `system_deps`
    -- setting). Detection is the source of truth; the `packages` map only provides
    -- remediation hints.
    systemDependencies = {
        { bin = "zig", packages = { brew = "zig", apt = "zig", dnf = "zig" } },
        { bin = "make", packages = { brew = "make", apt = "build-essential", dnf = "make" } },
    },
}
