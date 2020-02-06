module("PickitMaison", package.seeall);

--[[ include any depencies ]]--
require("common/log");
require("common/utils");
require("common/event");

-------------------------------------------
----------PICKIT AND AUTODISMANTLE---------
-------------------------------------------
--
-- PICKIT
--

function start(quality)
	register("STARTUP", function(e)
		pickit(quality);
		local loot_handle = register(event.ONTICK, function() checkloot(quality) end);
	end);
end

local quality_text = {"NORMAL", "ENHANCED", "RARE", "LEGENDARY", "UNIQUE", "SET", "MYTHIC"};
local pickit_handle = nil;
local ticktack=0;

function checkloot(quality)
	local state = hell_global.getGamestate();
	if state == 9 then
		ticktack = ticktack +1;
		if ticktack == 40 then
			for k, obj in pairs(hell_env.getEnvObjects()) do
				if type(obj.quality) ~= "nil" and obj.x ~= 0 and obj.y ~= 0 and obj.z ~= 0 then
					if obj.model == "worldcup_ball" or obj.model == "1year_event_coin" or obj.model == "nanoshard" then
						hell_inv.grabObj(obj.id);
					elseif string.find(obj.model, "bonehead") or string.find(obj.model, "pumpkin") or string.find(obj.model, "glowskull") or string.find(obj.model, "horseman") then
						hell_inv.dismantleObj(obj.id);
					elseif string.find(obj.model, "halloween") then
						local a=0;
					elseif obj.quality == 4 and obj.model == "tech" or obj.model == "ammo" or obj.model == "battery" or obj.model == "relic" or obj.model == "fuel" or obj.model == "rocket" or string.find(obj.model, "bolter") or string.find(obj.model, "cannonade") then
						hell_inv.grabObj(obj.id);
					elseif obj.quality >= quality then
						hell_inv.grabObj(obj.id);
					else
						hell_inv.dismantleObj(obj.id);
					end
				end
			end
			ticktack = 0;
		end
	end
end

--- pickit and auto dissmantler
function pickit(quality)

    if pickit_handle then
        unregister(pickit_handle);
        pickit_handle = nil;
    end
	
    if not quality then
   -- qualite a conservee
   -- 3:rare 4:leg 5:unique 6:mythic 7:set
		quality = 4;
		
   end
   
   log.INFO("Pickit ", quality_text[quality]);
   
    pickit_handle = register(event.ENV_DROP,
        function(e)
            local obj = e.obj;
            
			if obj.id ~= nil and obj.quality ~= nil then
			--hell_inv.grabObj(obj.id);

				--printf("START PICKIT[%i]: %s", obj.quality, obj.model);
				 
				-- on ignore gold, adrenaline, coupon, nano
				if obj.model == "gold" or string.find(obj.model, "worldcup") or obj.model == "adrenaline" or obj.model == "nanoshard" or string.find(obj.model, "bosshead_") or string.find(obj.model, "cube_ingredient") or obj.model == "1year_event_coin" then
					hell_inv.grabObj(obj.id);
				if string.find(obj.model, "worldcup") then
					printf("DROP COUPON");
				end
				if string.find(obj.model, "1year_event_coin") then
					printf("DROP ANNIVERSARY COIN");
				end
					return;
				elseif string.find(obj.model, "bonehead") or string.find(obj.model, "pumpkin") or string.find(obj.model, "glowskull") or string.find(obj.model, "horseman") then
					hell_inv.dismantleObj(obj.id);
				elseif string.find(obj.model, "halloween") then
					return;
				--si mieu ou si legendaire
				elseif obj.quality >= quality or obj.quality >= 4 then
					--si mods legendary
					if obj.quality == 4 then
						if obj.model == "tech" or obj.model == "ammo" or obj.model == "battery" or obj.model == "relic" or obj.model == "fuel" or obj.model == "rocket" or string.find(obj.model, "bolter") or string.find(obj.model, "cannonade") then
							hell_inv.grabObj(obj.id);
							--hell_inv.identifyObj(obj.id);
							printf("DROP [%s] : %s ", obj.qualityText, obj.model);
						--leg autres non mods
						else
							hell_inv.grabObj(obj.id);
							hell_inv.dismantleObj(obj.id);
						end
					
					else
						printf("DROP [%s] : %s ", obj.qualityText, obj.model);
						hell_inv.grabObj(obj.id);
					end
				return;
				
				--TP
				elseif obj.model == "townportal" or obj.model == "analyzer" then
					--hell_inv.grabObj(obj.id);
					return;
				
				--Essence
				elseif string.find(obj.model, "essence_") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					if string.find(obj.model, "essence_demon") then
						--hell_inv.grabObj(obj.id);
					end
					return;
				
				-- cryptex et xmas on vire
				elseif string.find(obj.model, "xmas_") or string.find(obj.model, "cryptex") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					--hell_inv.grabObj(obj.id);
					return;
				
				--medpack et mana
				elseif string.find(obj.model, "medpack") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					hell_inv.grabObj(obj.id);
					return;
				
				elseif string.find(obj.model, "powerpack") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					--hell_inv.grabObj(obj.id);
					return;
				
				--autres merde de def
				elseif string.find(obj.model, "extinguisher") or string.find(obj.model, "stabilizing") 
				or string.find(obj.model, "gyro") or string.find(obj.model, "shield") or string.find(obj.model, "antidote") or string.find(obj.model, "shunt") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					--hell_inv.grabObj(obj.id);
					return;

				-- blueprints
				elseif string.find(obj.model, "blueprint") then
					--printf("PICKIT[%i]: delete %s", obj.quality, obj.model);
					--printf("DROP [%s] : %s", obj.qualityText, obj.model);
					--hell_inv.grabObj(obj.id);
					return;
				
				-- casse les items inférieurs à la qualité definie	
				elseif obj.quality >= 1 and obj.quality < quality then
					hell_inv.grabObj(obj.id);
					--printf("PICKIT[%i]: dismantle %s : %s", obj.quality, obj.model, obj.tats);
					--printf("PICKIT[%i]: dismantle %s", obj.quality, obj.model);
					hell_inv.dismantleObj(obj.id);
					return;
				end
			end
        end
    );
end
