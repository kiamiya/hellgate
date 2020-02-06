module("SHBot", package.seeall);
require("common/log");
require("common/utils");
require("common/event");
require("common/utils");
require("common/persistence");
require("common/userinput");
require("hell/hell");
require("hell/hell_cam");
require("hell_common/hell_global");
require("hell_common/hell_env");
require("hell_common/hell_move");
require("hell_common/hell_skill");
require("hell_common/hell_map");
require("hell_common/hell_char");
require("hell/hell_chat");

-- F5	BOT active/desactive
-- F6	DIFFICTULTY change
-- F7	SELLRUN active/desactive
-- F8	BICRAVE AUTO active/desactive

local autostart = false;	-- auto start BOT
local FRIEND_TIMEOUT = 4;	-- friend timeout (min)
local RUN_SELL = 400;
local DIFFICULTY = 2; -- 0 : Normal, 1 : Nightmare, 2 : Hell
local delay_after_strike = 15000; -- nb secondes avant retour 15000 = 15s
local SKILL_NUMBER = 0; -- numero du skill dans la bar. commence a 0. 10 = avant dernier
local delay_backward = 1400; 
local MODE = "solo";
local IS_BEAST = 0;
local IS_NECRO = 1;
local CHAR_NAME = "";
local SH_MAPID = 'Stonehenge';
local SH_WARP_X = 40;
local SH_WARP_Y = -3;
local SH_WARP_Z = 10;
local DIGITS = 0;
local skill_engi = 163;
local x_dodge = 2.6;
local y_dodge = 8;
local tabledata_mob = {};
local movebot_handle = nil;
local movebot_handle_map = nil;
local movebot_handle_center = nil;
local movebot_handle_frontmap = nil;
local movebot_handle_inwarp = nil;
local movebot_handle_inmap = nil;
local movebot_map_firstleft = nil;
local movebot_map_waitback = nil;
local movebot_handle_outmap = nil;
local mob_handle_sfx = nil;
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
local sellrun=0;
local movebot_handle_check_isdead = nil;
local movebot_handle_on_death = nil;
local CHAR_ISDEAD = false;
local WARP_FAIL = false;
local z = 1;
local ticktock = 0;
local ticktack = 0;
local friend = "toto";
local friend2 = false;
local friend_handle = nil;
local y = 0;
local xp_begin = 0;
local xp_end = 0;
local LEECHER_1 = "";
local LEECHER_2 = "";
local waitmap = 0;
local time_begin;
local lvl;
local SELL_RUN = false;
local MSG_KEYUP = 0x101;
local isActive = false;
local AS_INVENTORY = hell_inv.MERCH_MISC;
local LAST_MERC = nil;
local tocktick = 0;
local movebot_handle_npc;
local movebot_handle_msg;
local bicrave_handle = nil;
local bicrave_on = false;
local immune_physical = {};
local immune_fire = {};
local immune_electric = {};
local immune_toxic = {};
local immune_phase = {};
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
	if not (z and type(z) == "number") then
		local foo, bar, foobar = hell_map.getCoords();
		z = foobar;
	end
	cx, cy, cz = roundCoords(hell_map.getCoords());
	dx, dy, dz = roundCoords(x, y, z);
	if(dx == cx and dy == cy and dz == cz) then
		hell_move.moveStop();
		unregister(movebot_handle);
		movebot_handle = nil;
		return;
	else
		vx = dx;
		vy = dy;
		vz = dz;
		dx, dy, dz = roundCoords(x, y, z);
		if(vx == dx and vy == dy and vz == dz) then
			hell_cam.lookAt(x, y, z);
			hell_move.moveForwardStart();
		else
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
		tocktick = 0;
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
	if MODE == "solo" and ismoving == false then
		hell_global.resetInstance();
		unregister(movebot_handle_frontmap);
		
		if i==1 or CHAR_ISDEAD == true or WARP_FAIL == true or SELL_RUN == true then
			local ismoving = hell_move.isMoving();
			if ismoving == false then
				moveTo(64.19,-79.91,5.93);
			end
		else
			hell_move.moveBackwardStart();
			delay(650, function() 
				hell_move.moveStop();
			end);
		end
		movebot_handle_inwarp = register(event.ONTICK, function() inWarp() end);
	end
	if MODE == "party" and friend == true and ismoving == false then
		hell_global.resetInstance();
		unregister(movebot_handle_frontmap);
		if i==1 or CHAR_ISDEAD == true or WARP_FAIL == true then
			local ismoving = hell_move.isMoving();
			if ismoving == false then
				moveTo(64.19,-79.91,5.93);
			end
		else
			hell_move.moveBackwardStart();
			delay(650, function() 
				hell_move.moveStop();
			end);
		end
		movebot_handle_inwarp = register(event.ONTICK, function() inWarp() end);
	end
	if MODE == "megaparty" and friend == true and friend2 == true and ismoving == false then
		INFO("friend 2 ok on sh");
		hell_global.resetInstance();
		unregister(movebot_handle_frontmap);
		if i==1 or CHAR_ISDEAD == true or WARP_FAIL == true then
			local ismoving = hell_move.isMoving();
			if ismoving == false then
				moveTo(64.19,-79.91,5.93);
			end
		else
			hell_move.moveBackwardStart();
			delay(650, function() 
				hell_move.moveStop();
			end);
		end
		movebot_handle_inwarp = register(event.ONTICK, function() inWarp() end);
	end
