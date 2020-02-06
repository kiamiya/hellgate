--- DWIPER is a stupid but effective dungeon wiper script, that shows many parts of API usage.
-- run it by pressing the "PAUSE/BREAK" key twice.
-- it tries to kill any mob it finds using the first skill in the bar.
-- uses a fuzzy decision engine for movement and targeting decisions.
-- TODO: waypoint support for Auto-Interactor
module("dwiper", package.seeall);

--[[ DEPENCIES ]]--
require("common/utils");
require("common/event");
require("common/api");
require("common/fuzzy");

--[[ LOGGER ]]--
require("common/log");
local function DEBUG(fmt, ...) log.DEBUG(_NAME, fmt, ...) end
local function INFO (fmt, ...) log.INFO (_NAME, fmt, ...) end
local function WARN (fmt, ...) log.WARN (_NAME, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(_NAME, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(_NAME, fmt, ...) end


--[[ BINDINGS ]]--
local GETOBJ = nil;
local GETOBJS = nil;
local GETPLAYER = nil;
local GETCOORDS = nil;
local NOTARGET = -1;
local MOVETO = function(x, y, z)end;
local ISMOVING = function() return false end;
local MOVESTOP = function()end;
local LOOKAT = function(x, y, z)end;
local FOCUS = function(id)end;
local MOVE_DELTA = 1.0;
local ATTACK = function(x, y, z)end;
local ATTACK_DIST = 2.0; 

if TARGET == "hell" then 
	require("hell_common/hell_env");
	require("hell_common/hell_skill");
	require("hell_common/hell_move");
	require("moveit");
	NOTARGET = -1;
	GETOBJ = hell_env.getEnvObj;
	GETOBJS = hell_env.getEnvObjects;
	GETPLAYER = hell_env.getPlayer;
	GETCOORDS = getCoords;
	MOVETO = moveit.moveTo;
	ISMOVING = hell_move.isMoving;
	MOVESTOP = hell_move.moveStop;
	LOOKAT = hell_cam.lookAt;
	FOCUS = function(id)end; -- not required for hell (think so)
	ATTACK = function(x, y, z) hell_skill.fire(hell_skill.getBar()[0].skillId, x, y, z) end
	ATTACK_DIST = 4.0;

elseif TARGET == "myth" then 
	require("hell_common/hell_env");
	require("hell_common/hell_skill");
	require("hell_common/hell_move");
	require("myth/myth_combat");
	NOTARGET = -1;
	GETOBJ = hell_env.getEnvObj;
	GETOBJS = hell_env.getEnvObjects;
	GETPLAYER = hell_env.getPlayer;
	GETCOORDS = getCoords;
	MOVETO = hell_move.moveTo;
	MOVESTOP = hell_move.moveStop;
	LOOKAT = myth_combat.lookAt;
	FOCUS = hell_env.target;
	--ATTACK = function(x, y, z) myth_combat.fireSkill("MeleeKick", x, y, z) end
	--ATTACK_DIST = 4.0;
	ATTACK = function(x, y, z) myth_combat.fireSkill( myth_skill.getBar()[0].skillId, x, y, z) end
	ATTACK_DIST = 4.0;
end

--[[ EVENTS ]]--
createEvent("DWIPER_TARGET");
createEvent("DWIPER_NOTARGET");
createEvent("DWIPER_ADDTARGET");
createEvent("DWIPER_DELTARGET");
createEvent("DWIPER_POIREACHED");
createEvent("DWIPER_ATTACK");
createEvent("DWIPER_NOMORETARGETS");

--[[ STATIC ]]--
local DWIPER_HANDLES = {};
local TARGETS = {};
local TARGET = NOTARGET;

-- registers a dwiper handle. this can be used for bulk registers/unregisters
local function registerHandle(eid, func)
	if DWIPER_HANDLES[eid] then
		unregister(DWIPER_HANDLES[eid]);
		DWIPER_HANDLES[eid] = nil;
	end
	DWIPER_HANDLES[eid] = register(eid, func);
end
-- removes all active callback handles
local function unregisterHandles()
	for k, v in pairs(DWIPER_HANDLES) do
		unregister(v);
	end
	DWIPER_HANDLES = {};
end

local function setTarget(id)
	TARGET = id;
	if TARGET == NOTARGET then 
		fire("DWIPER_NOTARGET");
		return;
	end

	if type(TARGETS[id]) ~= "table" then
		ERROR("trying to set unknown target %i", id);
		print_r(TARGETS[id]);
		return;
	end
	
	TARGETS[id].last_targeted = getCurrentMillis(); 
	fire("DWIPER_TARGET", nil, {id = id, obj = GETOBJ(id)});
	return;
end

-- we use a fuzzy decision to determine next target. rules are: 
-- MIN dist := obj.getDist()
-- MIN hp_precent := obj.getHealth()[1]
-- MIN hp_max := obj.getHealth()[3]
-- MAX vulnerable := (100-obj.getHealth()[1])/obj._dwiper.attack_count
local function getFuzzyComparators()
	-- FUZZY TARGET RULEZ
	local function comp_dist(obj_a, obj_b)
		return obj_a.getDist() - obj_b.getDist();	-- lower is better
	end
	local function comp_hp_precent(obj_a, obj_b)
		return obj_a.getHealth() - obj_b.getHealth();	-- lower is better
	end
	-- currently the only "can't be approached rule"
	-- TODO: improve, this does not take combat time into account 
	local function comp_time(obj_a, obj_b)	
		return obj_a._dwiper.target_time - obj_b._dwiper.target_time;	-- lower is better
	end
	return {comp_dist, comp_hp_precent, comp_time};
end

-- returns all current objects
local function getAllTargets()
	local all_targets = {}
	for id,dwiper_data in pairs(TARGETS) do
		local obj = GETOBJ(id);
		if obj then
			obj._dwiper = dwiper_data;	-- append our data to objetcs
			table.insert(all_targets, id, obj);
		end
	end
	return all_targets;
end

local function chooseTarget()	
	-- get all object to decide
	local all_targets = getAllTargets();
	local i = 0;
	for _,_ in pairs(all_targets) do
		i = i+1;
	end
	if i == 0 then
		return NOTARGET;
	end
	
	-- let fuzzy decide
	local decision = fuzzy.decide(all_targets, getFuzzyComparators());
	if not decision then return NOTARGET end
	INFO("decision[%i] %f %s", decision.id, decision._fuzzy, decision.model);
	
	-- save _fuzzy of decision for later re-check (objects are invalidated each tick. TARGETS[...] dwiper data not)
	TARGETS[decision.id].fuzzy = decision._fuzzy;
	TARGETS[decision.id].last_fuzzy = getCurrentMillis();
	
	return decision.id;
end

local function getTarget()
	if TARGET == NOTARGET then
		setTarget(chooseTarget());
	end
	return TARGET;
end

local function hasTarget()
	if (TARGET == NOTARGET or GETOBJ(TARGET) == nil) then
		TARGET = NOTARGET
		return false;
	else
		return true;
	end
end

local function isTarget(id)
	return (TARGET == id);
end

local function cancelTarget()
	TARGET = NOTARGET;
	fire("DWIPER_NOTARGET");
end

local function filterTarget(id)
	local obj = GETOBJ(id);
	if type(obj) ~= "table" then
		return true;
	end
	
	if not obj.isMob() then
		return true;
	end
	
	if not obj.isAlive() then
		return true;
	end
	
	return false;
end

local function addTarget(id)
	if TARGETS[id] ~= nil then return end
	if filterTarget(id) then return	end
	
	TARGETS[id] = {
		added = getCurrentMillis(),
		id = id,
		last_targeted = 0,
		last_moved = 0,
		last_attacked = 0,
		last_aggro = 0,
		last_fuzzy = 0,
		attack_count = 0,
		aggro_count = 0,
		target_time = 0,
	};
	
	fire("DWIPER_ADDTARGET", nil, {id = id, obj = GETOBJ(id)});
end

local function removeTarget(id)
	if TARGETS[id] == nil then return end
	
	TARGETS[id] = nil;
	if isTarget(id) then
		cancelTarget();
	end
	fire("DWIPER_DELTARGET", nil, {id = id});
	
	local i = 0;
	for _,_ in pairs(TARGETS) do
		i = i+1;
	end
	if i == 0 then
		fire("DWIPER_NOMORETARGETS");
	end
end

local function init_targets()
	for id, obj in pairs(GETOBJS()) do
		addTarget(obj.id);
	end
	
	local i = 0;
	for _,_ in pairs(TARGETS) do
		i = i+1;
	end
	if i == 0 then
		fire("DWIPER_NOMORETARGETS");
	end
end

-- here comes the fuzzy bot magic
local function ontick()
	-- chose a target if none exist
	local id = getTarget();
	if id == NOTARGET then return end
	
	-- fetch data
	local obj = GETOBJ(id);
	local data = TARGETS[id];
	if not obj or not obj.isAlive() then
		removeTarget(id);
		return; 
	end
	
	-- switch targets when needed.
	-- when is it needed? -> if fuzzyness got worse than for example +20% since chosen.
	-- because this is performance intense we dont want to check faster than once a second
	if getCurrentMillis() - data.last_fuzzy > 1000 then 
		data.last_fuzzy = getCurrentMillis();
		local all_targets = getAllTargets();
		local old_decision = all_targets[id];
		old_decision._fuzzy = TARGETS[id].fuzzy;	-- restore fuzzy state (deleted each Lua tick)
		local new_fuzzy = fuzzy.check(all_targets, old_decision, getFuzzyComparators())
		if new_fuzzy > 0.2 then
			INFO("cancel[%i] old_fuzzy:%f new_fuzzy:%f  [%i] %s", old_decision.id, old_decision._fuzzy, new_fuzzy, old_decision.id, old_decision.model);
			cancelTarget();
			return;
		else
			INFO("check [%i] old_fuzzy:%f new_fuzzy:%f  [%i] %s", old_decision.id, old_decision._fuzzy, new_fuzzy, old_decision.id, old_decision.model);
		end
	end

	-- inc target_time
	data.target_time = getCurrentMillis() - data.last_targeted; 
	
	-- lock target
	FOCUS(id);
	
	-- aim to it
	LOOKAT(obj.x, obj.y, obj.z);
	
	-- move to it
	local px, py, pz = GETCOORDS();
	local tx, ty, tz = obj.getCoords();
	local dist = math.vecDist(px, py, pz, tx, ty, tz);
	
	-- check poi reached (needs to be processed by other scripts)
	if data.poi and dist < MOVE_DELTA then
		removeTarget(id);
		fire("DWIPER_POIREACHED", nil, {id = id, obj = obj});
		return; 
	end 
	
	-- within range. attack it
	if dist < ATTACK_DIST and not data.poi then
		MOVESTOP();
		ATTACK(tx, ty, tz);
		data.last_attacked = getCurrentMillis();
		data.attack_count = data.attack_count + 1;
		fire("DWIPER_ATTACK", nil, {id = id, obj = obj});
		return;
	end
	
	-- move towards it
	if dist > ATTACK_DIST and not ISMOVING() then
		MOVETO(tx, ty, tz);
		data.last_moved = getCurrentMillis();
		return;
	end
end

--[[ CTL ]]--
-- stops dungeonwiper
function stop()
	INFO("STOPPING DUNGEON-WIPER");
	unregisterHandles();
	MOVESTOP();
end
-- restarts dungeonwiper
function restart()
	unregisterHandles();
	start();
end
-- starts dungeonwiper
function start()
	INFO("STARTING DUNGEON-WIPER");
	unregisterHandles();
	
	TARGETS = {};
	TARGET = NOTARGET;
	
	registerHandle(event.API_GAMESTATE, function(e)
		restart();
	end);
	
	registerHandle(event.ENV_MOVE, function(e)
		addTarget(e.id);
	end);
	
	registerHandle(event.ENV_AGGRO, function(e)
		if e.obj2.id ~= GETPLAYER().id then return end	-- i am not aggroed
		addTarget(e.id)
		
		if TARGETS[e.id] then
			local data = TARGETS[e.id];
			data.last_aggro = getCurrentMillis();
			data.aggro_count = data.aggro_count + 1;
		end
	end);
	
	registerHandle(event.ENV_DIES, function(e)
		removeTarget(e.id);
	end);
	
	registerHandle(event.ONTICK, function(e)
		ontick(e.elapsed);
	end);
	
	-- some traceing info
	registerHandle("DWIPER_ADDTARGET", function(e)
		INFO("DWIPER_ADDTARGET: [%i] %s", e.id, e.obj.model);
	end)
	
	registerHandle("DWIPER_TARGET", function(e)
		INFO("DWIPER_TARGET: [%i] %s", e.id, e.obj.model);
	end);
	
	registerHandle("DWIPER_DELTARGET", function(e)
		INFO("DWIPER_DELTARGET: [%i]", e.id);
	end);
	
	registerHandle("DWIPER_NOMORETARGETS", function(e)
		INFO("DWIPER_NOMORETARGETS");
	end);
	
	init_targets();
end

--[[ event registers ]]--
-- kill trigger on event.PAUSE
register("PAUSE", function(e)
	if api.status.ingame() then
		if (e.pause) then 
			stop();
		else
			start();
		end
	end
end);
-- stop when entered a new map
register("API_INGAME", function(e)
	-- stop();
end);

