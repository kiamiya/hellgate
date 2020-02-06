--- this module enables movement for generic routing data.
--  usage: moveit.moveTo(-36.62, 97.95, 2.86)
--
-- <p>
-- <h2>This module defines the following events</h2><hr />
-- <ul>
-- <li><b>MOVEIT_STARTED </b><br /> fired when moveit starts to work </li>
-- <li><b>MOVEIT_REACHED </b><br /> fired when moveit reached a destination</li>
-- <li><b>MOVEIT_STOPPED </b><br /> fired when moveit stops to work</li>
-- <li><b>MOVEIT_BLOCKED </b><br /> fired when moveit detects a block</li>
-- </ul>
-- </p>
module("moveit", package.seeall);

--[[ include any depencies ]]--
require("common/utils");
require("common/event");

require("common/astar");
require("hell_common/hell_map");
require("hell_common/hell_move");
require("hell/hell_cam");

--[[ logger shortcuts ]]--
require("common/log");
local function DEBUG(fmt, ...) log.DEBUG(_NAME, fmt, ...) end
local function INFO (fmt, ...) log.INFO (_NAME, fmt, ...) end
local function WARN (fmt, ...) log.WARN (_NAME, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(_NAME, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(_NAME, fmt, ...) end

--[[ STATIC ]]--
local DELTA = 0.5;
local moveitData = nil;
local moveitHandle = nil;

--[[ EVENTS ]]--
createEvent("MOVEIT_REACHED");
createEvent("MOVEIT_STARTED");
createEvent("MOVEIT_STOPPED");
createEvent("MOVEIT_BLOCKED");

--- starts the a-star movement algorithm to the requested destination
-- @param tx the coords
-- @param delta OPTIONAL the grid resolution to use. default 1.0
-- @return true if rout found and movement has started. false if no route has been found
function moveTo(tx, ty, tz, delta)
	if not (type(tx) == "number" and type(ty) == "number" and type(tz) == "number") then
		ERROR("moveTo(tx, ty, tz) invalid agruments. all need to be numbers");
		return;
	end
	if not delta then
		delta = DELTA;
	end
	
	-- stop currently active route
	moveStop(false);
	
	-- current coordinated
	local cx,cy,cz = hell_map.getCoords();
	-- delta vector from start to target
	local dx, dy, dz = math.vecDelta(cx, cy, cz,  tx, ty, tz);
	local dist = math.vecAbs(dx, dy, dz);
	
	--astar.DELTA = DELTA;
	--astar.DXDEBUG = true;
	--astar.DXCONVERT = function(x,y,z)
	--	return x,y,z;
	--end

	-- call routing algo
	local route = astar.route(cx, cy, cz,  tx, ty, tz, hell_env.checkCollision, delta);
	--print_r(route);
	
	-- set current route active
	if type(route) == "table" and type(route[1]) == "table" then
		moveitData = route[1];
		moveitHandle = register(event.ONTICK, doMove);
		event.fire(event.MOVEIT_STARTED);
		return true;
	else
		--WARN("routing module returned no route to target: %f %f %f", tx,ty,tz);
		event.fire(event.MOVEIT_BLOCKED);
		return false;
	end
end

-- moves towards current next routing node
function doMove()
	if not moveitData or not moveitHandle or not isIngame() or isPaused() then
		moveStop(true);
		return;
	end
	
	-- check if already close enouth to one of the next nodes
	local cx, cy, cz = hell_map.getCoords();
	local node = moveitData;
	repeat
		local dist = math.vecDist(cx, cy, cz, node.x, node.y, node.z);
		if  dist <= node.delta then
			moveitData = node.next;
		end
		node = node.next;
	until node == nil
	
	if moveitData == nil then 
		moveStop(false);
		event.fire(event.MOVEIT_REACHED);
		return;
	end
	
	--INFO("lookAt: %f %f %f",moveitData.x, moveitData.y, moveitData.z);
	--print_r(moveitData);
	hell_cam.lookAt(moveitData.x, moveitData.y, moveitData.z);
	hell_move.moveForwardStart();
end

--- stops the moveitHandle
function moveStop(fireEvent)
	if moveitHandle then
		unregister(moveitHandle);
		moveitHandle = nil;
		moveitData = nil;
		hell_move.moveStop();
		
		if fireEvent then event.fire(event.MOVEIT_STOPPED) end
	end
end

-- kill trigger on event.PAUSE
register(event.PAUSE, function(e)
	if (e.pause) then moveStop(true) end
end);