end

function inWarp()
	ticktack = ticktack + 1;
	local ismoving = hell_move.isMoving();
	flag_emergency = 0 ;
	tick = 0;
	CHAR_ISDEAD = false;
	
	local a = hell_map.getMapName();
	if ismoving == false then
		local state = hell_global.getGamestate();
		if a == SH_MAPID and state == 9 then
			hell_cam.setCam(0,0);
			hell_cam.setCam(-2.12,0);
		end
		if a ~= SH_MAPID and state == 9 then
			friend = false;
			friend2 = false;
			unregister(movebot_handle_inwarp);
			moveStop();
			time_begin = os.clock();
			skill_engi = 163;
			movebot_handle_inmap = register(event.ONTICK, function() inMap() end);
		end
	end
	if a == SH_MAPID and ismoving == false and ticktack > 850 then
		INFO("RETRY WARP TO MAP");
		unregister(movebot_handle_inwarp);
		ticktack = 0;
		WARP_FAIL = true;
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
	if MODE == "solo" and a ~= SH_MAPID and state == 9 then
		if lvl > 49 then
			xp_begin = hell_char.getPlayer().stats.rank_experience;
		else
			xp_begin = hell_char.getPlayer().stats.experience;
		end
		WARP_FAIL = false;
		SELL_RUN = false;
		delay(500, function() 
			startcheckmob();
			doRun();
		end);
		unregister(movebot_handle_inmap);
	end
	if MODE == "party" and a ~= SH_MAPID and state == 9 and friend == true then
		if lvl > 49 then
			xp_begin = hell_char.getPlayer().stats.rank_experience;
		else
			xp_begin = hell_char.getPlayer().stats.experience;
		end
		WARP_FAIL = false;
		delay(500, function() 
			startcheckmob();
			doRun();
		end);
		unregister(movebot_handle_inmap);
	end
	if MODE == "megaparty" and a ~= SH_MAPID and state == 9 and friend == true and friend2 == true then
		if lvl > 49 then
			xp_begin = hell_char.getPlayer().stats.rank_experience;
		else
			xp_begin = hell_char.getPlayer().stats.experience;
		end
		WARP_FAIL = false;
		delay(500, function() 
			startcheckmob();
			doRun();
		end);
		unregister(movebot_handle_inmap);
	end
	if waitmap == 1200*FRIEND_TIMEOUT then
		if MODE == "party" then
			MODE = "solo";
			LEECHER_1 = "";
			LEECHER_2 = "";
			INFO("Waiting for %s timeout 5min switch Mode to %s",LEECHER_1,MODE);
		end
		if MODE == "megaparty" then
			local presentfriend = nil;
			if friend == true then
				presentfriend = LEECHER_1;
			end
			if friend2 == true then
				presentfriend = LEECHER_2;
			end
			if presentfriend ~= nil then
				MODE = "party";
				LEECHER_1 = presentfriend;
				LEECHER_2 = "";
				INFO("Waiting for friend timeout 5min switch Mode to %s with leecher %s",MODE,LEECHER_1);
			end
			if presentfriend == nil then
				MODE = "solo";
				LEECHER_1 = "";
				LEECHER_2 = "";
				INFO("Waiting for friends timeout 5min switch Mode to %s",MODE);
			end
		end
	end
	waitmap = waitmap +1;
end



