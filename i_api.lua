----------------------------------------------------------
--        ___ _                         _  _ _____      --
--       | __| |_____ __ _____ _ _ ___ | \| |_   _|     --
--       | _|| / _ \ V  V / -_) '_(_-< | .` | | |       --
--       |_| |_\___/\_/\_/\___|_| /__/ |_|\_| |_|       --
----------------------------------------------------------
--                  Flowers Node Timer                  --
----------------------------------------------------------

---------------------------
-- Waving Water Settings --
---------------------------
-- Adjust water wave settings to accomodate Liquid floating mesh plants
if not flowers_nt.rollback then
	local wave_speed = tonumber(minetest.settings:get('water_wave_speed'))
	local wave_height = tonumber(minetest.settings:get('water_wave_height'))

	if wave_speed > 2.5 then
		minetest.settings:set('water_wave_speed', 2.5)
	end
	if wave_height > 0.5 then
		minetest.settings:set('water_wave_height', 0.5)
	end
end

--------------------------
-- Flowers Ground Cover --
--------------------------
-- Scale should have nil impact on flower density, 
-- however doubling  scale did appear to increase 
-- density but this could be human brain interpretation error :)
 
flowers_nt.cover = {{["offset"] = -0.039,   ["scale"] = 0.04},    -- 1 about half of 2 - very rare
					{["offset"] = -0.035,   ["scale"] = 0.04},    -- 2 about half of 3 - about mushroom default distribution
					{["offset"] = -0.029,   ["scale"] = 0.04},    -- 3 about half of 4
					{["offset"] = -0.020,   ["scale"] = 0.04},    -- 4 same as flowers mod default distribution (-0.02/0.04) 
					{["offset"] = -0.015,   ["scale"] = 0.04},    -- 5 25%-ish more than 4
					{["offset"] = -0.005,   ["scale"] = 0.04},    -- 6 25%-ish more than 5
					{["offset"] =  0.009,   ["scale"] = 0.08},    -- 7 Maximum you realistically want to use
					{["offset"] =  0.050,   ["scale"] = 0.08}     -- 8 Everywhere - not super dense
			}

------------------
-- Flower Timer --
------------------
function flowers_nt.grow_flower_tmr(pos)

	local node_name = minetest.get_node(pos).name
	local fl_reg_name = flowers_nt.get_name(node_name)

	-- This shouldn't happen but just in case fl_reg_name returns false log an error 
	if fl_reg_name then 						
		local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
		local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
		local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
		local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death
		local time_min    = flowers_nt.registered_flowers[fl_reg_name].time_min
			
			if not flowers_nt.allowed_to_grow(pos) then
				minetest.remove_node(pos)
				
			elseif minetest.get_node_light(pos) < light_min and not l_min_death or 
				   minetest.get_node_light(pos) > light_max and not l_max_death then
				
					minetest.get_node_timer(pos):start(time_min)
					
			elseif minetest.get_node_light(pos) < light_min and l_min_death or 
				   minetest.get_node_light(pos) > light_max and l_max_death then
				
					minetest.remove_node(pos)											
			else
				flowers_nt.set_grow_stage(pos)				
			end
	else
		-- If this occurs continually may indicate someone delibratly trying to crash server/game
		-- Explanation: Somehow the flower node was removed between timer expiring and the above code running
		-- I honestly don't believe this event can occur without some form of CSM being deployed, but you never know. 
		minetest.log("info", "Flowers_NT:Timer fail - see mod flowers_nt >> i_api.lua code line 76") 
	end		
end

-----------------------------
-- Allowed to grow on node --
-----------------------------
function flowers_nt.allowed_to_grow(pos,reg_name)
	local node
	local node_below	
	local can_grow  = false
	
	if reg_name ~= nil then
		node_below = minetest.get_node(pos)
	else
		node       = minetest.get_node(pos)
		node_below = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})	
		reg_name   = flowers_nt.get_name(node.name)		
	end
	
	-- catches any strange events were node timer expires 
	-- but flower stage has vanished (falling node/tnt explosion for example)
	if reg_name then
		
		local grow_on    = flowers_nt.registered_flowers[reg_name].grow_on
		
		for k,node_name in pairs(grow_on) do
			if node_name == node_below.name then
				can_grow = true
				break
			end
		end	
	end
	return can_grow
end

