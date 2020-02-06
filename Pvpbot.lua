module("Pvpbot", package.seeall);

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

-- F5 active/desactive pvpbot

local LEECHER = "juiphin";
local CHAR_NAME;
local CHAR_CLASS;

--[[ logger shortcuts ]]--
local mod = 'PvpBot';
local function DEBUG(fmt, ...) log.DEBUG(mod, fmt, ...) end
local function INFO (fmt, ...) log.INFO (mod, fmt, ...) end
local function WARN (fmt, ...) log.WARN (mod, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(mod, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(mod, fmt, ...) end

local handle_check_state = nil;
local handle_buff = nil;
local handle_buff2 = nil;
local handle_recast_death = nil;
local onmap = false;
local pet = "";
local onesec = 20;
local waiting_buff1;
local waiting_buff2 = false;
local char_changed = false;
local i = 1;
local time_start_skill = 20;
local time_start_skill2 = 40;
local buff_cooldown_time = 90;
local buff_cooldown_time2 = 10;
local tick=0;
local tack=0;

local summy_concentrate_ele = 224;
local summy_ele_stun = 204;
local summy_ele_fire = 202;
local summy_ele_poison = 206;
local summy_warper = 215;
local summy_venom_armor = 221;
local evo_venom_armor = 260;
local evo_shield = 240;
local petspawned = false;
local istation = nil;
local isbase = nil;
local isgreenwich = nil;
local isparliament = nil;
local isstonehenge = nil;

local MSG_KEYUP = 0x101;
local isActive = false;

local pvp_map = "Abandoned Subway";
local isOnMap = true;
local x,y,z=0;
local mob_handle = nil;
local mode = "runner";
local isActive = false;
local handle_attack = nil;
local handle_partyok = nil;
local movebot_handle_msg = nil;
local cac = 2;
local leecher_alive = false;
local z = 0;
local k = 0;
local h = 0;
local dead = 0;

function checkState()
	local state = hell_global.getGamestate();
	local a = hell_map.getMapName();
	if  state == 9 and a ~= '' and a ~= nil and a == pvp_map and isOnMap == true and isActive == false and k == 0 then
		delay(2000, function() 
			doRun();
		end);
		j = 0;
		k = k + 1;
	elseif state == 9 and a ~= '' and a ~= nil and a == pvp_map and isOnMap == false and isActive == true and k == 0 then
		unregister(handle_attack);
		hell_move.moveStop();
		INFO("RUN %d DONE",i);
		if mode == 'runner' then
			delay(3000, function() 
				hell_gui.runCallback(0x005D2873);
				delay(12000, function() 
					isOnMap = true;
					k = 0;
				end);
			end);
		end
		isActive = false;
		i = i +1;
		j = 0;
		k = k + 1;
		dead = 0;
	end
end

function doRun()
	isActive = true;
	if i ~= 1 then
		INFO("PVPBOT Play Record");
		isPlaying = true;
		--hell_skill.stop(cac);
		userinput.playRecord("macro",true,macroFinished());
	else
		macroFinished();
	end	
end

function partycallback()
	tick = tick + 1;
	if tick == 45 then
		INFO("send callback");
		hell_gui.runCallback(0x005D2873);
		tick = 0;
	end
end

function macroFinished()
	isPlaying = false;
	h = 0;
	g = 0;
	mob_handle = register(event.ONTICK, function() checkFriend(e) end);
	handle_attack = register(event.ONTICK, function() attack() end);	
end

local g = 0;
function attack()
	if dead == 15 and h == 0 then
		--INFO("15 kill");
		unregister(mob_handle);
		h = 1;
		delay(32000, function() 
			local l = "/local roger done";
			hell_global.sendCommand(l);
			isOnMap = false;
			k = 0;
		end);
	else
		if leecher_alive == true then
			hell_cam.lookAt(x, y, z);
			hell_skill.start(cac);
		elseif leecher_alive == false then
			hell_skill.stop(cac);
			--INFO("dead");
		end
	end
end


function checkFriend(e)
	local leecherID = nil;
	leecherID = hell_env.search(LEECHER)[1].id;
	if leecherID ~= nil then
		local lvl = hell_env.get(leecherID).stats.level;
		if lvl == 1 then
			leecherID = hell_env.search(LEECHER)[2].id;
		end
		local life = hell_env.get(leecherID).stats.hp_cur;
		x = hell_env.get(leecherID).x;
		y = hell_env.get(leecherID).y;
		z = hell_env.get(leecherID).z;
		if life == nil and g == 0 then
			g = 1;
			leecher_alive = false;
			dead = dead +1;
			--INFO("kill %d",dead);
		elseif life ~= nil and life > 100 then
			leecher_alive = true;
			g = 0;
		end
	end
end

function launchskill(skillid)
	if pcall(function() hell_skill.fire(skillid) end) then
	else
		INFO("ERROR CAST SKILL %s",skillid);
	end
end

function checkMsg(e)
	local obj = e;
	if obj.channel ~= nil and obj.sender ~= nil then
		if obj.channel == "" then
			if obj.message == "roger done" then
				delay(1000, function() 
					hell_gui.runCallback(0x005D2873);
				end);
			end	
		end
	end
end

function checkPlayer()
	CHAR_NAME = hell_char.getPlayer().name;
	if CHAR_NAME == 'Lrrr-Omicronian' or  CHAR_NAME == 'Asamiya' or  CHAR_NAME == 'canamule' or  CHAR_NAME == 'papapex' then
		CHAR_CLASS = 'engi';
		if CHAR_NAME == "Lrrr-Omicronian" then
			pet = "pet_shulgoth";
		end
		if CHAR_NAME == "Asamiya" then
			pet = "pet_shulgoth";
		end
		mode = "runner";
	elseif  CHAR_NAME == 'Mina' then
		CHAR_CLASS = 'evo';
		pet = "pet_pit_baron";
		mode = "runner";
	elseif  CHAR_NAME == 'l0tus' then
		CHAR_CLASS = 'mm';
		if CHAR_NAME == "l0tus" then
			pet = "pet_pit_baron";
		end
		mode = "runner";
	elseif  CHAR_NAME == 'Danjal' or CHAR_NAME == 'Phalaen' then
		CHAR_CLASS = 'bm';
		if CHAR_NAME == "Danjal" then
			pet = "pet_pit_baron";
		end
		if CHAR_NAME == "Phalaen" then
			pet = "pet_pit_baron";
		end
		mode = "runner";
	elseif  CHAR_NAME == 'Kiamiya' then
		CHAR_CLASS = 'guard';
		if CHAR_NAME == "Kiamiya" then
			pet = "pet_sydo";
		end
		if CHAR_NAME == "Big-Boned" then
			--pet = "nautilus";
		end
		mode = "runner";
	elseif  CHAR_NAME == 'Chax' or CHAR_NAME == 'Succube' then
		CHAR_CLASS = 'summon';
		if CHAR_NAME == "Chax" then
			pet ="nautilus";
		end
		if CHAR_NAME == "Succube" then
			--pet = "nautilus";
		end
		mode = "runner";
	else
		mode = "leecher";
		--handle_partyok = register(event.ONTICK, function() partycallback() end);
		movebot_handle_msg = register(event.CHAT_RECV, function(e) checkMsg(e) end);
	end
	INFO("PVPBot %s %s",CHAR_NAME,mode);	
	isOnMap = true;
	if handle_check_state == nil and mode == "runner" then
		handle_check_state = register(event.ONTICK, function() checkState() end);	
	end
end


local isRecording = false;
local isPlaying = false;
local isRecorded = false;

function checkKey(e)
	if isIngame() and e.wparam ~= 17804 and e.wparam ~= 0 then
		if e.message==MSG_KEYUP then
			if e.wparam == 116 and isActive == false and isRecorded == true then  -- F5
				checkPlayer();
				local str = 'PVPBOT '..mode..' : Enable';
				hell_gui.floatingMessage_C(str, '');
			elseif e.wparam == 116 and isActive == true then  -- F5
				hell_gui.floatingMessage_C('PVPBOT : Disable', '');
				INFO("PVPBOT Disable");
				if movebot_handle_msg ~= nil then	unregister(movebot_handle_msg);	end
				if mob_handle ~= nil then	unregister(mob_handle);	end
				if handle_check_state ~= nil then	unregister(handle_check_state);	end
				if handle_attack ~= nil then	unregister(handle_attack);	end
				if handle_partyok ~= nil then	unregister(handle_partyok);	end
				isActive = false;
			elseif e.wparam == 117 and isRecording == false and isPlaying == false and isRecorded == false then  -- F6
				hell_gui.floatingMessage_C('PVPBOT : Recording', '');
				INFO("PVPBOT Recording");
				userinput.startRecord();
				isRecording = true;
			elseif e.wparam == 117 and isRecording == true and isPlaying == false and isRecorded == false then  -- F6
				hell_gui.floatingMessage_C('PVPBOT : Stop Record', '');
				INFO("PVPBOT Stop Record");
				userinput.saveRecord("macro", true);
				userinput.stopRecord();
				isRecording = false;
				isRecorded = true;
			elseif e.wparam == 118 and isPlaying == false then  -- F7
				hell_gui.floatingMessage_C('PVPBOT : Play Record', '');
				INFO("PVPBOT Play Record");
				isPlaying = true;
				userinput.playRecord("macro",true,macroFinished());
			end
		end
	end
end

-- start when ready
register("STARTUP", function()
	register(event.USERINPUT, function() checkKey(e) end);
end);