function doRun()
	waitmap = 0;
	local cx, cy, cz = roundCoords(hell_map.getCoords());
	--1st left
	hell_move.moveStop();
	hell_move.moveLeftStart();
	delay(400, function() 
		hell_move.moveStop();
	end);
	ticktock = 0;
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
			if CHAR_CLASS == 'engi' then
				delay_backward = 1450;
				if pcall(function() hell_skill.fire(skill_engi) end) then
				else
					INFO("ERROR CAST SKILL");
				end
			elseif CHAR_CLASS == 'evo' then
				local hellfire = 247;
				local poison = 262;
				local elec = 251;

				if pcall(function() hell_skill.fire(poison) end) then
				else
					INFO("ERROR CAST SKILL");
				end
				delay(2000, function() 
					if pcall(function() hell_skill.fire(hellfire) end) then
					else
						INFO("ERROR CAST SKILL");
					end
				end);
			else
				INFO("NO RUN() FOR THIS CLASS");
			end
			movebot_map_waitback = register(event.ONTICK, function() waitAndBack() end);
		end);
		j = 1;
		return 0;
	end
end

function waitAndBack()
	startcheckmob();
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
	local state = hell_global.getGamestate();
	if state == 8 then
		friend = false;
		friend2 = false;
	end
	tick = tick + 1;
	if a == SH_MAPID and state == 9 then
		local cx, cy, cz = roundCoords(hell_map.getCoords());
		if (cx == SH_WARP_X and cy == SH_WARP_Y and cz == SH_WARP_Z) then
			lvl = hell_char.getPlayer().stats.level;
			if lvl > 49 then
				xp_end = hell_char.getPlayer().stats.rank_experience;
			else
				xp_end = hell_char.getPlayer().stats.experience;
			end
			local xp_earn = (xp_end - xp_begin);
			local run_time = (os.clock() - time_begin);
			if xp_earn ~= 0 and xp_earn ~= 587884867 then
				INFO("RUN %d : %.2fs : %d XP",i,run_time,xp_earn);
			else
				INFO("RUN %d : %.2fs",i,run_time);
			end
			j = 0;
			i = i +1;
			sellrun = sellrun + 1;
			CHAR_ISDEAD = false;
			movebot_handle_center = register(event.ONTICK, function() thenMoveToCenter(44.26,-43.08,6.46) end);
			unregister(movebot_handle_outmap);
		else
			sellrun = sellrun + 1;
			CHAR_ISDEAD = false;
			hell_move.moveStop();
			if lvl > 49 then
				xp_end = hell_char.getPlayer().stats.rank_experience;
			else
				xp_end = hell_char.getPlayer().stats.experience;
			end
			local xp_earn = (xp_end - xp_begin);
			local run_time = (os.clock() - time_begin);

			if xp_earn ~= 0 and xp_earn ~= 587884867 then
				INFO("RUN %d : %.2fs : %d XP",i,run_time,xp_earn);
			else
				INFO("RUN %d : %.2fs",i,run_time);
			end
			j = 0;
			i = i +1;
			if(sellrun==RUN_SELL) then
				INFO("GO SELLING SHIT");
				sell();
				sellrun=0;
				SELL_RUN = true;
			else
				delay(6000, function() 
					if IS_BEAST == 1 then
						frontMapBeast();
					end
					if IS_NECRO == 1 then
						movebot_handle_frontmap = register(event.ONTICK, function() frontMapNecro() end);
					end
				end);
			end
			unregister(movebot_handle_outmap);
		end
	else if a == "Skull Step" then
		if tick > 150 and flag_emergency == 0 and CHAR_ISDEAD == false then
			INFO("TRY EMERGENCY EXIT");
			local mana = hell_char.getData()["Current Power"];
			mana = mana * 1;
			if mana > 111 then
				hell_skill.fire(165);
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
		hell_gui.floatingMessage_C ('BOT AUTO : Must at SH', '');
		INFO("MUST BE ON STONEHENGE");
		return;
	else
		isActive = true;
		local strun = tostring(RUN_SELL);
		if RUN_SELL == 5000 then
			 strun = 'disable';
		end
		if DIFFICULTY == 0 then	dif = "Normal";end
		if DIFFICULTY == 1 then	dif = "Nightmare";end
		if DIFFICULTY == 2 then	dif = "Hell";end
		if IS_BEAST == 1 then
			INFO("BOT AUTO %s %s SELLRUN %s BEAST : %s",MODE,CHAR_CLASS,strun,dif);
		end
		if IS_NECRO == 1 then
			INFO("BOT AUTO %s %s SELLRUN %s NECRO : %s ",MODE,CHAR_CLASS,strun,dif);
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
		friend_handle = register(event.ENV_ACTION, function() checkFriend(e) end);
		movebot_handle_msg = register(event.CHAT_RECV, function(e) checkMode(e) end);
		startSell({["scrap"]=5000,["scrap_tech"]=5000,["scrap_magic"]=5000,["scrap_holy"]=5000});	-- auto shopper
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

