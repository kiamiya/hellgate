--- myth examples module
--
module("examples_sro", package.seeall);

--[[ include any depencies ]]--
require("sro/sro");
require("common/event");
require("common/utils");

--[[ logger shortcuts ]]--
require("common/log");
local function DEBUG(fmt, ...) log.DEBUG(_NAME, fmt, ...) end
local function INFO (fmt, ...) log.INFO (_NAME, fmt, ...) end
local function WARN (fmt, ...) log.WARN (_NAME, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(_NAME, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(_NAME, fmt, ...) end

-- start something when mmbbq is loaded
--register("STARTUP", function(e)
--	INFO("STARTUP fired");
--end);

