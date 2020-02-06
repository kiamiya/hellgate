module("SHBot", package.seeall);

require("common/log");
require("common/utils");
require("common/event");
require("common/utils");
require("common/persistence");
require("hell/hell");
require("hell/hell_cam");
require("hell_common/hell_global");
require("hell_common/hell_env");
require("hell_common/hell_move");
require("hell_common/hell_skill");
require("hell_common/hell_map");
require("hell_common/hell_char");
require("hell/hell_chat");

local CHAR_NAME = "canamule";
local IS_BEAST = 0;
local IS_NECRO = 1;
local DIFFICULTY = 0; -- 0 : Normal, 1 : Nightmare, 2 : Hell
local delay_after_strike = 20000; -- nb secondes avant retour 15000 = 15s
local SKILL_NUMBER = 0; -- numero du skill dans la bar. commence a 0. 10 = avant dernier
local delay_backward = 1400; 
local CURRENT_MAP = hell_map.getMapName();
local SH_MAPID = 'Stonehenge';
local SH_WARP_X = 40;
local SH_WARP_Y = -3;
local SH_WARP_Z = 10;
local DIGITS = 0;
local x_dodge = 2.6;
--local x_dodge = 2.5;
local y_dodge = 8;
local movebot_handle = nil;
local movebot_handle_map = nil;
local movebot_handle_center = nil;
local movebot_handle_frontmap = nil;
local movebot_handle_inwarp = nil;
local movebot_handle_inmap = nil;
local movebot_map_firstleft = nil;
local movebot_map_waitback = nil;
local i = 1;
local mapwarp_x = nil;
local mapwarp_y = nil;
local mapwarp_z = nil;
local afterleft_x = nil;
local afterleft_y = nil;
local afterleft_z = nil;
local cam_offset_y = 3.5;
local xcam, ycam = 0;
local j = 0;
local tick = 0;
local flag_emergency = 0;
local xp_before_run = 0;
local xp_after_run = 0;
local FRIEND_ON_MAP = false;