function checkMode(e)
	local obj = e;
	local state = hell_global.getGamestate();
	if state == 9 and obj.channel ~= nil and obj.sender ~= nil then
		if obj.channel == "" then
			if obj.message == "mode:party" then
				if obj.sender == 'Lrrr-Omicronian' or 
					obj.sender == 'Asamiya' or 
					obj.sender == 'Mina' or 
					obj.sender == 'l0tus' or 
					obj.sender == 'Danjal' or 
					obj.sender == 'Kiamiya' or 
					obj.sender == 'canamule' or
					obj.sender == 'Succube' or
					obj.sender == 'Phalaen' or
					obj.sender == 'Big-Boned' or
					obj.sender == 'Chax' then
						MODE = "party";
						LEECHER_1 = obj.sender;
						local invit = "/invite "..LEECHER_1;
						local whisp = "/p ok bot mode changed to "..MODE;
						local l = "/local roger roger";
						hell_global.sendCommand(invit);
						hell_global.sendCommand(l);
						hell_global.sendCommand(whisp);
						INFO("Mode changed to %s",MODE);
						INFO("Leecher1 %s",LEECHER_1);
				end				
			end
			if obj.message == "mode:megaparty" then
				if obj.sender == 'Lrrr-Omicronian' or 
					obj.sender == 'Asamiya' or 
					obj.sender == 'Mina' or 
					obj.sender == 'l0tus' or 
					obj.sender == 'Danjal' or 
					obj.sender == 'Kiamiya' or 
					obj.sender == 'canamule' or
					obj.sender == 'Succube' or
					obj.sender == 'Phalaen' or
					obj.sender == 'Big-Boned' or
					obj.sender == 'Chax' then
						MODE = "megaparty";
						LEECHER_2 = obj.sender;
						local invit = "/invite "..LEECHER_1;
						local whisp = "/p ok bot mode changed to "..MODE;
						local l = "/local roger roger";
						hell_global.sendCommand(invit);
						hell_global.sendCommand(l);
						hell_global.sendCommand(whisp);
						INFO("Mode changed to %s",MODE);
						INFO("Leecher2 %s",LEECHER_2);
				end				
			end
			if obj.message == "mode:solo" then
				MODE = "solo";
				LEECHER_1 = "";
				LEECHER_2 = "";
				local whisp = "/p ok bot mode changed to "..MODE;
				hell_global.sendCommand(whisp);
				INFO("Mode changed to %s",MODE);
			end
		end
	end
end

function checkFriend(e)
	local obj= e.obj;
	if obj.isPlayer() == true then
		if LEECHER_1 ~= "" and e.obj["name"] == LEECHER_1 then
			friend = true;
		end
		if LEECHER_2 ~= "" and e.obj["name"] == LEECHER_2 then
			friend2 = true;
		end
	end
end

function checkPlayer()
	CHAR_NAME = hell_char.getPlayer().name;
	lvl = hell_char.getPlayer().stats.level;
	if CHAR_NAME == 'Lrrr-Omicronian' or  CHAR_NAME == 'Asamiya' or  CHAR_NAME == 'canamule' or  CHAR_NAME == 'Pinedhuitre' then
		CHAR_CLASS = 'engi';
	elseif  CHAR_NAME == 'Mina' then
		CHAR_CLASS = 'evo';
	elseif  CHAR_NAME == 'l0tus' then
		CHAR_CLASS = 'mm';
	elseif  CHAR_NAME == 'Danjal' or CHAR_NAME == 'Phalaen' then
		CHAR_CLASS = 'bm';
	elseif  CHAR_NAME == 'Kiamiya' or CHAR_NAME == 'Big-Boned' then
		CHAR_CLASS = 'guard';
	elseif  CHAR_NAME == 'Chax' or CHAR_NAME == 'Succube' then
		CHAR_CLASS = 'summon';
	end
end

