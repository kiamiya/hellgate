-- mmBBQ [sro] specific configuration.
--
-- It contains LUA syntax, so you may also
-- add additional code directly in this file.
--
module("config_sro", package.seeall);


----------------------
-- ADDITIONAL MODULES 
----------------------
--require("your_mod");
--dofile("your_file.lua");


----------------------
-- CHAT CONFIG
----------------------
SPAMFILTER = true;
SPAMSCORE = 3; -- score needed in order to filter spam
SPAMLOG = true; -- whether to log suppressed spam
SPAMWORDS = {
	-- generic spam patterns
	["h.t.t.p"] = 2, -- H T T P
	["w.w.w"] = 2, -- W W W
	["====="] = 1, -- frequently used by spammers
	["USD"] = 1, -- USD
	["[$€£]"] = 1, -- CURRENCIES
	["c.?h.?[eE3].?[aA4].?p"] = 1, -- CHE4P
	["[gG].?[oO0].?[lL].?[dD]"] = 1, -- g0ld
	["p.?[aA4].?[lL1].?[lL1].?[aA4].?d.?[iI1].?u.?m"] = 1, -- PALLADIUM
	
	-- known spam companies
	["[wW].?[oO0].?[wW].?[eE3].?[vV].?[eE3]"] = 3, -- woweve.com
	["[mM].?[mM].?[oO0].?[4].?[sS].?[tT].?[eE3]"] = 3, -- mmo4store
	["[gG].?[oO0].?[lL1].?[dD].?[aA4].?[aA4]"] = 3, -- goldaa
    ["[rR].?[mM].?[4].?[tT]"] = 3, -- rm4t
	["[sS].?[aA4].?[lL1].?[eE3].?[dD].?[iI1].?[aA4].?[bB].?[lL1].?[oO0]"] = 3, -- salediablo3
	["[pP].?[vP].?[pP].?[bB].?[aA4].?[nN].?[kK]"] = 3, -- PVPBANK
	["G.?[o0].?[l1].?D.?C.?[3eE].?[o0]"] = 3, -- GOLDCEO
	["[eE3].?g.?p.?[aA4].?[lL1]"] = 3, -- EGPAL
	["m.?m.?[o0].?[o0].?k"] = 3, -- MMOOK
	["[iI1].?g.?[eE3].?v.?[eE3]"] = 3, -- IGEVE
	["t.?p.?[l1].?c.?[e3].?[o0]"] = 3, -- TPLCE0
};


---------------------
--       LOGIN CREDENTIALS  
--  >> OPTIONAL. NOT REQUIRED  <<
---------------------
-- replace and uncomment 
-- with your credentials
--AUTOLOGIN = true;
--USERNAME = "foo";
--PASSWORD = "bar";
--SERVER = "server";
--PIN = "313373";
--CHARNAME = "foobar";


