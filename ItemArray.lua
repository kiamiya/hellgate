-- ItemArray v1.0 r1	2011-12-23
-- Author: Tearlow
--
-- Special Thanks- The person behind "Pickit" It is the backbone of it all.
--
-- As always, Got ideas for improvements? Do give me a shout :)
--
-- 24.07.2012 MWI - added pause and timer support. press "PAUSE/BREAK" to disable itemarray
-- 19.03.2012 MWI - small change on  where event.ITEMDOP was renamed to event.ENV_DROP
-- 20.03.2012 MWI - target specific mappings so that its compatible to target: myth
-- 21.03.2012 MWI - corrected myth shifted quality values
-- 22.03.2012 MWI - added initial pickup when near enough
-- 26.03.2012 MWI - small performance improvement
-- 12.12.2011 TLW - initial version
--
--[[
 ______   __                      ______                                    
/\__  _\ /\ \__                  /\  _  \                                   
\/_/\ \/ \ \ ,_\    __    ___ ___\ \ \L\ \  _ __   _ __    __     __  __    
   \ \ \  \ \ \/  /'__`\/' __` __`\ \  __ \/\`'__\/\`'__\/'__`\  /\ \/\ \   
    \_\ \__\ \ \_/\  __//\ \/\ \/\ \ \ \/\ \ \ \/ \ \ \//\ \L\.\_\ \ \_\ \  
    /\_____\\ \__\ \____\ \_\ \_\ \_\ \_\ \_\ \_\  \ \_\\ \__/.\_\\/`____ \ 
    \/_____/ \/__/\/____/\/_/\/_/\/_/\/_/\/_/\/_/   \/_/ \/__/\/_/ `/___/> \
                                         http://darknessfall.com/     /\___/
                                                    by Tearlow         \/__/ 
    Requirements: mmBBQ 1.4

    What does it do?
        - Think Pickit. But this will handle all items, even the ones
        already on the ground. Let's say you're playing a ranged class
        using pickit. It would do no good since you're too far away
        from the loot for it to "grab" it.

        ItemArray indexes all items within the Scene the player is
        in. What this means in English is, each cycle (each cycle is
        1 second) it will find the items that have been dropped
        and if the player is close enough it will "grab" the item.
        It is possible to Exclude items adding "models" to the
        Ignore_Item filter.

        Once the item is inside the player's inventory it will decide
        what actions is needed. Delete, Dismantle or Identify. These
        are actions you can mostly define yourself, but more of that
        in the next section.


    So, how do I make this work?
        - Simple. Put the file "ItemArray.lua" inside your mmoBBQ
        folder. Then add the following line under ADDITIONAL MODULES
        
        require("ItemArray");
        
        Save. And you're ready! If you're the lazy type or simply don't
        know what to do- Inside the folder "Optional" I've included
        an already modified config.lua, overwrite the one in mmoBBQs
        folder and you're ready.


    How do I change the defaulted settings?
        - This requires you to open up "ItemArray.lua" and scroll
        down a bit. Alternatively you can search for "CONFIG" and
        you will find the comment section explaining what each
        option does. Do NOT however change anything besides:
        
        local Itemquality = 3;
        local ModByPass = 3;
        local Ignore_Items = {
        ...
        };


    Something is wrong... HELP!
        - That's not really a question. But if you for some reason
        have issues, contact me on BlizzHackers forum.
        
        http://www.blizzhackers.cc/viewtopic.php?p=4550440#p4550440


    Special Thanks
        - The person behind Pickit, It's the very core :)
        - willsteel: Wicked guy that helped me a bit here and there.

--]]
module("ItemArray", package.seeall);

--[[ include any depencies ]]--
require("common/log");
require("common/utils");
require("common/event");

--[[ STATICS ]]--
local MAXDIST = 10;
local SCAN_DELAY = 1007;

--[[ MAPPINGS ]]--
local GET_OBJECTS = function() end;
local GET_OBJECT = function(id)end;
local CHECK_OBJECT = function(id)end;
local GRAB_OBJECT = function(id)end;
local IDENTIFY_OBJECT = function(id)end;
local DISMANTLE_OBJECT = function(id)end;
local DELETE_OBJECT = function(id)end;
if TARGET == "hell" then
	require("hell_common/hell_global");
	require("hell_common/hell_env");
	require("hell_common/hell_inv");
	require("hell_common/hell_map");
	GET_OBJECTS = hell_env.getEnvObjects;
	GET_OBJECT = hell_env.get;
	CHECK_OBJECT = hell_env.check;
	GRAB_OBJECT = hell_inv.grabObj;
	DELETE_OBJECT = hell_inv.deleteObj;
	DISMANTLE_OBJECT = hell_inv.dismantleObj;
	IDENTIFY_OBJECT = hell_inv.identifyObj;