local function callSell(tabledata_buy)
	LAST_MERC = hell_env.getNpcId_C();
	local tabledata_inv = {};
	for y=1,12 do
		for x=1,6 do
			if hell_inv.get(x,y) ~= nil then
				local obj = hell_inv.get(x,y);
				local qty = obj.getStats("item_quantity");
				local model = obj["model"];
				if qty == nil then qty = 1 end
				for pattern,quantity in pairs(tabledata_buy) do
					if pattern == model and qty >= quantity then
						INFO("item sold : %s x%s",model,qty);
						hell_env.sell_C(obj.id, LAST_MERC);
					elseif string.find(obj.model, "medpack")  or string.find(obj.model, "powerpack") then
						INFO("item sold : %s x%s",model,qty);
						hell_env.sell_C(obj.id, LAST_MERC);
					end
				end
			end
		end
	end	
	LAST_MERC = nil;
end

function sell()
	hell_move.moveStop();
	hell_move.moveLeftStart();
	delay(700, function() 
		hell_move.moveStop();
		movebot_handle_center = register(event.ONTICK, function() MoveToCenterSH(44.26,-43.08,6.46) end);
	end);
end

function MoveToCenterSH(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		moveTo(x,y,z);
		unregister(movebot_handle_center);
		movebot_handle_npc = register(event.ONTICK, function() MoveToNPC(45.70,-10.73,10.39) end);
	end
end

function MoveToNPC(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		moveTo(x,y,z);
		unregister(movebot_handle_npc);
		movebot_handle_npc = register(event.ONTICK, function() MoveToNPC2() end);
	end
end

function MoveToNPC2(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		local npcID = hell_env.search("birch")[1].id;
		local x = hell_env.get(npcID).x;
		--local x = 68.90153503418;
		local y = hell_env.get(npcID).y;
		--local y = -4.4510059356689;
		local z = hell_env.get(npcID).z;
		--local z = 10.014455795288;
		moveTo(x,y,z);
		unregister(movebot_handle_npc);
		movebot_handle_npc = register(event.ONTICK, function() atNPC() end);
	end
end

function MoveToNPCBack(x, y , z)
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		tocktick = 0;
		moveTo(x,y,z);
		unregister(movebot_handle_npc);
		movebot_handle_center = register(event.ONTICK, function() thenMoveToCenter(44.26,-43.08,6.46) end);
	end
end

function atNPC()
	local ismoving = hell_move.isMoving();
	if ismoving == false then
		local npcID = hell_env.search("birch")[1].id;
		hell_env.interact_C(npcID);
		tocktick = tocktick +1;
	end
	if tocktick > 150 then
		userinput.sendEsc();
		unregister(movebot_handle_npc);
		movebot_handle_npc = register(event.ONTICK, function() MoveToNPCBack(42.68,-12.20,10.17) end);
	end
end

function startSell(tabledata_buy) 
	local str='';
	for pattern,quantity in pairs(tabledata_buy) do
		--INFO("Auto Seller - %s x%s",pattern,quantity);
		str = str..' '..pattern;
	end
	INFO("AUTOSELLER%s",str);
	bicrave_handle = register(event.ONTICK, function(e)
		if not isIngame() then return end
		if AS_INVENTORY[1][1] then
			callSell(tabledata_buy);
		else
			LAST_MERC = nil;
		end
	end);
end

function killEvent()
	if movebot_handle ~= nil then	unregister(movebot_handle);	end
	if movebot_handle_map ~= nil then	unregister(movebot_handle_map);	end
	if movebot_handle_center ~= nil then	unregister(movebot_handle_center); end
	if movebot_handle_frontmap ~= nil then	unregister(movebot_handle_frontmap);	end
	if movebot_handle_inwarp ~= nil then	unregister(movebot_handle_inwarp);	end
	if movebot_handle_inmap ~= nil then	unregister(movebot_handle_inmap);	end
	if movebot_map_firstleft ~= nil then	unregister(movebot_map_firstleft);	end
	if movebot_map_waitback ~= nil then	unregister(movebot_map_waitback);	end
	if movebot_handle_outmap ~= nil then	unregister(movebot_handle_outmap);	end
	if movebot_handle_check_isdead ~= nil then	unregister(movebot_handle_check_isdead);	end
	if movebot_handle_on_death ~= nil then	unregister(movebot_handle_on_death);	end
	if movebot_handle_npc ~= nil then	unregister(movebot_handle_npc);	end
	if friend_handle ~= nil then	unregister(friend_handle);	end
	if movebot_handle_msg ~= nil then	unregister(movebot_handle_msg);	end
	if bicrave_handle ~= nil then	unregister(bicrave_handle);	end
	if mob_handle_sfx ~= nil then	unregister(mob_handle_sfx);	end
end


function checkMob(e)
	local obj = e.obj;
	if obj ~= nil and obj.isMob() == true then
		local affix = nil;
		affix = obj["stats"]["applied_affix"];
		if affix ~= nil then
			local isNew = true;
			for i,pattern in ipairs(tabledata_mob) do
				if pattern == e.id then
					isNew = false;
				end
			end
			local dist = obj.getDist();
			if isNew==true and dist < 40 then
				local id = e.id;
				table.insert(tabledata_mob,id);
				local model = obj.model;
				local sfx_def1 = obj["stats"]["sfx_defense_bonus 1"];
				local sfx_def2 = obj["stats"]["sfx_defense_bonus 2"];
				local sfx_def3 = obj["stats"]["sfx_defense_bonus 3"];
				local sfx_def4 = obj["stats"]["sfx_defense_bonus 4"];
				local sfx_def5 = obj["stats"]["sfx_defense_bonus 5"];
				--INFO("model : %s id : %d",model,id)
				local imune = '';
				local affix1 = obj["stats"]["applied_affix"];
				local affix2 = obj["stats"]["applied_affix 1"];
				local affix3 = obj["stats"]["applied_affix 2"];
				--affix test
				if affix1 ~= nil then
					imune = resolveAffixes(affix,id);
				end
				if affix2 ~= nil then
					imune = resolveAffixes(affix2,id);
				end
				if affix3 ~= nil then
					imune = resolveAffixes(affix3,id);
				end
				if imune == nil then
					-- sfx def test
					local amount;
					if sfx_def1 > 3500 then
						imune = 'physical';
						amount = sfx_def1;
						table.insert(immune_physical,id);
					end
					if sfx_def2 > 3500 then
						imune = 'fire';
						amount = sfx_def2;
						table.insert(immune_fire,id);
					end
					if sfx_def3 > 3500 then
						imune = 'electric';
						amount = sfx_def3;
						table.insert(immune_electric,id);
					end
					if sfx_def4 > 3500 then
						imune = 'toxic';
						amount = sfx_def4;
						table.insert(immune_toxic,id);
					end
					if sfx_def5 > 3500 then
						imune = 'phase';
						amount = sfx_def5;
						table.insert(immune_phase,id);
					end
					if imune ~= nil then
						INFO("Def bonus %s (%d) : %d",imune,amount,id);
					end
				end
				if imune ~= "" and  imune ~= nil then
					if table.getn(immune_physical) ~=0 or table.getn(immune_fire)~=0 or
						table.getn(immune_toxic)~=0 or table.getn(immune_electric)~=0 or table.getn(immune_phase)~=0 then
						
						if table.getn(immune_physical) > table.getn(immune_fire) or
							table.getn(immune_physical) > table.getn(immune_electric) or
							table.getn(immune_physical) > table.getn(immune_toxic) or
							table.getn(immune_physical) > table.getn(immune_phase) or
							table.getn(immune_physical) == table.getn(immune_toxic) or 
							table.getn(immune_physical) == table.getn(immune_electric) or 
							table.getn(immune_physical) == table.getn(immune_fire) then
							skill_engi = 165;
						end
						if table.getn(immune_fire) > table.getn(immune_physical) or
							table.getn(immune_fire) > table.getn(immune_electric) or
							table.getn(immune_fire) > table.getn(immune_toxic) or
							table.getn(immune_fire) > table.getn(immune_phase) then
							skill_engi = 163;
						end
						if table.getn(immune_toxic) > table.getn(immune_physical) or
							table.getn(immune_toxic) > table.getn(immune_electric) or
							table.getn(immune_toxic) > table.getn(immune_fire) or
							table.getn(immune_toxic) > table.getn(immune_phase) then
							skill_engi = 163;
						end
						if table.getn(immune_electric) > table.getn(immune_physical) or
							table.getn(immune_electric) > table.getn(immune_fire) or
							table.getn(immune_electric) > table.getn(immune_toxic) or
							table.getn(immune_electric) > table.getn(immune_phase) then
							skill_engi = 163;
						end
						if table.getn(immune_phase) > table.getn(immune_physical) or
							table.getn(immune_phase) > table.getn(immune_fire) or
							table.getn(immune_phase) > table.getn(immune_toxic) or
							table.getn(immune_phase) > table.getn(immune_electric) then
							skill_engi = 163;
						end
					end
				end
			end
		end
	end
end

function getMob()
	local affix1 = getHover().stats["applied_affix"];
	local affix2 = getHover().stats["applied_affix 1"];
	local affix3 = getHover().stats["applied_affix 2"];
	INFO("affix 1 : %d",affix1);
	INFO("affix 2 : %d",affix2);
	INFO("affix 3 : %d",affix3);
end

function resolveAffixes(affix,id)
	local res = nil;
	if affix == 2137 then
		table.insert(immune_physical,id);
		res = 'physical';
	end
	if affix == 2138 then
		table.insert(immune_fire,id);
		res =  'fire';
	end
	if affix == 2139 then
		table.insert(immune_electric,id);
		res =  'electric';
	end
	if affix == 2140 then
		table.insert(immune_toxic,id);
		res =  'toxic';
	end
	if affix == 2141 then
		table.insert(immune_phase,id);
		res =  'phase';
	end
	if res ~= nil then
		INFO("Immune %s : %d",res,id);
	end
	return res;
end

function checkKey(e)
	if isIngame() and e.wparam ~= 17804 and e.wparam ~= 0 then
		if e.message==MSG_KEYUP then
			if e.wparam == 116 and isActive == true then  -- F5
				hell_gui.floatingMessage_C ('BOT AUTO : Disable', '');
				INFO("BOT AUTO : Disable");
				killEvent();
				delay(5000, function() 
					killEvent();
				end);
				delay(10000, function() 
					killEvent();
				end);
				delay(15000, function() 
					killEvent();
				end);
				moveStop();
				hell_move.moveStop();
				i=1;
				sellrun=0;
				isActive=false;
			elseif e.wparam == 116 and isActive == false then  -- F5
				local str;
				if RUN_SELL ~= 5000 then
					str = 'Auto sell '..RUN_SELL;
				else
					str = 'Auto sell disable';
				end
				hell_gui.floatingMessage_C ('BOT AUTO : Enable', str);
				checkPlayer();
				start();
			elseif e.wparam == 117 and isActive == true then  -- F6
				if DIFFICULTY == 2 then DIFFICULTY = 0; 
				else 
					DIFFICULTY = DIFFICULTY +1; 
				end
				local diff_name = 'Normal';
				if DIFFICULTY == 1 then diff_name = 'Nightmare' end
				if DIFFICULTY == 2 then diff_name = 'Hell' end
				local str = 'BOT AUTO : '..diff_name;
				hell_gui.floatingMessage_C (str, '');
				INFO("Difficulty changed to %s",diff_name);
			elseif e.wparam == 118 then  -- F7
				if RUN_SELL == 5000 then
					RUN_SELL = 400; 
					local str = 'BOT AUTO : SELLRUN '..RUN_SELL;
					hell_gui.floatingMessage_C (str, '');
					INFO("Sellrun enable %s run",tostring(RUN_SELL));
				else
					RUN_SELL = 5000; 
					hell_gui.floatingMessage_C ('BOT AUTO : SELLRUN DISABLE', '');
					INFO("Sellrun disable");
				end
			elseif e.wparam == 119 and isActive==false then  -- F8
				if bicrave_on == false then
					bicrave_on = true;
					local str = 'BICRAVE AUTO : ENABLE ';
					hell_gui.floatingMessage_C (str, '');
					startSell({["scrap"]=5000,["scrap_tech"]=5000,["scrap_magic"]=5000,["scrap_holy"]=5000});	-- auto shopper
				else
					local str = 'BICRAVE AUTO : DISABLE ';
					hell_gui.floatingMessage_C (str, '');
					INFO("Bicrave AUTO disable");
					unregister(bicrave_handle);
					bicrave_on = false;
				end
			end
		end
	end
end

function startcheckmob()
	if mob_handle_sfx == nil then
		mob_handle_sfx = register(event.ENV_ACTION, function() checkMob(e) end);
	else
		unregister(mob_handle_sfx);
		mob_handle_sfx = nil;
	end
end


-- start when ready
register("STARTUP", function()
	register(event.USERINPUT, function() checkKey(e) end);
	SHBot.checkPlayer();
	if autostart == true then
		SHBot.start();
	end
end);