---------------------------
-- Place next grow stage -- 
---------------------------
function flowers_nt.set_grow_stage(pos)
	local node = minetest.get_node(pos)
	local node_p2 = node.param2
	
	-- get reg name and stage
	-- Haven't used flowers_nt.get_name() as I need to set stage 3.
	-- Future add additional metric to get_name() to indicate orginally
	-- parent or existing.
	local reg_name    = string.sub(node.name, 0, -3)
	local cur_stage   = string.sub(node.name, -1)	
	local time_min
	local time_max
	local existing	
	local rot_place
	
	-- catch existing flower case and set current stage to 3 if found
	if type(flowers_nt.registered_flowers[reg_name]) == "table" then
		time_min  = flowers_nt.registered_flowers[reg_name].time_min
		time_max  = flowers_nt.registered_flowers[reg_name].time_max
		existing  = flowers_nt.registered_flowers[reg_name].existing
		rot_place = flowers_nt.registered_flowers[reg_name].rot_place
	else
		reg_name  = flowers_nt.registered_flowers[node.name].parent
		time_min  = flowers_nt.registered_flowers[reg_name].time_min
		time_max  = flowers_nt.registered_flowers[reg_name].time_max
		existing  = flowers_nt.registered_flowers[reg_name].existing
		rot_place = flowers_nt.registered_flowers[reg_name].rot_place
		cur_stage = 3
	end
	
	if cur_stage + 1 > 4 then
		-- reset to 0		
		-- new flower can grow any orientation
		if rot_place then
			node_p2 = math.random(0,3)
		end
		
		minetest.set_node(pos, {name = reg_name.."_0", param2 = node_p2})
	else
		-- catch existing and grow to from stage 2
		if existing ~= nil and cur_stage+1 == 3 then		
			minetest.set_node(pos, {name = existing, param2 = node_p2})
		else
			minetest.set_node(pos, {name = reg_name.."_"..cur_stage + 1, param2 = node_p2})
		end
	end
	
	if cur_stage + 1 >= 3 then
		-- flower and seed stage remain twice as long - arbitary timeframe
		minetest.get_node_timer(pos):start(math.random(2*(time_min), 2*(time_max)))
	else
		minetest.get_node_timer(pos):start(math.random(time_min, time_max))
	end
end

-------------------------
-- None Growing Flower --
-------------------------
-- Placed flower parts don't grow, but good for decorating
function flowers_nt.no_grow(pos)
	-- set meta flag
	local meta = minetest.get_meta(pos)
	meta:set_int("flowers_nt", 1)
	
	-- expire timer, covers case if flower placed on top of existing 
	-- flower location where a timer may already be running.
	minetest.get_node_timer(pos):stop()
end

----------------------------------------
-- None Growing Placed Floating Plant --
----------------------------------------
function flowers_nt.on_place_water(itemstack, placer, pointed_thing)
		local u_pos = pointed_thing.under
		local a_pos = pointed_thing.above
		local a_name = minetest.get_node(a_pos).name
		local u_name = minetest.get_node(u_pos).name
		local reg_name = flowers_nt.get_name(itemstack:get_name())
		local grow_on = flowers_nt.registered_flowers[reg_name].grow_on
		local can_grow = false
				
		for k,g_name in pairs(grow_on)do
			if g_name == u_name then
				can_grow = true
				break
			end		
		end
		
		if can_grow and minetest.registered_nodes[a_name].drawtype == "airlike" then		
			pointed_thing.under = a_pos
			pointed_thing.above = {x=a_pos.x, y=a_pos.y+1, z=a_pos.z}
				
			minetest.item_place_node(itemstack, placer, pointed_thing)
		end
	return itemstack
end

---------------------------
-- Restart flower cycle --
---------------------------
-- Once a growing flower is picked it will start to re-grow
function flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)	
	local output = false
	local old_flowers_nt = oldmetadata.fields.flowers_nt or nil

	-- no meta so not picked and placed flower
	if old_flowers_nt == nil then
		local reg_name  = flowers_nt.get_name(oldnode.name)
		local rot_place = flowers_nt.registered_flowers[reg_name].rot_place
		local time_min  = flowers_nt.registered_flowers[reg_name].time_min
		local time_max  = flowers_nt.registered_flowers[reg_name].time_max
		local node_p2   = "N"
		
		if rot_place then
			node_p2 = math.random(0,3)
		end
			
		minetest.set_node(pos, {name = reg_name.."_0", param2 = node_p2})
		minetest.get_node_timer(pos):start(math.random(time_min, time_max))
		output = true
	end
	return output
end

-------------------------
-- Get Flower Reg Name --
-------------------------
-- Get the registered flower name from the node_name
function flowers_nt.get_name(node_name)
	local reg_name = string.sub(node_name, 0, -3)	
	local p_name
	
-- catch existing flower case
	if type(flowers_nt.registered_flowers[reg_name]) == "table" then
		p_name = reg_name
	elseif type(flowers_nt.registered_flowers[node_name]) == "table" then
		p_name = flowers_nt.registered_flowers[node_name].parent
	else
		p_name = false
	end	
	
	return p_name
end

