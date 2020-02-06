module("CouponBot", package.seeall);

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

local RESETER = "canamule";
local MODE = '';
local RUNNER_TIME = 3;
local ENGI_TIME = 0;
local tick = 0;
local tock = 0;
local CHAR_NAME = "";
local fatbully = false;
local isfound = false;
local fatbully_x;
local fatbully_y;
local fatbully_z;
local waitmap = 0;
local time_begin;
local friend = false;
local isreseting = false;
--[[ logger shortcuts ]]--
local mod = 'CouponBot';
local function INFO (fmt, ...) log.INFO (mod, fmt, ...) end


function start()
	--check current map
	local a = hell_map.getMapName();
	if a ~= 'Tottenham Court Road' then
		INFO("MUST BE ON Tottenham Court Road");
		return;
	else
		if MODE == 'runner' then
			local runner_handle = register(event.ONTICK, function() runner(e) end); 
		end
		if MODE == '' or MODE == 'killer' then
			MODE = 'killer';
			local mob_handle = register(event.ENV_ACTION, function() checkMob(e) end);
			--local loot_handle = register(event.ONTICK, function() checkloot(e) end);
			--local friend_handle = register(event.ENV_ACTION, function() checkFriend(e) end);
			--local fatbully_handle = register(event.ENV_ACTION, function() checkFatBully(e) end);
			local job_handle = register(event.ONTICK, function() run() end);
		end
		INFO("BOT COUPON : %s : %s",CHAR_CLASS,MODE);
	end
end

function checkMob(e)
	local a = hell_map.getMapName();
	if a == 'Tottenham Court Road' and CHAR_CLASS ~= 'evo'then
		local obj = e.obj;
		if obj.isMob() == true then
			hell_cam.lookAt(obj.x, obj.y, obj.z);
			local skill = 4;
			if pcall(function() hell_skill.fireBar(skill) end) then
			else
				INFO("ERROR CAST SKILL");
			end
		end
	end
end

function runner()
	local a = hell_map.getMapName();
	local state = hell_global.getGamestate();
	if state == 9 and  a == 'Tottenham Court Road' and isreseting == false then
		tock = tock +1;
		backwardreset();
		--INFO("ON MAP")
	end
	if state == 9 and  a ~= 'Tottenham Court Road' and isreseting == false then
		tock = tock +1;
		backwardreset();
		--INFO("AT STATION");
	end
	if state == 8 then
		tock = 0;
		isreseting = false;
		hell_move.moveStop();
	end
end

function backwardreset()
	if tock == 20*RUNNER_TIME then
		isreseting = true;
		hell_move.moveBackwardStart();
	end
end

tiick = 0;
function run()
	tiick= tiick+1;
	if CHAR_CLASS == 'evo' and tiick == 40 then
		local skill = 247;
		if pcall(function() hell_skill.fire(skill) end) then
		else
			INFO("ERROR CAST SKILL");
		end
		tiick = 0;
	end
end

function checkFatBully(e)
	local a = hell_map.getMapName();
	if a == 'Tottenham Court Road' then
		local findfatbully = hell_env.search("fat");
		if findfatbully[1] ~= nil and isfound == false and hell_env.search("fat")[1]['stats'].hp_cur ~= nil then
			fatbully = true;
			fatbully_x = hell_env.search("fat")[1].x;
			fatbully_y = hell_env.search("fat")[1].y;
			fatbully_z = hell_env.search("fat")[1].z;
			INFO("FATBULLY :  %.2f  %.2f  %.2f",fatbully_x,fatbully_y,fatbully_z);
			isfound = true;
		elseif findfatbully[1] ~= nil and hell_env.search("fat")[1]['stats'].hp_cur == nil then
			--INFO("waiting for fat bully");
			isfound = false;
			tick = 0;
		elseif isfound==true and findfatbully[1] ~= nil and hell_env.search("fat")[1]['stats'].hp_cur ~= nil then
			fatbully_x = hell_env.search("fat")[1].x;
			fatbully_y = hell_env.search("fat")[1].y;
			fatbully_z = hell_env.search("fat")[1].z;
		end
	end
end

function checkFriend(e)
	local a = hell_map.getMapName();
	if a == 'Tottenham Court Road' then
		local findfriend = hell_env.search(RESETER);
		if findfriend[1] ~= nil  and hell_env.search(RESETER)[1]['stats'].hp_cur ~= nil then
			--INFO("FRIEND HERE");
			friend = true;
			--hell_skill.stop(2);
		elseif findfriend[1] == nil then
			--INFO("FRIEND LEFT");
			friend = false;
		end
	end
end

function checkPlayer()
	CHAR_NAME = hell_char.getPlayer().name;
	if CHAR_NAME == 'Lrrr-Omicronian' or  CHAR_NAME == 'Asamiya' or  CHAR_NAME == 'canamule' then
		CHAR_CLASS = 'engi';
	elseif  CHAR_NAME == 'Mina' then
		CHAR_CLASS = 'evo';
	elseif  CHAR_NAME == 'l0tus' then
		CHAR_CLASS = 'mm';
	elseif  CHAR_NAME == 'Danjal' then
		CHAR_CLASS = 'bm';
	elseif  CHAR_NAME == 'Kiamiya' then
		CHAR_CLASS = 'guard';
	elseif  CHAR_NAME == 'Chax' then
		CHAR_CLASS = 'summon';
	end
end

-- start when ready
register("STARTUP", function()
	CouponBot.checkPlayer();
	CouponBot.start();
end);