end
if TARGET == "myth" then
	require("hell_common/hell_global");
	require("hell_common/hell_env");
	require("hell_common/hell_inv");
	require("hell_common/hell_map");
	GET_OBJECTS = hell_env.getEnvObjects;
	GET_OBJECT = hell_env.get;
	CHECK_OBJECT = hell_env.check;
	GRAB_OBJECT = hell_inv.grabObj;
	DELETE_OBJECT = hell_inv.deleteObj;
	DISMANTLE_OBJECT = hell_inv.dismantleObj;
	IDENTIFY_OBJECT = hell_inv.identifyObj;
end



--[[ logger shortcuts ]]--
local mod = 'ItemArray';
local function DEBUG(fmt, ...) log.DEBUG(mod, fmt, ...) end
local function INFO (fmt, ...) log.INFO (mod, fmt, ...) end
local function WARN (fmt, ...) log.WARN (mod, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(mod, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(mod, fmt, ...) end

local ItemArray_handle1 = nil;
local ItemArray_handle2 = nil;
local ItemArray_handle3 = nil;

--[[--------------------------------------------
-------------------- CONFIG --------------------
------------------------------------------------
--
--  >> Itemquality:
-- Dismantle Quality. 1-6. ex. 4 = Legendary.
-- It would keep everything Legendary and above.
-- The rest is Dismantled.
--
--  >> ModByPass:
-- This will bypass Itemquality but only for
-- mods! Set to 3 to keep Rare+ mods.
--
--  >> Ignore_Items:
-- This filters out models that you don't wanna
-- pick up. NOTE: It's Exact names. Not
-- Regex/Partial match.
--
------------------------------------------------
--------------------------------------------]]--

local Itemquality = 4;
local ModByPass = 4;
local Ignore_Items = {
	"cryptex",
	"xmas_ghostcandy",
	"xmas_black_elixir",
	"xmas_red_elixir",
	"townportal",
	"medpack",
	"powerpack",
	"extinguisher";
};

-- myth has shifted quality values
if TARGET == "myth" then
	Itemquality = Itemquality + 1;
	ModByPass = ModByPass + 1;
end

--[[--------------------------------------------
---- DO NOT TOUCH ANYTHING FROM HERE AND ON ----
--------------------------------------------]]--

local TIMER_LAST = 0;
local Items = {};
local Items_action = {};

function enable(iq, mq)
	if ItemArray_handle1 and ItemArray_handle2 and ItemArray_handle3 then
		unregister(ItemArray_handle1);
		unregister(ItemArray_handle2);
		unregister(ItemArray_handle3);
		ItemArray_handle1 = nil;
		ItemArray_handle2 = nil;
		ItemArray_handle3 = nil;
	end

	if not iq then Itemquality = 3; else Itemquality = iq; end
	if not mq then ModByPass = 3; else ModByPass = mq; end

	INFO("ItemArray Started. Dismantle at -%s- Mod bypass at -%s-", ItemQualityText(Itemquality), ItemQualityText(ModByPass));

	-- ItemArray_handle1
	--
	-- Takes care of ITEMDROP events. Once processed, if close enough
	-- it will grab the item. If not, adding it to Items array.
	ItemArray_handle1 = register(event.ENV_DROP,
		function(e)
			local obj = e.obj;

			if obj and Items[obj.id] ~= nil and filter(obj.model) then
				--INFO("event.ITEMDROP: Added [ID: %s] - %s", obj.id, obj.model);
				Items[obj.id] = obj;
				processItem(obj.id);	-- one shot (if near enought pick directly)
			end
		end
	);

	-- ItemArray_handle2
	--
	-- Every X seconds it will add all items within the Scene to the
	-- Items Array. Also handles Item_Action.
	timer(SCAN_DELAY, function()
		if isIngame() and not isPaused() then
			Items = {}; -- Empties Items. I don't know a solution to the related issue yet. Or at least to fix it fully.

			for k, obj in pairs(GET_OBJECTS()) do
				if (type(obj.quality) ~= "nil" and obj.x ~= 0 and obj.y ~= 0 and obj.z ~= 0 and filter(obj.model)) then
					if not Items[obj.id] then
						Items[obj.id] = obj;
						--INFO("event.ONTICK.1: Added [ID: %s] - %s", obj.id, obj.model);
					end
				end
			end

			-- Deal with the Items_Action:
			for k, action in pairs(Items_action) do
				if CHECK_OBJECT(k) then
					local Item = GET_OBJECT(k);
					if (Item and Item.x == 0 and Item.y == 0 and Item.z == 0) then
						if action == "DELETE" then
							DELETE_OBJECT(k);
							INFO("ItemArray[%i]: delete %s", Item.quality, Item.model);
							Items_action[k] = nil;
							return;
						elseif action == "DISMANTLE" then
							DISMANTLE_OBJECT(k);
							INFO("ItemArray[%i]: dismantle %s [%s]", Item.quality, Item.model, Item.id);
							Items_action[k] = nil;
							return;
						elseif action == "IDENTIFY" then
							IDENTIFY_OBJECT(k);
							INFO("ItemArray[%i]: identify %s [%s]", Item.quality, Item.model, Item.id);
							Items_action[k] = nil;
							return;
						elseif action == "DO NOTHING" then
							--ERROR("======================");
							--ERROR("Item Action Default");
							--print_r(Item);
							--ERROR("======================");
							Items_action[k] = nil;
						end
					else
						Items_action[k] = nil;
					end
				end
			end
			
		else
			Items = {};
			Items_action = {};
		end
	end);

	-- ItemArray_handle3
	--
	-- Handles Player location. Collision detection. Item pickups.
	-- Item location etc.
	ItemArray_handle3 = register(event.ONTICK,
		function()
			if isIngame() and not isPaused() then
				for k, v in pairs(Items) do
					processItem(k);
				end
			end
		end
	);
end

function ItemQualityText(q)
	local text = "Unknown";

	-- myth has shifted quality values
	if TARGET == "myth" then
		q = q - 1;
	end
	
	if q == 1 then text = "NORMAL" end -- White
	if q == 2 then text = "ENHANCED" end -- Green
	if q == 3 then text = "RARE" end -- Blue
	if q == 4 then text = "LEGENDARY" end -- Orange
	if q == 5 then text = "UNIQUE" end -- Yellow
	if q == 6 then text = "MYTHIC" end -- Red
	if q == 7 then text = "SET" end -- Purple
	
	return text;
end

function filter(model)
	if model then
		for k, v in pairs(Ignore_Items) do
			if v == model then
				--INFO("FILTER: [%s] - is ignored.", model);
				return false;
			end
		end
		return true;
	end
end

function processItem(k)
	local px, py, pz = _G.getCoords();
	local ix, iy, iz;
	local cbool, cx, cy, cz, cstat, cobj, cd;
	local obj;
	if CHECK_OBJECT(k) then
		obj = GET_OBJECT(k);
		ix, iy, iz = obj.getCoords();
		--cbool, cx, cy, cz, cstat, cobj = hell_map.checkCollision(px, py, pz, ix, iy, iz);
	else
		return;
	end

	--if utils.vecDist(px, py, pz, ix, iy, iz) <= MAXDIST and hell_map.checkCollision(px, py, pz, ix, iy, iz) then
	if utils.vecDist(px, py, pz, ix, iy, iz) <= MAXDIST then
		if (obj.model == "rocket" or obj.model == "tech" or obj.model == "ammo" or obj.model == "battery" or obj.model == "relic" or obj.model == "fuel") then
			if (ModByPass and obj.quality >= ModByPass) then
				GRAB_OBJECT(obj.id);
				Items[obj.id] = nil;
				delay(2000, function(e) IDENTIFY_OBJECT(obj.id) end);
				printf("ModByPass: %s [%s]", obj.model, obj.quality);
				return;
			end
		end

		--INFO("event.ONTICK.2: GRAB [ID: %s] - %s", obj.id, obj.model);
		grabitem(obj.id);
		Items[obj.id] = nil;
	--else
		--printf("X: %s Y: %s Z: %s DIST: %s", cx, cy, cz, utils.vecDist(px, py, pz, cx, cy, cz));				end
	end
end

function grabitem(iid)
	local obj = GET_OBJECT(iid);

	GRAB_OBJECT(obj.id);
	Items_action[obj.id] = "DO NOTHING";

	if obj.model == "gold" or obj.model == "analyzer" or string.find(obj.model, "medpack") or string.find(obj.model, "powerpack") then
		Items_action[obj.id] = nil;
		return;
	end

	-- trash low budget blueprints
	if string.find(obj.model, "_blueprint") and obj.quality >= 1 and obj.quality < Itemquality then
		Items_action[obj.id] = "DELETE";
		return;
	end

	-- only dismantle bigger items with known quality
	if obj.quality >= 1 and obj.quality < Itemquality then
		Items_action[obj.id] = "DISMANTLE";
		--DISMANTLE_OBJECT(obj.id);
		return;
	end

	-- identify remaining unidentified objects
	if not obj.getStats("identified") or not obj.getStats("identified") == 1 then
		Items_action[obj.id] = "IDENTIFY";
	end
end

--[[ Adding additional Items to Filter out. ]]--
table.insert(Ignore_Items, "maggotspawn");

-- start when ready
register("STARTUP", function()
	ItemArray.enable(Itemquality, ModByPass)
end);
