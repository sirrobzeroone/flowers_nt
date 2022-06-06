--[[The MIT License (MIT)

Copyright (c) 2016 TenPlus1

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.]]

local min, max, random = math.min, math.max, math.random

-- default crops
local crops = {
	{"farming:cotton_", 8, "farming:seed_cotton"},
	{"farming:wheat_", 8, "farming:seed_wheat"}
}


-- special pine check for nearby snow
local function pine_grow(pos)

	if minetest.find_node_near(pos, 1,
		{"default:snow", "default:snowblock", "default:dirt_with_snow"}) then

		default.grow_new_snowy_pine_tree(pos)
	else
		default.grow_new_pine_tree(pos)
	end
end


-- special function for cactus growth
local function cactus_grow(pos)
	default.grow_cactus(pos, minetest.get_node(pos))
end

-- special function for papyrus growth
local function papyrus_grow(pos)
	default.grow_papyrus(pos, minetest.get_node(pos))
end


-- default saplings
local saplings = {
	{"default:sapling", default.grow_new_apple_tree, "soil"},
	{"default:junglesapling", default.grow_new_jungle_tree, "soil"},
	{"default:emergent_jungle_sapling", default.grow_new_emergent_jungle_tree, "soil"},
	{"default:acacia_sapling", default.grow_new_acacia_tree, "soil"},
	{"default:aspen_sapling", default.grow_new_aspen_tree, "soil"},
	{"default:pine_sapling", pine_grow, "soil"},
	{"default:bush_sapling", default.grow_bush, "soil"},
	{"default:acacia_bush_sapling", default.grow_acacia_bush, "soil"},
	{"default:large_cactus_seedling", default.grow_large_cactus, "sand"},
	{"default:blueberry_bush_sapling", default.grow_blueberry_bush, "soil"},
	{"default:pine_bush_sapling", default.grow_pine_bush, "soil"},
	{"default:cactus", cactus_grow, "sand"},
	{"default:papyrus", papyrus_grow, "soil"}
}

-- helper tables ( "" denotes a blank item )
local green_grass = {
	"default:grass_2", "default:grass_3", "default:grass_4",
	"default:grass_5", "", ""
}

local dry_grass = {
	"default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4",
	"default:dry_grass_5", "", ""
}

-- loads mods then add all in-game flowers except waterlily
local flowers = {}

minetest.after(0.1, function()

	for node, def in pairs(minetest.registered_nodes) do

		if def.groups
		and def.groups.flower
		and not node:find("waterlily")
		and not node:find("xdecor:potted_") then
			flowers[#flowers + 1] = node
		end
	end
end)


-- default biomes deco
local deco = {
	{"default:dry_dirt", dry_grass, {}},
	{"default:dry_dirt_with_dry_grass", dry_grass, {}},
	{"default:dirt_with_dry_grass", dry_grass, flowers},
	{"default:sand", {}, {"default:dry_shrub", "", "", ""} },
	{"default:desert_sand", {}, {"default:dry_shrub", "", "", ""} },
	{"default:silver_sand", {}, {"default:dry_shrub", "", "", ""} },
	{"default:dirt_with_rainforest_litter", {}, {"default:junglegrass", "", "", ""}}
}

--
-- local functions
--
-- particles
local function particle_effect(pos)

	minetest.add_particlespawner({
		amount = 4,
		time = 0.15,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -1, y = 2, z = -1},
		maxvel = {x = 1, y = 4, z = 1},
		minacc = {x = -1, y = -1, z = -1},
		maxacc = {x = 1, y = 1, z = 1},
		minexptime = 1,
		maxexptime = 1,
		minsize = 1,
		maxsize = 3,
		texture = "bonemeal_particle.png"
	})
end


-- tree type check
local function grow_tree(pos, object)

	if type(object) == "table" and object.axiom then
		-- grow L-system tree
		minetest.remove_node(pos)
		minetest.spawn_tree(pos, object)

	elseif type(object) == "string" and minetest.registered_nodes[object] then
		-- place node
		minetest.set_node(pos, {name = object})

	elseif type(object) == "function" then
		-- function
		object(pos)
	end
end


-- sapling check
local function check_sapling(pos, nodename)

	-- what is sapling placed on?
	local under =  minetest.get_node({
		x = pos.x,
		y = pos.y - 1,
		z = pos.z
	})

	local can_grow, grow_on

	-- check list for sapling and function
	for n = 1, #saplings do

		if saplings[n][1] == nodename then

			grow_on = saplings[n][3]

			-- sapling grows on top of specific node
			if grow_on
			and grow_on ~= "soil"
			and grow_on ~= "sand"
			and grow_on == under.name then
				can_grow = true
			end

			-- sapling grows on top of soil (default)
			if can_grow == nil
			and (grow_on == nil or grow_on == "soil")
			and minetest.get_item_group(under.name, "soil") > 0 then
				can_grow = true
			end

			-- sapling grows on top of sand
			if can_grow == nil
			and grow_on == "sand"
			and minetest.get_item_group(under.name, "sand") > 0 then
				can_grow = true
			end

			-- check if we can grow sapling
			if can_grow then
				particle_effect(pos)
				grow_tree(pos, saplings[n][2])
				return true
			end
		end
	end
end


