# vfox-lua

A [vfox](https://github.com/version-fox/vfox) / [mise](https://mise.jdx.dev) plugin for managing [Lua](https://www.lua.org/) versions.

## Features

- **Dynamic version fetching**: Automatically fetches available versions from lua.org
- **Always up-to-date**: No static version list to maintain
- **Compiles from source**: Uses official Lua source releases
- **LuaRocks included**: Automatically installs LuaRocks for Lua 5.x versions
- **Cross-platform**: Works on Linux and macOS

## Requirements

- A C compiler (gcc or clang)
- make
- curl

### macOS

```bash
xcode-select --install
```

### Debian/Ubuntu

```bash
sudo apt-get install build-essential libreadline-dev
```

### RHEL/CentOS

```bash
sudo yum groupinstall "Development Tools"
sudo yum install readline-devel
```

## Installation

### With mise

```bash
mise install lua@latest
mise install lua@5.4.8
mise install lua@5.3.6
```

### With vfox

```bash
vfox add lua
vfox install lua@latest
```

## Usage

```bash
# List all available versions
mise ls-remote lua

# Install a specific version
mise install lua@5.4.8

# Set global version
mise use -g lua@5.4.8

# Set local version (creates .mise.toml)
mise use lua@5.4.8
```

## Environment Variables

This plugin sets the following environment variables:

- `PATH` - Adds the Lua bin directory and LuaRocks bin directory
- `LUA_INIT` - Configures package.path and package.cpath for LuaRocks modules

## How It Works

This plugin:

1. Fetches the list of available versions from [lua.org/ftp](https://www.lua.org/ftp/)
2. Downloads the source tarball for the requested version
3. Compiles Lua from source using `make`
4. Installs LuaRocks (for Lua 5.x versions)

## License

MIT License - see [LICENSE](LICENSE) for details.
