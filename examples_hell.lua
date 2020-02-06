--- hell examples module
--
module("examples_hell", package.seeall);

--[[ include any depencies ]]--
require("hell/hell");
require("common/event");
require("common/utils");
require("common/persistence");

--[[ logger shortcuts ]]--
require("common/log");
local function DEBUG(fmt, ...) log.DEBUG(_NAME, fmt, ...) end
local function INFO (fmt, ...) log.INFO (_NAME, fmt, ...) end
local function WARN (fmt, ...) log.WARN (_NAME, fmt, ...) end
local function ERROR(fmt, ...) log.ERROR(_NAME, fmt, ...) end
local function FATAL(fmt, ...) log.FATAL(_NAME, fmt, ...) end

--
-- MOVEBOT
--
local movebot_handle = nil;
local DIGITS = 0;
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
		INFO("move x:"..cx.." y:"..cy.." z:"..cz.." reached");
		unregister(movebot_handle);
		movebot_handle = nil;
		return;
	else
		vx, vy, vz = roundCoords(hell_env.checkCollision(x, y, z));
		dx, dy, dz = roundCoords(x, y, z);
		if(vx == dx and vy == dy and vz == dz) then
			INFO("move x:"..dx.." y:"..dy.." z:"..dz.." can be reached without collision");
			hell_cam.lookAt(x, y, z);
			hell_move.moveForwardStart();
		else
			INFO("move Collision at x:"..vx.." y:"..vy.." z:"..vz);
			unregister(movebot_handle);
			movebot_handle = nil;
			return;
		end
	end
end
--- this starts a simple moveTo to algorithm that stop at the first collision
function moveTo(x, y, z)
	if not movebot_handle then
		movebot_handle = register(event.ONTICK, function() move(x, y, z) end);
	end
end

--- stops the moveTo algorithm
function moveStop()
	if movebot_handle then
		unregister(movebot_handle);
		movebot_handle = nil;
		hell_move.moveStop();
	end
end
-- kill trigger
register(event.PAUSE, function(e)
	if (e.pause) then moveStop() end
end);
--
-- END: MOVEBOT
--


--
-- AUTO POT
--
-- Automatically takes Healing and Mana potions at given percentage
--
-- Usage:  startAP(50, 50)
--
local HP_READY = getCurrentMillis();
local MP_READY = getCurrentMillis();
local function callAP(percent_heal, percent_mana)
	-- [[ HEAL ]]--
	local maxhp = hell_char.getData()["Max HP"];
	local curhp = hell_char.getData()["Current HP"];
	if not maxhp or not curhp then return end
	if (curhp/maxhp*100) <= percent_heal and HP_READY < getCurrentMillis() then
		local obj = hell_inv.search("medpack")[1];
		if obj then
			-- in hell HP causes cooldown of 10 secs and MP cooldown of 5 secs
			HP_READY = getCurrentMillis() + 10000;
			MP_READY = getCurrentMillis() + 5000;
			INFO("Auto Potter - HEAL");
			obj.use();
		end
	end
	
	-- [[ MANA ]]--
	local maxmp = hell_char.getData()["Max Power"];
	local curmp = hell_char.getData()["Current Power"];
	if not maxmp or not curmp then return end
	if (curmp/maxmp*100) <= percent_mana and MP_READY < getCurrentMillis() then
		local obj = hell_inv.search("powerpack")[1];
		if obj then
			-- in hell MP causes cooldown of 10 secs and HP cooldown of 5 secs
			HP_READY = getCurrentMillis() + 5000;
			MP_READY = getCurrentMillis() + 10000;
			INFO("Auto Potter - MANA");
			obj.use();
		end
	end
end
--- call to start auto potter at a given percentage for health an mana
function startAP(percent_heal, percent_mana)
	register("STARTUP", function(e)
		if type(percent_heal) ~= "number" then percent_heal = 50 end
		if type(percent_mana) ~= "number" then percent_mana = 50 end
		INFO("Auto Potter - HEAL %i%%  MANA %i%%", percent_heal, percent_mana);
		register(event.ONTICK, function(e)
			if not isIngame() then return end 
			callAP(percent_heal, percent_mana) 
		end);
	end);
