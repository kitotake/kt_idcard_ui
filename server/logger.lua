-- server/logger.lua
-- Module Logger global côté SERVEUR
-- Doit être listé EN PREMIER dans server_scripts du fxmanifest.lua

local LEVELS = { debug = 0, info = 1, warn = 2, error = 3 }

local function getLevel()
    if _G.Config and Config.debug then return 0 end
    return 1
end

local function colorTag(level)
    if level == "error" then return "^1[ERROR]^7"
    elseif level == "warn"  then return "^3[WARN]^7"
    elseif level == "debug" then return "^5[DEBUG]^7"
    else                         return "^2[INFO]^7"
    end
end

Logger = {}
Logger.__index = Logger

function Logger:child(name)
    local child = setmetatable({}, Logger)
    child._name = name or "?"
    return child
end

function Logger:_log(level, msg)
    if LEVELS[level] < getLevel() then return end
    print(("%s [%s] %s"):format(colorTag(level), self._name, tostring(msg)))
end

function Logger:info(msg)  self:_log("info",  msg) end
function Logger:warn(msg)  self:_log("warn",  msg) end
function Logger:error(msg) self:_log("error", msg) end
function Logger:debug(msg) self:_log("debug", msg) end
