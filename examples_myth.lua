--- myth examples module
--
module("examples_myth", package.seeall);

--[[ include any depencies ]]--
require("myth/myth");
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
		local obj = hell_inv.search("health potion")[1];
		if obj and obj.stats["skill_cooldown"] then
			-- the cooldown var measures in 1/20 friction of a second
			HP_READY = getCurrentMillis() +  obj.stats["skill_cooldown"] * 50;
			INFO("Auto Potter - HEAL");
			obj.use();
		end
	end
	
	-- [[ MANA ]]--
	local maxmp = hell_char.getData()["Max Power"];
	local curmp = hell_char.getData()["Current Power"];
	if not maxmp or not curmp then return end
	if (curmp/maxmp*100) <= percent_mana and MP_READY < getCurrentMillis() then
		local obj = hell_inv.search("mana potion")[1];
		if obj and obj.stats["skill_cooldown"] then
			-- the cooldown var measures in 1/20 friction of a second
			MP_READY = getCurrentMillis() + obj.stats["skill_cooldown"] * 50;
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
-- Usage: startAS({["major health potion"]=20, ["major mana potion"]=20, ["scrying stone"]=20});
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
local AI_SCAN_DELAY = 5007;
local AI_IDS = {};

local AI_UNITTYPES = {
	ORE = 77,
	DOOR_BOX = 103,
	PILE = 490,
	CRATE = 105,
	BARREL = 106,
}

local function callAI()
	-- scan for boxes and doors to use
	local player = hell_env.getPlayer();
	for id,timestamp in pairs(AI_IDS) do
		if hell_env.check(id) then
			local obj = hell_env.get(id);
			if timestamp < getCurrentMillis() - 2000 and obj and obj.getDist() < AI_MAXDIST then
				AI_IDS[id] = getCurrentMillis();
				if obj.unittype == AI_UNITTYPES.ORE and obj.getStats("skill_seed 4") == nil then
					INFO("Auto Interactor - ORE [%i] %03i %s", obj.id, obj.unittype, obj.model);
					obj.interact();
				end
				if obj.unittype == AI_UNITTYPES.DOOR_BOX and obj.getStats("skill_seed 2") == nil and obj.getStats("block_movement") ~= 2 then
					INFO("Auto Interactor - DOOR_BOX [%i] %03i %s", obj.id, obj.unittype, obj.model);
					obj.interact();
				end
				if obj.unittype == AI_UNITTYPES.PILE and obj.getStats("skill_seed 2") == nil then
					INFO("Auto Interactor - PILE [%i] %03i %s", obj.id, obj.unittype, obj.model);
					obj.interact();
				end
				if obj.unittype == AI_UNITTYPES.CRATE and obj.getStats("skill_seed 6") == nil then	-- also "state 18" and "state 20" set
					INFO("Auto Interactor - CRATE [%i] %03i %s", obj.id, obj.unittype, obj.model);
					--myth_combat.attackToPrimary(obj.x,obj.y,obj.z);
					myth_combat.fireSkill("MeleeKick", obj.x,obj.y,obj.z);
				end
				if obj.unittype == AI_UNITTYPES.BARREL and obj.getStats("skill_seed 6") == nil then	-- also "state 18" and "state 20" set
					INFO("Auto Interactor - BARREL [%i] %03i %s", obj.id, obj.unittype, obj.model);
					--myth_combat.attackToPrimary(obj.x,obj.y,obj.z);
					myth_combat.fireSkill("MeleeKick", obj.x,obj.y,obj.z);
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
		-- check for objects with requested unittype
		for id, obj in pairs(hell_env.getEnvObjects()) do
			for s,unit_id in pairs(AI_UNITTYPES) do
				if obj.unittype == unit_id then
					AI_IDS[id] = -1;
				end
			end
		end
	end);
end
--
-- END: AUTO INTERACTOR
--

