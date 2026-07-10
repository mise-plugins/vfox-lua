local M = {}

function M.parse(s)
    local major, minor, patch = string.match(s, "^(%d+)%.?(%d*)%.?(%d*)$")
    if not major then
        return nil
    end
    return {
        major = tonumber(major),
        minor = tonumber(#minor > 0 and minor or 0),
        patch = tonumber(#patch > 0 and patch or 0),
    }
end

return M
