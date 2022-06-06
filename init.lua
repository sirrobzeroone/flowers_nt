----------------------------------------------------------
--        ___ _                         _  _ _____      --
--       | __| |_____ __ _____ _ _ ___ | \| |_   _|     --
--       | _|| / _ \ V  V / -_) '_(_-< | .` | | |       --
--       |_| |_\___/\_/\_/\___|_| /__/ |_|\_| |_|       --
----------------------------------------------------------
--                  Flowers Node Timer                  --
----------------------------------------------------------
--   Full Credit to Shara and the "Endless Apple" mod   --
--    for providing the concept for this process.       --
----------------------------------------------------------
-- modname and path
local m_name = minetest.get_current_modname()
local m_path = minetest.get_modpath(m_name)

-- setup mod global table and registered flowers table
flowers_nt = {}
flowers_nt.registered_flowers = {}

-- Settings, bit excessive but was intresting to do
dofile(m_path .. "/i_get_settintype.lua")
local stringtoboolean={ ["true"]=true, ["false"]=false }

flowers_nt.settings = {} 
flowers_nt.settings.seed_head_spread = tonumber(minetest.settings:get("fnt_seed_head_spread") or flowers_nt.get_setting("fnt_seed_head_spread"))
flowers_nt.settings.density = tonumber(minetest.settings:get("flowers_nt_density") or flowers_nt.get_setting("flowers_nt_density"))
flowers_nt.rollback = stringtoboolean[minetest.settings:get("rollback") or flowers_nt.get_setting("rollback")]
flowers_nt.rollback_replace = {}

--files to load	
dofile(m_path .. "/i_api.lua")

-- Specific game files to load
local game_id = Settings(minetest.get_worldpath()..DIR_DELIM..'world.mt'):get('gameid')
flowers_nt.game_tail = ""

if game_id == "minetest" then
	dofile(m_path.. "/i_game_mtg.lua" )
end

if game_id == "voxelgarden" then
	flowers_nt.game_tail = "_vg"
	dofile(m_path.. "/i_game_vg.lua" )
end

-- if Bonemeal mod loaded
if minetest.get_modpath("bonemeal") ~= nil then
	dofile(m_path.. "/i_bonemeal_override.lua" )		
end

-- Load confirmation 
-- minetest.debug("[MOD] flowers_nt loaded")






	