end
--
-- END: AUTO POT
--


--
-- AUTO SHOPPER
--
-- Automatically buys stuff when at merchant.
--
-- Usage: startAS({["large medpack"]=20, ["large powerpack"]=20, ["analyzer"]=20});
--
local AS_INVENTORY = hell_inv.MERCH_MISC;
local LAST_MERC = nil;
local function callAS(tabledata_buy)
	if LAST_MERC == hell_env.getNpcId_C() then return end
	LAST_MERC = hell_env.getNpcId_C();
	local tabledata_inv = {};
	-- first scan contents of players inventory
	for pattern,qty in pairs(tabledata_buy) do
		tabledata_inv[pattern] = 0;
		for _,i in pairs(hell_inv.MAIN.search(pattern)) do
			local qty = i.getStats("item_quantity");
			if qty == nil then qty = 1 end
			-- increment inventory table by found qty
			tabledata_inv[pattern] = tabledata_inv[pattern] + qty;
		end
	end 
	-- now lets go shopping
	for pattern,qty in pairs(tabledata_buy) do
		local shop_item = AS_INVENTORY.search(pattern)[1];
		if shop_item ~= nil then
			local diff = qty - tabledata_inv[pattern];
			if diff > 0 then
				INFO("Auto Shopper - buy  %s[%i]", pattern, diff);
				--hell_inv.MAIN.move(shop_item); -- inv move is no go for shopping
				hell_env.buy_C(shop_item.id, LAST_MERC, diff);
			else
				INFO("Auto Shopper - enough of %s[%i]", pattern, tabledata_inv[pattern]);
			end
		else
			INFO("cant buy %s[%i] here", pattern, qty);
		end
	end
end
--- call to start auto buy. 
-- @param tabledata_buy is a table of string->qty mappings to have in inventory. 
-- @usage startAS({["major health potion"]=20, ["major mana potion"]=20, ["scrying stone"]=20})
function startAS(tabledata_buy) 
	register("STARTUP", function(e)
		-- dirty hack to check if merchant is available (test merchant inventory not empty)
		INFO("Auto Shopper - active");
		register("ONTICK", function(e)
			if not isIngame() then return end
			if AS_INVENTORY[1][1] then
				callAS(tabledata_buy);
			else
				LAST_MERC = nil;
			end
		end);
	end);
end
--
-- END: AUTO SHOPPER
--


--
-- AUTO INTERACTOR
--
-- Opens Boxes, Doors, Ores ... automatically when beeing close to then
--
-- Usage: startAI()
local AI_MAXDIST = 2.5;
local AI_SCAN_DELAY = 5003;
local AI_IDS = {};

local AI_UNITFLAGS = {
	CRATE = 210,
}

local function callAI()
	-- scan for boxes and doors to use
	local player = hell_env.getPlayer();
	for id,timestamp in pairs(AI_IDS) do
		if hell_env.check(id) then
			local obj = hell_env.get(id);
			if timestamp < getCurrentMillis() - 2000 and obj and obj.getDist() < AI_MAXDIST then
				AI_IDS[id] = getCurrentMillis();
				if obj.unitflags == AI_UNITFLAGS.CRATE and obj.getStats("skill_seed 5") == nil then
					INFO("Auto Interactor - CRATE [%i] %03i %s", obj.id, obj.unitflags, obj.model);
					hell_skill.fire("Use_Both_Weapons", obj.x,obj.y,obj.z);
				end
			end
		end
	end
end
--- call to start interactor
function startAI() 
	register("STARTUP", function(e)
		INFO("Auto Interactor active");
		register(event.ONTICK, function(e)
			if not isIngame() then return end 
			callAI(); 
		end);
	end);
	-- delay full scan
	timer(AI_SCAN_DELAY, function()
		if not isIngame() then return end 
		AI_IDS = {};
		-- check for objects with requested unitflags
		for id, obj in pairs(hell_env.getEnvObjects()) do
			for s,unit_flags in pairs(AI_UNITFLAGS) do
				if obj.unitflags == unit_flags then
					AI_IDS[id] = -1;
				end
			end
		end
	end);
end
--
-- END: AUTO INTERACTOR
--