local movebot_handle_check_isdead = nil;
local movebot_handle_on_death = nil;
local CHAR_ISDEAD = false;
local WARP_FAIL = false;
local z = 1;
local ticktock = 0;
local ticktack = 0;
--[[ logger shortcuts ]]--
local mod = 'SHBot';
local function DEBUG(fmt, ...) log.DEBUG(mod, fmt, ...) end
local function INFO (fmt, ...) log.INFO (mod, fmt, ...) end
local function WARN (fmt, ...) log.WARN (mod, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(mod, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(mod, fmt, ...) end

local function roundCoords(x,y,z)
	return math.round(x, DIGITS), math.round(y, DIGITS), math.round(z, DIGITS);
end
local function move(x, y, z)
	if isPaused() then return end
	if not (x and y and type(x) == "number" and type(y) == "number" ) then
		ERROR("move(x, y, z) supplied args are not numbers");
		unregister(movebot_handle);
		return;
	end
	-- third arg is opt. take current z
	if not (z and type(z) == "number") then
		local foo, bar, foobar = hell_map.getCoords();
		z = foobar;
	end
	
	cx, cy, cz = roundCoords(hell_map.getCoords()); --getting current position
	dx, dy, dz = roundCoords(x, y, z);
	if(dx == cx and dy == cy and dz == cz) then
		hell_move.moveStop();
		--INFO("move x:"..cx.." y:"..cy.." z:"..cz.." reached");
		unregister(movebot_handle);
		movebot_handle = nil;
		--moveTo(44.26,-43.08,6.46);
		return;
	else
		--vx, vy, vz = (hell_env.checkCollision(x, y, z));
		vx = dx;
		vy = dy;
		vz = dz;
		dx, dy, dz = roundCoords(x, y, z);
		if(vx == dx and vy == dy and vz == dz) then
			--INFO("move x:"..dx.." y:"..dy.." z:"..dz.." can be reached without collision");
			hell_cam.lookAt(x, y, z);
			hell_move.moveForwardStart();
		else
			--INFO("move Collision at x:"..vx.." y:"..vy.." z:"..vz);
			unregister(movebot_handle);
			movebot_handle = nil;
			return;
		end
	end
end

function moveTo(x, y, z)
	if not movebot_handle then
		movebot_handle = register(event.ONTICK, function() move(x, y, z) end);
	end
end

function moveStop()
	if movebot_handle then
		unregister(movebot_handle);
		movebot_handle = nil;
		hell_move.moveStop();
	end
end

function thenMoveToCenter(x, y , z)
	local ismoving = hell_move.isMoving();
	local xmap_x, xmap_y, xmap_z = 0;
	if ismoving == false then
		moveTo(x,y,z);
		unregister(movebot_handle_center);
		if IS_BEAST == 1 then
			xmap_x = 17.09
			xmap_y = -53.05
			xmap_z = 5.93
		end
		if IS_NECRO == 1 then
			xmap_x = 62.75
			xmap_y = -76.01
			xmap_z = 5.93
		end
		movebot_handle_map = register(event.ONTICK, function() thenMoveToMap(xmap_x,xmap_y,xmap_z) end);
		return 0;
	end
end

function thenMoveToMap(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		moveTo(x,y,z);
		hell_global.setDifficulty(DIFFICULTY);
		unregister(movebot_handle_map);
		
		if IS_BEAST == 1 then
			movebot_handle_frontmap = register(event.ONTICK, function() frontMapBeast() end);
		end
		if IS_NECRO == 1 then
			movebot_handle_frontmap = register(event.ONTICK, function() frontMapNecro() end);
		end
		return 0;
	end
end

function frontMapBeast()
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		hell_global.resetInstance();
		unregister(movebot_handle_frontmap);
		moveTo(13.74,-52.99,5.93);
		movebot_handle_inwarp = register(event.ONTICK, function() inWarp() end);
		return 0;
	end
end

function frontMapNecro()
	ticktack = 0;
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		hell_global.resetInstance();
		unregister(movebot_handle_frontmap);
		--INFO("FRONT MAP MOVE");
		
		if i==1 or CHAR_ISDEAD == true or WARP_FAIL == true then
			moveTo(64.19,-79.91,5.93);
		else
			hell_move.moveBackwardStart();
			delay(650, function() 
				hell_move.moveStop();
			end);
		end
		movebot_handle_inwarp = register(event.ONTICK, function() inWarp() end);
		return 0;
	end
end

function inWarp()
	ticktack = ticktack + 1;
	local ismoving = hell_move.isMoving();
	flag_emergency = 0 ;
	tick = 0;
	FRIEND_ON_MAP = false;
	CHAR_ISDEAD = false;
	
	if ismoving == false then
		local state = hell_global.getGamestate();
		if state == 9 then
			hell_cam.setCam(0,0);
			hell_cam.setCam(-2.12,0);
		end
		if state == 8 then
			--INFO("ON MAP");
			moveStop();
			unregister(movebot_handle_inwarp);
			movebot_handle_inmap = register(event.ONTICK, function() inMap() end);
		end
	end
	if ismoving == false and ticktack > 800 then
		INFO("RETRY WARP TO MAP");
		--hell_move.moveLeftStart();
		--delay(150, function() 
		--	hell_move.moveStop();
		--end);
		--moveTo(64.10,-79.50,5.93);
		unregister(movebot_handle_inwarp);
		ticktack = 0;
		WARP_FAIL = true
		moveStop();
		delay(1000, function() 
			hell_global.sendCommand("/stuck");
			delay(14000, function() 
				frontMapNecro();
			end);
		end);
	end
end


function inMap()
	local a = hell_map.getMapName();
	local state = hell_global.getGamestate();
	if a ~= SH_MAPID and state == 9 then
		--if FRIEND_ON_MAP == true then
		WARP_FAIL = false;
		delay(500, function() 
			--mapwarp_x, mapwarp_y, mapwarp_z =  roundCoords(hell_map.getCoords());
			doRun();
		end);
		unregister(movebot_handle_inmap);
		--end
	end
end



function doRun()
	local cx, cy, cz = roundCoords(hell_map.getCoords());
	--1st left
	hell_move.moveStop();
	hell_move.moveLeftStart();
	delay(300, function() 
		hell_move.moveStop();
	end);
	ticktock = 0;
	--moveTo((cx+x_dodge),cy);
	--go forward
	movebot_map_firstleft = register(event.ONTICK, function() mapFirstLeft() end);
end



function mapFirstLeft(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false and j==0 then
		afterleft_x, afterleft_y, afterleft_z = roundCoords(hell_map.getCoords());
		local cx, cy, cz = roundCoords(hell_map.getCoords());
		--go forward
		xcam, ycam = hell_cam.getCam();
		hell_cam.setCam(1.5,ycam);
		hell_move.moveForwardStart();
		delay(1600, function() 
			hell_move.moveStop();
			xcam, ycam = hell_cam.getCam();
			--hell_cam.setCam(xcam,(ycam-cam_offset_y));
			local skill = SKILL_NUMBER;
			if pcall(function() hell_skill.fireBar(skill) end) then
			else
				INFO("ERROR CAST SKILL");
			end
			movebot_map_waitback = register(event.ONTICK, function() waitAndBack() end);
		end);
		j = 1;
		return 0;
	end
end

function waitAndBack()
	delay(delay_after_strike, function()
		unregister(movebot_map_firstleft);
		hell_cam.setCam(xcam,ycam);
		hell_move.moveBackwardStart();
		
		delay(2000, function() 
			hell_move.moveStop();
			hell_move.moveRightStart();
			delay(400, function() 
				hell_move.moveStop();
				hell_move.moveBackwardStart();
				delay(delay_backward, function() 
					hell_move.moveStop();
					local state = hell_global.getGamestate();
					if state == 9 then
						hell_cam.setCam(0,0);
					end
					movebot_handle_outmap = register(event.ONTICK, function() outMap() end);
				end);
			end);
		end);
	end);
	unregister(movebot_map_waitback);
end

function outMap()
	if movebot_map_waitback ~= nil then
		unregister(movebot_map_waitback);
	end
	local a = hell_map.getMapName();
	tick = tick + 1;
	if a == SH_MAPID then
		local cx, cy, cz = roundCoords(hell_map.getCoords());
		if (cx == SH_WARP_X and cy == SH_WARP_Y and cz == SH_WARP_Z) then
			INFO("RUN %d DONE",i);
			j = 0;
			i = i +1;
			CHAR_ISDEAD = false;
			movebot_handle_center = register(event.ONTICK, function() thenMoveToCenter(44.26,-43.08,6.46) end);
			unregister(movebot_handle_outmap);
		else
			CHAR_ISDEAD = false;
			hell_move.moveStop();
			INFO("RUN %d DONE",i);
			delay(7000, function() 
				j = 0;
				i = i +1;
				if IS_BEAST == 1 then
					frontMapBeast();
				end
				if IS_NECRO == 1 then
					frontMapNecro();
				end
			end);
			unregister(movebot_handle_outmap);
		end
	else if a == "Skull Step" then
		if tick > 150 and flag_emergency == 0 and CHAR_ISDEAD == false then
			INFO("TRY EMERGENCY EXIT");
			local mana = hell_char.getData()["Current Power"];
			mana = mana * 1;
			if mana > 111 then
				hell_skill.fireBar(1);
				flag_emergency = 1;
				delay(1000, function() 
					hell_global.sendCommand("/stuck");
					delay(14000, function() 
						hell_move.moveBackwardStart();
						delay(800, function() 
							hell_move.moveStop();
							local state = hell_global.getGamestate();
							if state == 9 then
								hell_cam.setCam(0,0);
							end
						end);
					end);
				end);
			end
			tick = 0;
		end
		if tick > 500 and flag_emergency == 1 and CHAR_ISDEAD == false then
			INFO("RETRY EMERGENCY EXIT");
			delay(1000, function() 
				hell_global.sendCommand("/stuck");
				delay(14000, function() 
					hell_move.moveBackwardStart();
					delay(800, function() 
						hell_move.moveStop();
						local state = hell_global.getGamestate();
						if state == 9 then
							hell_cam.setCam(0,0);
						end
					end);
				end);
			end);
			tick = 0;
		end
	end	end
end

function start()
	--check current map
	local a = hell_map.getMapName();
	if a ~= SH_MAPID then
		INFO("MUST BE ON STONEHENGE");
		return;
	else
		if DIFFICULTY == 0 then
			mode = "Normal";
		end
		if DIFFICULTY == 1 then
			mode = "Nightmare";
		end
		if DIFFICULTY == 2 then
			mode = "Hell";
		end
		if IS_BEAST == 1 then
			INFO("BOT START MAP BEAST : %s",mode);
		end
		if IS_NECRO == 1 then
			INFO("BOT START MAP NECRO : %s",mode);
		end
		--check current position, must be at warp
		local cx, cy, cz = roundCoords(hell_map.getCoords());
		if (cx == SH_WARP_X and cy == SH_WARP_Y and cz == SH_WARP_Z) then
			--move to right
			moveTo(45.14,-7.45,9.41);
		end
		movebot_handle_center = register(event.ONTICK, function() thenMoveToCenter(44.26,-43.08,6.46) end);
		movebot_handle_check_isdead = register(event.ONTICK, function() checkisDead() end);
		movebot_handle_on_death = register(event.ENV_DIES, function(e) onDeath(e) end);
	end
end

function checkisDead()
	
	if CHAR_ISDEAD == true and z == 1 then
		local str = "REVIVE IN TOWN IN 8s";
		INFO(str);
		delay(8000, function() 
			INFO("RUN CALLBACK RESTART TOWN");
			hell_gui.runCallback("UIOnButtonDownRestartTown");
		end);
		z = z + 1;
	end
	if CHAR_ISDEAD == true then
		ticktock = ticktock + 1;
	end
	if CHAR_ISDEAD == true and ticktock > 250 then
		ticktock = 0;
		INFO("RETRY REVIVE TOWN")
		hell_gui.runCallback("UIOnButtonDownRestartTown");
	end
end


function onDeath(e)
	local obj = e.obj;
	if obj.isPlayer() == true then
		if e.obj["name"] == CHAR_NAME then
			local str = e.obj["name"] .. " DIED";
			INFO(str);
			z = 1;
			CHAR_ISDEAD = true;
		end
	end
end

-- start when ready
--register(event.CHAT_RECV, function(e)
	--DEBUG(e);
--end);


-- start when ready
register("STARTUP", function()
	SHBot.start()
end);