-- crops check
local function check_crops(pos, nodename, strength)

	local mod, crop, stage, nod, def

	-- grow registered crops
	for n = 1, #crops do

		if nodename:find(crops[n][1])
		or nodename == crops[n][3] then

			-- separate mod and node name
			mod = nodename:split(":")[1] .. ":"
			crop = nodename:split(":")[2]

			-- get stage number or set to 0 for seed
			stage = tonumber( crop:split("_")[2] ) or 0
			stage = min(stage + strength, crops[n][2])

			-- check for place_param setting
			nod = crops[n][1] .. stage
			def = minetest.registered_nodes[nod]
			def = def and def.place_param2 or 0

			minetest.set_node(pos, {name = nod, param2 = def})

			particle_effect(pos)

			return true
		end
	end
end


-- check soil for specific decoration placement
local function check_soil(pos, nodename, strength)

	-- set radius according to strength
	local side = strength - 1
	local tall = max(strength - 2, 0)
	local floor
	local groups = minetest.registered_items[nodename]
		and minetest.registered_items[nodename].groups or {}

	-- only place decoration on one type of surface
	if groups.soil then
		floor = {"group:soil"}
	elseif groups.sand then
		floor = {"group:sand"}
	else
		floor = {nodename}
	end

	-- get area of land with free space above
	local dirt = minetest.find_nodes_in_area_under_air(
		{x = pos.x - side, y = pos.y - tall, z = pos.z - side},
		{x = pos.x + side, y = pos.y + tall, z = pos.z + side}, floor)

	-- set default grass and decoration
	local grass = green_grass
	local decor = flowers

	-- choose grass and decoration to use on dirt patch
	for n = 1, #deco do

		-- do we have a grass match?
		if nodename == deco[n][1] then
			grass = deco[n][2] or {}
			decor = deco[n][3] or {}
		end
	end

	local pos2, nod, def

	-- loop through soil
	for _, n in pairs(dirt) do

		if random(5) == 5 and 1 == 2 then   -- flowers_nt add 1==2 stop flowers from being placed
			if decor and #decor > 0 then
				-- place random decoration (rare)
				local dnum = #decor or 1
				nod = decor[random(dnum)] or ""
			end
		else
			if grass and #grass > 0 then
				-- place random grass (common)
				local dgra = #grass or 1
				nod = #grass > 0 and grass[random(dgra)] or ""
			end
		end

		pos2 = n

		pos2.y = pos2.y + 1

		if nod and nod ~= "" then

			-- get crop param2 value
			def = minetest.registered_nodes[nod]
			def = def and def.place_param2

			-- if param2 not preset then get from existing node
			if not def then
				local node = minetest.get_node_or_nil(pos2)
				def = node and node.param2 or 0
			end

			minetest.set_node(pos2, {name = nod, param2 = def})
		end

		particle_effect(pos2)
	end
end

-- global on_use function for bonemeal
function bonemeal:on_use(pos, strength, node)

	-- get node pointed at
	local node = node or minetest.get_node(pos)

	-- return if nothing there
	if node.name == "ignore" then
		return
	end

	-- make sure strength is between 1 and 4
	strength = strength or 1
	strength = max(strength, 1)
	strength = min(strength, 4)

	-- papyrus and cactus
	if node.name == "default:papyrus" then

		default.grow_papyrus(pos, node)
		particle_effect(pos)
		return true

	elseif node.name == "default:cactus" then

		default.grow_cactus(pos, node)
		particle_effect(pos)
		return true
	
	end
	
	-------------------------
	-- flowers_nt addition --
	-------------------------
	local flowers_nt_node = false
	local fnt_reg_name 
	
	for reg_name, def in pairs(flowers_nt.registered_flowers) do
		local sub_name = string.sub(node.name, 0, -3)

		if reg_name == sub_name then
			flowers_nt_node = true
			fnt_reg_name = sub_name
			break
		
		elseif reg_name  == node.name then
			flowers_nt_node = true
			fnt_reg_name = def.parent
			break		
		end	
	end
	
	if flowers_nt_node == true then
		local light_min = flowers_nt.registered_flowers[fnt_reg_name].light_min

		-- light check depending on strength, sub in flower light_min
		if (minetest.get_node_light(pos) or 0) < (light_min - (strength * 3)) then
			return
		end
		
		flowers_nt.set_grow_stage(pos)
		particle_effect(pos)	
		return true
	end
	-----------------------------		
	-- end flowers_nt addition --
	-----------------------------
	
	-- grow grass and flowers
	if minetest.get_item_group(node.name, "soil") > 0
	or minetest.get_item_group(node.name, "sand") > 0
	or minetest.get_item_group(node.name, "can_bonemeal") > 0 then
		check_soil(pos, node.name, strength)
		return true
	end

	-- light check depending on strength (strength of 4 = no light needed)
	if (minetest.get_node_light(pos) or 0) < (12 - (strength * 3)) then
		return
	end

	-- check for tree growth if pointing at sapling
	if (minetest.get_item_group(node.name, "sapling") > 0
	or node.name == "default:large_cactus_seedling")
	and random(5 - strength) == 1 then
		check_sapling(pos, node.name)
		return true
	end

	-- check for crop growth
	if check_crops(pos, node.name, strength) then
		return true
	end
end