----------------------
-- Seed Head Spread --
----------------------
function flowers_nt.seed_spread(pos,oldnode,player)
	-- idea implimented from a comment by Paramat	
	local minp = {x=pos.x-1,y=pos.y-2,z=pos.z-1}
	local maxp = {x=pos.x+1,y=pos.y+1,z=pos.z+1}		
	local reg_name = flowers_nt.get_name(oldnode.name)
	local is_water = flowers_nt.registered_flowers[reg_name].is_water
	local time_min = flowers_nt.registered_flowers[reg_name].time_min
	local time_max = flowers_nt.registered_flowers[reg_name].time_max
	local grow_on  = flowers_nt.registered_flowers[reg_name].grow_on
	local rot_place = flowers_nt.registered_flowers[reg_name].rot_place
	local seed_spread = flowers_nt.settings.seed_head_spread
	local set_density = flowers_nt.settings.density
	local node_p2   = "N"
	local node_names
	local flower_density

	if flowers_nt.registered_flowers[reg_name].parent ~= nil then
		reg_name = flowers_nt.registered_flowers[reg_name].parent
	end
	
	-- Build target nodes table
	if flowers_nt.registered_flowers[reg_name].existing == nil then
		node_names = {reg_name.."_1", reg_name.."_2",reg_name.."_3",
					  reg_name.."_4",reg_name.."_0"}	
	else
		node_names = {reg_name.."_1",reg_name.."_2",flowers_nt.registered_flowers[reg_name].existing,
					  reg_name.."_4",reg_name.."_0"}		
	end
	
	flower_density = minetest.find_nodes_in_area_under_air(minp, maxp,node_names)

	-- Safe to use # as we have numeric table of pos's only, spread only occurs a set % of the time	
	if #flower_density <= set_density and math.random(1,100) <= seed_spread then
		local look_deg = 360-math.deg(player:get_look_horizontal())
		local x = 0
		local z = 0
		
		-- 45 to 316 = Z+, 46 to 135 = X+, 136 to 225 Z-, 226 to 315 X- 		
			if     look_deg >= 46  and look_deg <= 135 then x = 1	
			elseif look_deg >= 136 and look_deg <= 225 then z = -1		
			elseif look_deg >= 226 and look_deg <= 315 then x = -1
			else  z = 1
			end
		-- offset forward the way player was facing ie seeds will fall in front of player	
		if z == 1 then
			minp = {x=pos.x-1,y=pos.y-2,z=pos.z}
			maxp = {x=pos.x+1,y=pos.y+1,z=pos.z+1}
		elseif z == -1 then
			minp = {x=pos.x-1,y=pos.y-2,z=pos.z-1}
			maxp = {x=pos.x+1,y=pos.y+1,z=pos.z}
		elseif x == 1 then
			minp = {x=pos.x,y=pos.y-2,z=pos.z-1}
			maxp = {x=pos.x+1,y=pos.y+1,z=pos.z+1}
		else -- x == -1
			minp = {x=pos.x-1,y=pos.y-2,z=pos.z-1}
			maxp = {x=pos.x,y=pos.y+1,z=pos.z+1}		
		end

		local air_nodes = minetest.find_nodes_in_area_under_air(minp, maxp,grow_on)
		local ran_nodes = {}
		-- remove our pos node flower marker as it is airlike so is included in ran_nodes 		
		for _,a_pos in pairs(air_nodes) do
			local o_pos = minetest.pos_to_string(pos)
			local r_pos = minetest.pos_to_string({x=a_pos.x,y=a_pos.y+1,z=a_pos.z})			
						
			if o_pos == r_pos then
				--minetest.debug("removed: "..r_pos)
			else
				table.insert(ran_nodes, minetest.string_to_pos(r_pos))
			end			
		end	
		if #ran_nodes > 1 then	
			local index = math.random(1,#ran_nodes)
			
			if rot_place then
				node_p2 = math.random(0,3)
			end
			-- drop the seed on our selected node using particles and set marker/timer				
			flowers_nt.seed_place_effect(ran_nodes[index],reg_name)			
			minetest.set_node(ran_nodes[index], {name = reg_name.."_0", param2 = node_p2})
			minetest.get_node_timer(ran_nodes[index]):start(math.random(time_min, time_max))			
		end
	end
end
-----------------------
-- Seed Place Effect --
-----------------------
function flowers_nt.seed_place_effect(pos, fl_reg_name)	
	local amount = 	math.random(1,3)	
	minetest.add_particlespawner({
		   amount = amount,
		   time = 2,
		   minpos = pos,
		   maxpos = pos,
		   minvel = {x=0, y=-1, z=0},
		   maxvel = {x=0, y=0, z=0},
		   minacc = {x=0, y=-1, z=0},
		   maxacc = {x=0, y=0, z=0},
		   minexptime = 1,
		   maxexptime = 1,
		   minsize = 6,
		   maxsize = 6,
		   collisiondetection = false,
		   collision_removal = false,
		   object_collision = false,
		   vertical = false,
		   texture = minetest.registered_nodes[fl_reg_name.."_5"].tiles[1]
			})			
end

-----------------------
-- Delete Decoration --
-----------------------
function flowers_nt.delete_decoration(dec_name)
	-- need to remove the existing decoration registeration, unfortunatly just clearing
	-- the value from minetest.registered_decorations table does not work. Very heavy handed
	-- clearing all decs and then re-register all but the one, but I've found no other
	-- way to do this.
	-- See: https://forum.minetest.net/viewtopic.php?f=47&t=25925

	local reg_dec_cpy = table.copy(minetest.registered_decorations)
	minetest.clear_registered_decorations()
	for k,v in pairs(reg_dec_cpy) do
		if dec_name ~= k then minetest.register_decoration(v) else end		
	end
end

----------------------------------
-- Add to Registered Decoration --
----------------------------------
function flowers_nt.add_to_decoration(dec_names)


end
-----------------
-- Disable ABM --
-----------------
function flowers_nt.disable_abm(abm_label)
	local reg_abm = minetest.registered_abms
	
	for k,def in pairs(reg_abm) do
		if def.label == abm_label then			
			table.remove(minetest.registered_abms, k)		
		end
	end
end

------------------------------
--   Register Flower Nodes  --
------------------------------
flowers_nt.register_flower = function(def)

	local m_name = minetest.get_current_modname()
	local S = minetest.get_translator(m_name)
	-- Split the name value provided into desc value and registered 
	-- name value - minor character checking and cleanup
	local name       = string.lower(def.flower_name or "Mandatory")
	local reg_name   = string.gsub(name," ","_")
	local desc_name  = string.gsub(name,"_"," ")
		  --https://stackoverflow.com/questions/20284515/capitalize-first-letter-of-every-word-in-lua (thanks to: n1xx1)
	      desc_name  = string.gsub(" "..desc_name, "%W%l", string.upper):sub(2)
	local stage_1_name = def.stage_1_name or " Seedling"
	local stage_2_name = def.stage_2_name or " Budding"
	local stage_3_name = def.stage_3_name or ""
	local stage_4_name = def.stage_4_name or " Seed Head"
	local stage_5_name = def.stage_5_name or " Seed"
	local grow_on    = def.grow_on
	local place_on   = table.copy(def.grow_on)
	local biomes     = def.biomes
	local seed       = def.biome_seed
	local offset     = flowers_nt.cover[def.cover or 4].offset
	local scale      = flowers_nt.cover[def.cover or 4].scale
	local y_max      = def.y_max or 31000
	local y_min      = def.y_min or 1
	local y_offset   = 0
	local rot_place  = def.rot_place or false
	local color      = string.lower(def.color or "nil")
    local e_groups   = def.e_groups or nil
	local sounds     = def.sounds or nil
	local light_src  = def.light_source or nil
	local light_min  = def.light_min or 12
	local light_max  = def.light_max or 15
	local l_min_death= def.light_min_death or false
	local l_max_death= def.light_max_death or false
	local time_min   = def.time_min  or 60
	local time_max   = def.time_max  or 180
	local drawtype   = def.drawtype or "plantlike"
	local mesh       = def.mesh or nil
	local inv_img    = def.inv_img or false
	local inv_img_n  = m_name.."_"..reg_name
	local is_water   = def.is_water or false
	local walkable   = def.walkable or false
	local sel_box    = def.sel_box  or {-0.3,-0.5,-0.3,0.3,0.25,0.3}
	local on_use     = def.on_use or nil
	local on_punch_2 = def.on_punch_2 or nil	
	local on_punch_3 = def.on_punch_3 or nil
	local on_punch_4 = def.on_punch_4 or nil
	local existing   = def.existing or nil
	local s3_name    = m_name..":"..reg_name.."_3"
	local gt         = flowers_nt.game_tail
	local valid_data = true
	
	-- Mandatory fields check
	if existing ~= nil then
		if name    == "Mandatory" or 
		   grow_on == nil then	
			
			valid_data = false
		end		
	else
		if name    == "Mandatory" or 
		   grow_on == nil or
		   biomes  == nil or 
		   seed    == nil then	
			
			valid_data = false
		end	 	
	end

	if not valid_data then
		minetest.log("info", "Flowers_NT - Mandatory data not supplied to register flower. See Readme for Mandatory fields") 

	else
		-- Catch unsupported drawtypes
		if drawtype ~= "mesh" and drawtype ~= "plantlike" and drawtype ~= "torchlike" then
			drawtype = "plantlike"
			minetest.log("info", "Flowers_NT - Unsupported drawtype for "..def.flower_name.." changed to plantlike.") 
		end

		-- is_water may have node names to ignore
		if type(is_water) == "table" then		
			for _,node_name in pairs(is_water) do			
				for k,g_node_name in pairs(grow_on) do
					if g_node_name == node_name then
						table.remove(grow_on, k)
					end			
				end		
			end		
			is_water = true
		end
		
		-- Unique inv image case
		if inv_img then
			inv_img_n = m_name.."_"..reg_name.."_inv"	
		end
		
		if flowers_nt.rollback == false then
			-- Add flower to global registered_flowers table.
			flowers_nt.registered_flowers[m_name..":"..reg_name] = {}
			flowers_nt.registered_flowers[m_name..":"..reg_name] = {						
								reg_name  = reg_name,
								desc_name = desc_name,
								grow_on   = grow_on,
								light_min = light_min,
								light_max = light_max,
								l_min_death = l_min_death,
								l_max_death = l_max_death,
								time_min  = time_min,
								time_max  = time_max,
								color     = color,
								rot_place = rot_place,
								existing  = existing,
								is_water  = is_water}
			
			-- Add existing to global registered_flowers table as key
			if existing ~= nil then
				flowers_nt.registered_flowers[existing] = {}
				flowers_nt.registered_flowers[existing] = {						
									parent = m_name..":"..reg_name}
			end
			
			-------------------
			--  Flower Seed  --
			-------------------
			local stage_5 = {
				description = S(desc_name..stage_5_name),
				tiles = {m_name.."_"..reg_name..gt.."_5.png"},
				inventory_image = m_name.."_"..reg_name..gt.."_5.png",
				wield_image = m_name.."_"..reg_name..gt.."_5.png",
				drawtype = "signlike",
				paramtype = "light",
				sunlight_propagates = true,
				walkable = false,
				pointable = true,
				diggable = true,
				buildable_to = true,
				is_ground_content = true,
				liquids_pointable = is_water,
				selection_box = {
					type = "fixed",
					fixed = {-0.4,-0.5,-0.4, 0.4, -0.25, 0.4}
				},
				groups = {dig_immediate = 3, seed = 1, flower = 1},
				
				on_place = function(itemstack, placer, pointed_thing)
							local node_below    = minetest.get_node(pointed_thing.under)
							local node_name   = node_below.name						
							local fl_reg_name = flowers_nt.get_name(itemstack:get_name())
							local rot_place   = flowers_nt.registered_flowers[fl_reg_name].rot_place
							local node_p2     = "N"
							local is_water    = flowers_nt.registered_flowers[fl_reg_name].is_water
							local a_pos       = pointed_thing.above
							local u_pos       = pointed_thing.under
							
							if rot_place then
								node_p2 = math.random(0,3)
							end
							
							-- Liquid nodes need special handling for seeds
							if is_water then													
								local grow_on    = flowers_nt.registered_flowers[fl_reg_name].grow_on
								local can_grow   = false
								
								for k,node_name in pairs(grow_on) do
									if node_name == node_below.name then
										can_grow = true
										break
									end
								end	
								
								if can_grow then
									flowers_nt.seed_place_effect(a_pos, fl_reg_name)								
									minetest.set_node(a_pos, {name = fl_reg_name.."_0",param2 = node_p2})
									minetest.get_node_timer(a_pos):start(math.random(time_min, time_max))
									
									if not minetest.is_creative_enabled(placer:get_player_name()) then
										itemstack:take_item()
									end
								end

							else
								-- disallow placement on non-growing nodes, I played around with allowing
								-- placement and then popping seed off as dropped item and disallowing 
								-- placement this seems a better way to go.
								local node_a_name = minetest.get_node(a_pos).name
								if node_a_name == "air" and flowers_nt.allowed_to_grow(u_pos,fl_reg_name) then
									minetest.item_place_node(itemstack, placer, pointed_thing)
								end
							end	
							return itemstack
						end,
				
				after_place_node = function(pos, placer, itemstack)
										--minetest.get_node_timer(pos):start(math.random(1, time_min/2))
								   end,
				
				on_timer = flowers_nt.grow_flower_tmr
			}
			
			-- for extra groups 
			if e_groups then
				for grp_name,level in pairs(e_groups) do
					stage_5.groups[grp_name] = level
				end
			end
			
			-- light source (even the seeds/spores glow faintly)
			if light_src then
				local light = math.floor(tonumber(light_src/2))
				
				if light_src > 0 and light_src <= 15 then
					stage_5.light_source = tonumber(light_src) 
				end
			end
			
			minetest.register_node(m_name..":"..reg_name.."_5", stage_5)
			
			---------------------------------
			--  Flower Dormant  Stage Zero --
			---------------------------------
			local stage_0 = {
				description = S(desc_name.." Dormant"),
				drawtype = "airlike",
				paramtype = "light",
				sunlight_propagates = true,
				walkable = false,
				pointable = false,
				diggable = false,
				buildable_to = true,
				drop = "",
				groups = {not_in_creative_inventory = 1, flower = 1},
				on_timer = flowers_nt.grow_flower_tmr
			}
			-- For rot_place 
			if rot_place then
				stage_0.paramtype2 = "facedir"
			end
			
			minetest.register_node(m_name..":"..reg_name.."_0", stage_0)	
			
			-----------------------------
			-- Flower Growth Stage One --
			-----------------------------
			local stage_1 = {
				description = S(desc_name..stage_1_name),
				drawtype = drawtype,
				waving = 1,
				tiles = {m_name.."_"..reg_name..gt.."_1.png"},
				inventory_image = inv_img_n..gt.."_1.png",
				wield_image = inv_img_n..gt.."_1.png",
				paramtype = "light",
				sunlight_propagates = true,
				walkable = false,
				is_ground_content = true,
				buildable_to = true,
				liquids_pointable = is_water,
				sounds = sounds,
				selection_box = {
					type = "fixed",
					fixed = sel_box
				},
				groups = {dig_immediate = 2, flower = 1},

				after_place_node = function(pos, placer, itemstack)
									flowers_nt.no_grow(pos)
								   end,
								   
				after_dig_node = function(pos, oldnode, oldmetadata, digger)				
									flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)							
								  end,
				
				on_timer = flowers_nt.grow_flower_tmr
			}
							
			--for water lily/surface water plants
				if is_water then
					stage_1.waving = 3
					stage_1.on_place = flowers_nt.on_place_water
				end
			-- for mesh node_below
				if drawtype == "mesh" then			
					stage_1.mesh = mesh
					stage_1.use_texture_alpha = "clip"
				end
			-- For rot_place 
				if rot_place then
					stage_1.paramtype2 = "facedir"
				end
				
			-- for extra groups 
			if e_groups then
				for grp_name,level in pairs(e_groups) do
					stage_1.groups[grp_name] = level
				end
			end
			
			-- light source
			if light_src then
				local light = math.floor(tonumber(light_src/2))
				
				if light_src > 0 and light_src <= 15 then
					stage_1.light_source = tonumber(light_src) 
				end
			end
				
				minetest.register_node(m_name..":"..reg_name.."_1", stage_1)	
				
			-------------------------------	
			--  Flower Growth Stage Two  --
			-------------------------------
			 local stage_2 ={
				description = S(desc_name..stage_2_name),
				drawtype = drawtype,
				waving = 1,
				tiles = {m_name.."_"..reg_name..gt.."_2.png"},
				inventory_image = inv_img_n..gt.."_2.png",
				wield_image = inv_img_n..gt.."_2.png",
				paramtype = "light",
				sunlight_propagates = true,
				walkable = walkable,
				is_ground_content = true,
				buildable_to = true,
				liquids_pointable = is_water,
				sounds = sounds,
				selection_box = {
					type = "fixed",
					fixed = sel_box
				},
				groups = {dig_immediate = 2, flower = 1},

				after_place_node = function(pos, placer, itemstack)
									flowers_nt.no_grow(pos)
								   end,

				after_dig_node = function(pos, oldnode, oldmetadata, digger)				
									flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
								  end,
				
				on_timer = flowers_nt.grow_flower_tmr
			}

				--for water lily/surface water plants
				if is_water then
					stage_2.waving = 3
					stage_2.on_place = flowers_nt.on_place_water
				end
				-- for mesh node_below
				if drawtype == "mesh" then
					stage_2.mesh = mesh
					stage_2.use_texture_alpha = "clip"
					stage_2.collision_box ={type = "fixed", fixed = sel_box}
				end
				-- For rot_place 
				if rot_place then
					stage_2.paramtype2 = "facedir"
				end
				
				-- on_punch 
				if on_punch_2 ~= nil then
					stage_2.on_punch = on_punch_2			
				end
				
				-- for extra groups 
				if e_groups then
					for grp_name,level in pairs(e_groups) do
						stage_2.groups[grp_name] = level
					end
				end
				
			-- light source
			if light_src then
				if light_src > 0 and light_src <= 15 then
					stage_2.light_source = light_src 
				end
			end
				
				minetest.register_node(m_name..":"..reg_name.."_2", stage_2)	
				
			---------------------------------
			--  Flower Growth Stage Three  --
			---------------------------------
				-- allows for insertion of exisiting flower at stage 3
				-- primarily to support MTG-Flowers
			local stage_3
			if existing ~= nil then
				s3_name = existing
				stage_3 = {	
					description = S(desc_name..stage_3_name),
					drawtype = drawtype,
					waving = 1,
					tiles = {m_name.."_"..reg_name..gt.."_3.png"},
					inventory_image = inv_img_n..gt.."_3.png",
					wield_image = inv_img_n..gt.."_3.png",
					paramtype = "light",
					sunlight_propagates = true,
					walkable = walkable,
					is_ground_content = true,
					buildable_to = true,
					liquids_pointable = is_water,
					sounds = sounds,
					selection_box = {
						type = "fixed",
						fixed = sel_box
					},
					groups = {dig_immediate = 2, flower = 1},
					
					after_place_node = function(pos, placer, itemstack)
										flowers_nt.no_grow(pos)
									   end,
					
					after_dig_node = function(pos, oldnode, oldmetadata, digger)				
										flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
									  end,
					
					on_timer = flowers_nt.grow_flower_tmr			
				}
				
			 --for water lily/surface water plants
				if is_water then
					stage_3.waving = 3
					stage_3.on_place = flowers_nt.on_place_water
				end
			-- for mesh node_below
				if drawtype == "mesh" then
					stage_3.mesh = mesh
					stage_3.use_texture_alpha = "clip"
					stage_3.collision_box ={type = "fixed", fixed = sel_box}
				end	
				
			-- add color group
				if color ~= "nil" then -- it's a string not true nil
					stage_3.groups["color_"..color] = 1
				end
			
			-- For rot_place 
				if rot_place then
					stage_3.paramtype2 = "facedir"
				end
				
			-- on_use
				if on_use ~= nil then
					stage_3.on_use = on_use			
				end
				
			-- on_punch 
				if on_punch_3 ~= nil then
					stage_3.on_punch = on_punch_3			
				end

			-- for extra groups 
			if e_groups then
				for grp_name,level in pairs(e_groups) do
					stage_3.groups[grp_name] = level
				end
			end
			
			-- light source
			if light_src then
				if light_src > 0 and light_src <= 15 then
					stage_3.light_source = light_src 
				end
			end			
			
				minetest.register_node(":"..existing,stage_3)
								
			else
				stage_3 = {	
					description = S(desc_name..stage_3_name),
					drawtype = drawtype,
					waving = 1,
					tiles = {m_name.."_"..reg_name..gt.."_3.png"},
					inventory_image = inv_img_n..gt.."_3.png",
					wield_image = inv_img_n..gt.."_3.png",
					paramtype = "light",
					sunlight_propagates = true,
					walkable = walkable,
					is_ground_content = true,
					buildable_to = true,
					liquids_pointable = is_water,
					sounds = sounds,
					selection_box = {
						type = "fixed",
						fixed = sel_box
					},
					
					groups = {dig_immediate = 2, flower = 1},

					after_place_node = function(pos, placer, itemstack)
										flowers_nt.no_grow(pos)
									   end,

					after_dig_node = function(pos, oldnode, oldmetadata, digger)				
										flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
									  end,
					
					on_timer = flowers_nt.grow_flower_tmr
				}
				
			--for water lily/surface water plants
				if is_water then
					stage_3.waving = 3
					stage_3.on_place = flowers_nt.on_place_water
				end 
			-- for mesh node_below
				if drawtype == "mesh" then
					stage_3.mesh = mesh
					stage_3.use_texture_alpha = "clip"
					stage_3.collision_box ={type = "fixed", fixed = sel_box}
				end	
				
			-- add color group
				if color ~= "nil" then -- it's a string not true nil
					stage_3.groups["color_"..color] = 1
				end
			
			-- For rot_place 
				if rot_place then
					stage_3.paramtype2 = "facedir"
				end
							
			-- on_use
				if on_use ~= nil then
					stage_3.on_use = on_use			
				end	
			
			-- on_punch 
				if on_punch_3 ~= nil then
					stage_3.on_punch = on_punch_3			
				end
				
			-- for extra groups 
				if e_groups then
					for grp_name,level in pairs(e_groups) do
						stage_3.groups[grp_name] = level
					end
				end	

			-- light source
			if light_src then
				if light_src > 0 and light_src <= 15 then
					stage_3.light_source = light_src 
				end
			end
			
				minetest.register_node(m_name..":"..reg_name.."_3",stage_3)	
				
			end

			--------------------------------
			--  Flower Growth Stage Four  --
			--------------------------------	
			local stage_4 = {
				description = S(desc_name..stage_4_name),
				drawtype = drawtype,
				waving = 1,
				tiles = {m_name.."_"..reg_name..gt.."_4.png"},
				inventory_image = inv_img_n..gt.."_4.png",
				wield_image = inv_img_n..gt.."_4.png",
				paramtype = "light",
				sunlight_propagates = true,
				walkable = walkable,
				is_ground_content = true,
				buildable_to = true,
				liquids_pointable = is_water,
				sounds = sounds,
				selection_box = {
					type = "fixed",
					fixed = sel_box
				},
				groups = {dig_immediate = 3, flower = 1},
				drop = m_name..":"..reg_name.."_5",
				
				after_place_node = function(pos, placer, itemstack)
									flowers_nt.no_grow(pos)
								   end,

				after_dig_node = function(pos, oldnode, oldmetadata, digger)			
									if flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata) then
										flowers_nt.seed_spread(pos, oldnode, digger)
									end							
								  end,
				
				on_timer = flowers_nt.grow_flower_tmr
			}

			--for water lily/surface water plants
				if is_water then
					stage_4.waving = 3
					stage_4.on_place = flowers_nt.on_place_water
				end 
			-- for mesh node_below
				if drawtype == "mesh" then
					stage_4.mesh = mesh
					stage_4.use_texture_alpha = "clip"
					stage_4.collision_box ={type = "fixed", fixed = sel_box}
				end	
			
			-- For rot_place 
				if rot_place then
					stage_4.paramtype2 = "facedir"
				end
			
			-- on_punch 
				if on_punch_4 ~= nil then
					stage_4.on_punch = on_punch_4			
				end
			
			-- for extra groups 
			if e_groups then
				for grp_name,level in pairs(e_groups) do
					stage_4.groups[grp_name] = level
				end
			end

			-- light source
			if light_src then
				local light = math.floor(tonumber(light_src/2))
				
				if light_src > 0 and light_src <= 15 then
					stage_1.light_source = tonumber(light_src) 
				end
			end
				
			minetest.register_node(m_name..":"..reg_name.."_4",stage_4)	
				
			--------------------------------
			--  Flower LBM, trigger timer  --
			--------------------------------	
			-- LBM is needed to start the timers on inital mapgen
			minetest.register_lbm({
			  name = m_name..":"..reg_name,
			  run_at_every_load = true, 
			  nodenames = {m_name..":"..reg_name.."_0", 
						   m_name..":"..reg_name.."_1", 
						   m_name..":"..reg_name.."_2",
						   s3_name,
						   m_name..":"..reg_name.."_4",
						   m_name..":"..reg_name.."_5"	-- seed			   
						   },
			  action = function(pos, node)
					local meta = minetest.get_meta(pos)
					local flowers_nt = meta:get_int("flowers_nt")
					if flowers_nt == 0 then
						local timer = minetest.get_node_timer(pos)
							if not timer:is_started() then
								local flower_stage = tonumber(string.sub(node.name, -1))				
								
								-- catch existing node stage 3
								if flower_stage == nil then
									flower_stage = 3
								end
								
								if flower_stage == 3 or flower_stage == 4 then
									timer:start(math.random(2*(time_min), 2*(time_max)))
								else
									timer:start(math.random(time_min, time_max))
								end
							end
						end
					end,
			})
		
			----------------------------------
			--  Flower Register Decoration  --
			----------------------------------
			
			if existing ~= nil then
				
				local function has_value (tab, val)
					for index, value in pairs(tab) do
						if value == val then
							return value
						end
					end
					return false
				end

				local add_to = {existing}
				local reg_dec_cpy = table.copy(minetest.registered_decorations)

				for k,v in pairs(reg_dec_cpy) do
					local def_reg = nil
					local def_name = nil
					if type(v.decoration)== "table" then 
						for k2,v2 in pairs(v.decoration) do
						
							if has_value(add_to,v2) then 
								table.insert(v.decoration,m_name..":"..reg_name.."_1")
								table.insert(v.decoration,m_name..":"..reg_name.."_2")
								table.insert(v.decoration,m_name..":"..reg_name.."_4")
							
								def_reg = v
								def_name = k
							end						
						end
					
					elseif type(v.decoration) == "string" then

						if has_value(add_to,v.decoration) then 

							v.decoration = {m_name..":"..reg_name.."_1",
											m_name..":"..reg_name.."_2",
											v.decoration,
											m_name..":"..reg_name.."_4"}	
							def_reg = v
							def_name = k
											
						end			
					end
					
					if def_reg ~= nil then
						minetest.registered_decorations[def_name] = def_reg
						
					end			
				end	
							
			else		
					local dec_def = {
						name = m_name..":"..reg_name,
						deco_type = "simple",
						place_on = place_on,
						sidelen = 16,
						noise_params = {
							offset = offset,
							scale = scale,
							spread = {x = 200, y = 200, z = 200},
							seed = seed,
							octaves = 3,
							persist = 0.6 },
						biomes = biomes,
						y_max = y_max,
						y_min = y_min,
						place_offset_y = y_offset,
						decoration = {m_name..":"..reg_name.."_1", 
									  m_name..":"..reg_name.."_2", 
									  s3_name,
									  m_name..":"..reg_name.."_4"}
					}
			
				--for water lily/surface water plants
				if is_water and y_offset == 0 then
					dec_def.place_offset_y  = 1
				end

				--for random rotation on placement
				if rot_place then
					dec_def.param2 = 0
					dec_def.param2_max = 3				
				end
			
				minetest.register_decoration(dec_def)
			end
		else
	--------------
	-- Rollback --
	--------------	
		-- Rollback wave settings
			minetest.settings:set('water_wave_speed', 5.0)
			minetest.settings:set('water_wave_height', 1.0)

		-- Rollback LBMs

			if existing ~= nil then
				minetest.register_lbm({
				  name = m_name..":"..reg_name,
				  run_at_every_load = true,     -- letting this run everytime in case someone places something out of storage
				  nodenames = {m_name..":"..reg_name.."_0", 
							   m_name..":"..reg_name.."_1", 
							   m_name..":"..reg_name.."_2",
							   m_name..":"..reg_name.."_4",
							   m_name..":"..reg_name.."_5"					   
							   },
				  action = function(pos, node)
								minetest.set_node(pos, {name= existing})
						   end})
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_0"] = existing
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_1"] = existing
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_2"] = existing
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_4"] = existing
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_5"] = existing
			
			else
				minetest.register_lbm({
				  name = m_name..":"..reg_name,
				  run_at_every_load = true, 
				  nodenames = {m_name..":"..reg_name.."_0", 
							   m_name..":"..reg_name.."_1", 
							   m_name..":"..reg_name.."_2",
							   m_name..":"..reg_name.."_2",					   
							   m_name..":"..reg_name.."_4",
							   m_name..":"..reg_name.."_5"					   
							   },
				  action = function(pos, node)
								minetest.set_node(pos, {name= "air"})
						   end	})	

				flowers_nt.rollback_replace[m_name..":"..reg_name.."_0"] = "air"
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_1"] = "air"
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_2"] = "air"
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_3"] = "air"		
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_4"] = "air"
				flowers_nt.rollback_replace[m_name..":"..reg_name.."_5"] = "air"
					
			end
			
		-- Remove/Replace items from "main" player inventory on rollback.
			minetest.register_on_joinplayer(function(player)
				local roll_replace = flowers_nt.rollback_replace
				local inv = player:get_inventory()
				
				for i_tar,i_rep in pairs(roll_replace) do		
					if inv:contains_item("main", i_tar) then
						local main_inv = inv:get_list("main")
						
						for i,itemstack in pairs(main_inv) do
							if itemstack:get_name() == i_tar then
								inv:remove_item("main", ItemStack(itemstack:get_name().." "..itemstack:get_count()))
								
								if i_rep ~= "air" then
									inv:set_stack("main", i, ItemStack(i_rep.." "..itemstack:get_count()))
								end
								
								minetest.chat_send_player(player:get_player_name(),"Flowers_NT Rollback: "..itemstack:get_name().." replaced with "..i_rep.." x"..itemstack:get_count())				
							end
						end						
					end	
				end
			end)		
		end -- Rollback End
	end -- Valid data end
end -- Function End