-- shared/logger.lua  (ou server/logger.lua)
-- Module Logger global — doit être listé EN PREMIER dans fxmanifest.lua
-- sous la section server_scripts (ou shared_scripts).
--
-- Usage :
--   local log = Logger:child("MON_MODULE")
--   log:info("message")
--   log:warn("attention")
--   log:error("erreur")
--   log:debug("debug")  -- supprimé si Config.debug ~= true

local LEVELS = { debug = 0, info = 1, warn = 2, error = 3 }

local function getLevel()
    -- Respecte Config.debug si la config est déjà chargée, sinon info par défaut
    if _G.Config and Config.debug then return 0 end
    return 1
end

local function colorTag(level)
    -- Couleurs console FiveM (codes ANSI)
    if level == "error" then return "^1[ERROR]^7"
    elseif level == "warn"  then return "^3[WARN]^7"
    elseif level == "debug" then return "^5[DEBUG]^7"
    else                         return "^2[INFO]^7"
    end
end

-- ─── Constructeur ─────────────────────────────────────────────────────────────

Logger = {}
Logger.__index = Logger

function Logger:child(name)
    local child = setmetatable({}, Logger)
    child._name = name or "?"
    return child
end

function Logger:_log(level, msg)
    if LEVELS[level] < getLevel() then return end
    local tag = colorTag(level)
    print(("%s [%s] %s"):format(tag, self._name, tostring(msg)))
end

function Logger:info(msg)  self:_log("info",  msg) end
function Logger:warn(msg)  self:_log("warn",  msg) end
function Logger:error(msg) self:_log("error", msg) end
function Logger:debug(msg) self:_log("debug", msg) end
