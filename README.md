# Flowers Node Timer
Flowers NT adds a framework to add growing flowers to your game using node timers. 

Compatible with Minetest Engine version 5.2+  
Compatible with all Mapgens except MGv6 - Sorry  
All content - CC0 1.0 Universal - except were noted - See Licence.txt

I trawled the forums, modding book, github discussion threads and other peoples code to get ideas to create this mod - Thank you to everyone a few in particular:  
Shara, Paramat, Sokomine, ShadMOrdre, Rubenwardy, Krock, Termos, Linuxdirk, Skamiz Kazzarch, VanessaE 

## Table of contents
 1. [Overview](#overview)
 2. [API](#api)
	 1. [Usage](#usage)
	 2. [Localisation/Translations](#localisation/translations)
	 3. [Image Names](#image-names)
	 4. [Mod Settings](#mod-settings)	
	 5. [Rollback](#rollback)	 
 3. [Simple Flower Example](#simple-flower-example)
 4. [Complex Flower Example](#complex-flower-example)
 5. [Manually Configure Nodes](#manually-configure-nodes)
	 1. [Flowers_NT Global Table](#flowers_nt-global-table)
	 2. [Flowers_NT Functions](#flowers_nt-function)
	 3. [Registration example](#registration-example)
 6. [Game and Mod notes](#game-and-mod-notes)
 	 1. [Minetest Game](#minetest-game)
 	 2. [Voxel Garden](#voxel-garden)
 	 3. [Bonemeal Mod](#bonemeal-mod)

## Overview
Flowers NT uses node timers to provide a simple way to grow and cultivate flowers, mushrooms and any other small herb like plants. These can be grown on normal blocks as configured for that flower. This mod can be used as a supplement to farming mods but is not intended as a replacement. Flowers NT provides a configurable API to register growing flowers or small herb type plants for your game (land based or floating only). Supports MTG and Voxelgarden with no configuration needed - Compatible with flowers, dyes and bonemeal.

Unlike most farming mods Flowers NT only has 5 growth stages with 4 being visible to the player. As flowers need to grow perpetually in the wild the cycle doesn't end at the seed/waiting to be harvested stage but loops back around to the beginning stage so that at anytime in the wild there's always growing flowers at different stages.

    0. Dormant  (Stage Zero)
    1. Seedling (Stage One)
    2. Budding (Stage Two)
    3. Flowering (Stage Three)
    4. Seed Head (Stage Four)
    0. Dormant  (Stage Zero)

    5. Seeds (Stage Five) - but only used to plant a new flower
 
At the beginning of the game/map block load all flowers will start at Stage 3. Primarily chosen as this enables easier integration with the base Flowers mod. To add randomness over time each stages timer is randomized for each flower for each growth cycle so over time the flowers will be present at different stages. 
 
All flower stages can be picked and used as decorations (except stage 4 - see below), however once a flower stage is picked and stuck into the ground it will not grow or decay. So those stages can be used as decoration around your builds. The node you picked the flower from will restart to grow at Dormant (Stage 0) and eventually a new Flower will grow. Flowers require light and the correct medium below them to grow both of which can be configured. For example MTG/Voxelgarden which both use the flowers mod require a light level above 12 and Dirt/Dirt with Grass below them to grow - except Water Lilies and Mushrooms who are a special cases.
 
To gather seeds you need to wait until the flower produces a seed head (Stage Four). In the case of MTG/Voxelgarden Flowers NT game examples I made these stages very obvious. When you pick the flower seed head instead of receiving the seed head you will gather 1 item of that flowers seed. To plant the seed simply place it onto any valid ground node for that flower type. Floating water plants work slightly differently as you are sprinkling the seeds into the water and as such they don't visually place.

Flowers won't self-spread without player interaction. Other than directly planting seeds there is a 50% chance when you pick a flower seed head that an additional seed node will be placed nearby. There is also a density cap of 3 flowers around the picked flower (3x3 grid with our picked flower in the middle). I borrowed the spreading idea from something Paramat wrote so full credit to him. 

Testing with mesh nodes on waving water for floating plants, showed some intresting visual artifacts in the mesh node (stretching and compression vertically). It's not surprising but it visual unpleasant. If you have waving water turned on Flowers_NT will basically halve the water_wave_speed (normally 5) and water_wave_height (normally 1). However if you already have these both set below this threshold no change will be made. 
 
 As most people will be using Flowers_NT with MTG/Voxelgarden it will: 
 - Flowers ABM will no longer see flowers registered by flowers_nt as they dont contain the group "flora" however the ABM still runs as it's used by grass. Mushroom ABM is deleted.  
 - Overwrite the existing registered flowers node but retain the name's and use these as Flowering (Stage Three)
 - Compatible with the generic mod dyes that comes with MTG - unsure on other dye/coloring mods, Flowers_NT maintains the group color settings eg "color_yellow = 1" so any dye mod that looks for or uses those values should work.  
 - Stage 0, Stage 1 and Stage 2 will take between 1-3 mins to move through each stage, to allow picking opportunities Stage 3 and Stage 4 will remain for between 2-6 mins. So the shortest growth cycle is 7 mins and the longest 21 mins - at worst basically half a tree's minimum growth time. However if this is to long it can easily be adjusted in the i_mtg_game.lua file. All flowers have the same growth time but you could for example make Dandelions shorter and Water lilies longer.
 - Distribution/density of flowers has been as closely matched to flowers mod as I could, biggest difference being Water Lily's followed by mushrooms. 
 - There is a rollback script for Flowers_NT which will replace all Flower_NT versions either with configured existing node or Air if there was no exisiting. The Rollback also attempts to check player inventories on logon and do a similar replace for their inventories and resets the water settings. See Rollback section below - use with caution I can't gaurentee rollback will work 100% so players may still end up with unknown items or the odd unknown node. At this time I have no idea how to perform this check on storage nodes without adding code to every storage node ie chests. So don't go rolling this mod onto your game server without doing your own testing :).
 
## API

### Usage
#### Use flowers_nt.register_flower(definition) to register a flower

#### All fields accepted in flowers_nt definitions
Many of the below definitions are used in the node registration definition and the decoration registration definition. For reference/more detailed information around a specific field you can read about them in the Minetest API.  
Minetest API Node Overview: https://minetest.gitlab.io/minetest/nodes/  
Minetest API Node Definition: https://minetest.gitlab.io/minetest/definition-tables/#node-definition  
Minetest API Decoration Overview: https://minetest.gitlab.io/minetest/decoration-types/  
Minetest API Decoration Definition:  https://minetest.gitlab.io/minetest/definition-tables/#decoration-definition

**name** =  "Flower name" used to create registered node name and node description name. Formats accepted - "flower_name", "Flower_Name", "flower name" or "Flower Name".

Flowers_NT will format input as the below when registering Nodes:   
Registered node name = "modname:flower_name_0-5"

    Node description = S("Flower Name".." see below")  
    Stage 1 = " Seedling"  
    Stage 2 = " Budding"  
    Stage 3 = "" - no addition  
    Stage 4 = " Seed Head"   
    Stage 5 = " Seed"  

The above can be overriden per flower by including stage_1-5_name in flowers_nt.register_flower eg stage_5_name = " Spores" (leave a leading white space)  
*See Minetest API https://minetest.gitlab.io/minetest/nodes/*

**color** = Flowers_NT uses groups to assign the correct color for use by dyes and other mods. So enter a color or remove if you want no color. The basic MTG dyes mod supports these colors: 
-White, Grey, Dark Grey, Black, Violet, Blue, Cyan, Dark Green, Green, Yellow, Brown, Orange, Red, Magenta and Pink.  
*See Minetest API Node Definition - Groups*
		
**drawtype** = "plantlike", torchlike or "mesh" accepted only (sorry no node box)  
*For simplicity the same drawtype is used across Stages 1-4*   
*See Minetest API Node Definition - Drawtype*
		
**mesh** = "mesh_name.obj" - Not required for "plantlike"/"torchlike" - must be located under the mod/models folder.   
*For simplicity the same mesh is used across Stages 1-4*   
*See Minetest API Node Definition - Mesh*

**sounds** = Flowers_NT uses when registering the nodes. Same format should be used as when normally registering a nodes sounds.   
*This can be left blank but it's not recommended*   
*See Minetest API Node Definition - Sounds*
		
**grow_on** = Table of nodes the flower can grow on eg {"default:dirt", default:dirt_with_grass"}.  
*Used internally by flowers_nt and to register mapgen decoration - minetest.register_decoration(decoration definition).*

**sel_box** - Optional - Table of values used to register the nodes selection box, auto sets to {-0.3,-0.5,-0.3, 0.3, 0.25, 0.3}  
*Used by flowers_nt during node registration - minetest.register_node().*  
*See Minetest API Node Definition - selection_box > fixed*

**e_groups** - Optional - add extra groups to stages 1-5 simple table of groups eg {falling_node = 1, heavy = 1}. This can also be used to override existing groups however be aware that it will override for all stages.
Flowers recieve the below groups:
    
    Stage 0 = {not_in_creative_inventory = 1, flower = 1}
    Stage 1 = {dig_immediate = 2, flammable = 1, flower = 1}
    Stage 2 = {dig_immediate = 2, flammable = 1, flower = 1}    
    Stage 3 = {dig_immediate = 2, flammable = 1, flower = 1}
    Stage 4 = {dig_immediate = 3, flammable = 3, flower = 1}
    Stage 5 = {dig_immediate = 3, flammable = 2, seed = 1, flower = 1}

**time_min** - Optional - Flowers_NT auto sets to 60 - Minimum time for a flower to change stages

**time_max** - Optional - Flowers_NT auto sets to 180 - Maximum time for a flower to change stages

**is_water** = Optional - Either a Table of nodes that a floating plant can't grow on.         
*For biome registration for a floating plant eg Water Lilies you have to include a ground node, in the case of Water Lilies "default:dirt". However we don't want Lilies growing on dirt so place that as an exclusion(s) here as a lua table eg is_water = {default:dirt}.*      
      If you don't need an exclusion but it's still a floating water plant set to true eg is_water = true
		
**light_min** = Optional - Flowers_NT auto sets to 12. Used by Flowers_NT when checking if flower can grow. When light level is below this level flower no longer grows
		
**light_max** = Optional - Flowers_NT auto sets to 15. Used by Flowers_NT when checking if flower can grow. When light level is above this level flower no longer grows

**light_min_death** = Optional - true/false (Bool) - Flowers_NT auto sets to false. If true and the light level drops below the light_min value the flower/plant will die.

**light_max_death** = Optional - true/false (Bool) - Flowers_NT auto sets to false. If true and the light level goes above the light_max value the flower/plant will die.

**inv_img** = Optional - Flowers_NT auto sets to false - When true used to set custom inventory image and wield image - see image names below
*See Minetest API Node Definition*
			  
**biomes** = Table of Biome names flowers can be found growing in eg {"Grassland", "Deciduous forest"}
*Used by flowers_nt to register mapgen decoration*
*See Minetest API Decoration Definition - biomes* 

**biome_seed** = Number 
*Used by flowers_nt to register mapgen decoration*
*See Minetest API Decoration Definition - biomes*

**cover** = Number between 1-8 - 1 very rare - 8 very common; normal flowers mod coverage = 4
*Used by flowers_nt to register mapgen decoration specifically noise_params - offset and scale although these are hidden behind 8 numbered coverage levels:*

    1. About half of No 2 - very rare
    2. About half of No 3
    3. About half of No 4 - Approx flowers mod mushroom distribution
    4. Same as flowers mod default distribution (-0.02/0.04) 
    5. About 25% more than No 4
    6. About 25% more than No 5
    7. Almost found everywhere in biome - Used by Water Lilies
    8. Found everywhere in biome

*See Minetest API Decoration Definition - noise_params: scale and spread*
			   
**y_min** = Optional - Flowers_NT auto sets to 1. Lowest y level the flower will be placed.   
*Used by flowers_nt to register mapgen decoration*   
*See Minetest API Decoration Definition - y_min*
				
**y_max** = Optional - Flowers_NT auto sets to 31000. Highest y level the flower will be placed.    
*Used by flowers_nt to register mapgen decoration*	   
*See Minetest API Decoration Definition - y_max*
					
**y_offset** = Optional - Flowers_NT auto sets to 0 when is_water = false and sets to 1 when is_water = true. Sets how far above the ground the decoration is placed normally flowers want to be placed on the ground which is 0.   
*Used by flowers_nt to register mapgen decoration*	
*See Minetest API Decoration Definition - y_offset*

**rot_place** = Optional - Flowers_NT auto sets to false - When true Flowers_NT will register the flower decoration so it randomly rotates when placed on mapgen.   
*See Minetest API Decoration Definition - param2  and param2_max*

**existing** = Optional - Flowers_NT will override this nodes registered settings and use it as Flowering (Stage Three)
				
**on_use** = Optional - Flowers_NT leaves nil - Only applies to Flowering (Stage Three) - custom on_use code.   
*Used by flowers_nt during node registration*   
*See Minetest API Node Definition - on_use*

### Localisation/Translations
When *flowers_nt.register_flower(def)* is called it will automatically add a translation wrapper (S) around the flower description. The translation wrapper will be assigned in the calling mods namespace. Translations for flower names can/must be provided from the source mods locale files not from Flowers_NT. For example if I had a mod called "extra_flowers" and I registered a "Blue Tulip" the localisation/translation file for my mod would look like the below if I was translating to french (assuming Stage names are left unchanged):

		# textdomain:extra_flowers
		Blue Tulip Seed=Graine de tulipe bleue
		Blue Tulip Seedling=Semis de tulipe bleue
		Blue Tulip Budding=Tulipe bleue en herbe
		Blue Tulip=Tulipe bleue
		Blue Tulip Seed Head=Tête de graine de tulipe bleue
		
If you override stage names you will need to provide the translation for the overriden stage name for example if my "extra_flowers" mod also registered a "Blue Mushroom" and I'd overriden stage 5 so it was " Spores" instead of " Seeds" I would provide the below: 
		
		# textdomain:extra_flowers
		Blue Mushroom Spores=Spores de champignons bleus
		Blue Mushroom Seedling=Semis de champignon bleu
		Blue Mushroom Budding=Champignon bleu en herbe
		Blue Mushroom=Champignon bleu
		Blue Mushroom Seed Head=Tête de graine de champignon bleu		

*Apologises to native french speakers those translation examples are from google*
https://minetest.gitlab.io/minetest/translations/

### Image names
As Flowers_NT handles different games and styles there is a game_tail setting if you need it - flowers_nt.game_tail. I doubt this will be useful to anyone else but if you need it, it allows different textures for different games eg all the Voxel Garden textures are structured as "flowers_nt_orange_tulip_vg_1.png" and flowers_nt.game_tail = "_vg", However normal MTG has flowers_nt.game_tail = "" and the image names appear as the examples below. If your intrested in this feature have a look at init.lua voxelgarden section and the textures folder - however for most people this can be ignored.

#### Normal Node/Inv/Hand image names
    Stage One   = "mod_name_flower_name_1.png" eg "flowers_nt_orange_tulip_1.png" (Seedling)
    Stage Two   = "mod_name_flower_name_2.png" eg "flowers_nt_orange_tulip_2.png" (Flower Budding)
    Stage Three = "mod_name_flower_name_3.png" eg "flowers_nt_orange_tulip_3.png" (Flowering)
    Stage Four  = "mod_name_flower_name_4.png eg "flowers_nt_orange_tulip_4.png" (Seed Head)
    Stage Five  = "mod_name_flower_name_5".png eg "flowers_nt_orange_tulip_5.png" (Seeds Image)

#### Custom Inventory and Wield image names (inv_img = true):
    Stage One   = "mod_name_flower_name_inv_1".png eg "flowers_nt_orange_tulip_inv_1.png" (Seedling)
    Stage Two   = "mod_name_flower_name_inv_2".png eg "flowers_nt_orange_tulip_inv_2.png" (Flower Budding)
    Stage Three = "mod_name_flower_name_inv_3".png eg "flowers_nt_orange_tulip_inv_3.png" (Flowering)
    Stage Four  = "mod_name_flower_name_inv_4".png eg "flowers_nt_orange_tulip_inv_4.png" (Seed Head)

### Mod Settings
These are avaliable to be adjusted under Minestest settings >> all settings >> mods >> flowers_nt
	
- **Random Seed Spreading**
 - Random Seed Head Spread - The percentage chance of seed being placed when a player digs a flower at the the Seeding Stage.
 - Flower Density -  The maximum number of a single flower type that can be in a 3x3 area.
	
- **Rollback**
 - See below section

If you are running a server without gui, I adapted some code that retrieves the values out of settingstypes.txt. You can simply adjust the default settings in settingstypes.txt and they will be respected when Flowers_NT next opens/runs.I believe if you ever change these values via GUI they will then be in your minetest.conf and be unchangable via settingstypes.txt until deleted from minetest.conf.

### Rollback
Rollback is rather simple to trigger open minetest settings >> all settings >> mods >> flowers_nt >> rollback and set rollback from false to true.

Change no other settings or mods that maybe registering flowers using flowers_nt api - very important. 

Run and log on to server/game a few things will occur:
- If using waved water it will be reset to default settings.
- 2 LBM's maybe created depends how your flowers were orginally configured.
 - LBM 1 - Existing - All flower stages will be converted to the orginal registered flower stage 3.
 - LBM 2 - No Existing - All flower stages will be converted to air.
- If flowers mod was being used it's abms will no longer be affected.
- On player logon a small script will check their inventories for flowers 1,2,3,4,5 and either replace 1,2,4,5 with existing stage 3 or remove all flower stages 1-5. 
- Chests/Storage Nodes - Currently not handled

Depending on if your playing a solo game or it's a server you may need to leave flowers_nt running in rollback mod for a few days to a week to ensure maximum removal/conversion. Once your happy that most nodes have either been removed or converted you can then delete flowers_nt mod and hopefully end up with a minimum of unknown nodes and items.

I know the above wont be perfect but I'm hoping it'll minimise issues when people wish to remove this mod.	

## Simple Flower Example
Assuming all images are avaliable, your using MTG/Voxelgarden biomes etc as a base and your happy with the defaults and no existing flower to allow for, you can register the 5 stages + seed as simply as the below

    flowers_nt.register_flower({
							flower_name = "Purple Chrysanthemum",
							color       = "purple"
							sounds      = default.node_sound_leaves_defaults(),
							grow_on     = {"default:dirt",
							               "default:dirt_with_grass"
									      },
							biomes      = {"grassland", "deciduous_forest"},
							biome_seed  = 123456,
							cover       = 4
							})

## Complex Flower Example
A more complex example showing a floating water plant and MTG/Voxelgarden biomes etc

    flowers_nt.register_flower({
							flower_name = "sacred lotus",
							color      	  = "white",
							drawtype    	 = "mesh",
							mesh        	 = "sacred_lotus.obj",
							sounds      	 = default.node_sound_leaves_defaults(),
							grow_on     	 = {"default:dirt",
											    "default:water_source",
											    "default:river_water_source"
												},
							time_min    	 = 120,
							time_max    	 = 240,
							is_water    	 = {"default:dirt"},
							light_min   	 = 12,
							light_max   	 = 14,
							light_max_death  = true,
							inv_img     	 = true,
							biomes      	 = {"rainforest_swamp", "savanna_shore", "deciduous_forest_shore"},
							biome_seed  	 = 11223344,
							cover       	 = 7,
							y_min       	 = 0,
							y_max       	 = 0,
							y_offset    	 = 1,
							existing    	 = "example_mod:sacred_lotus",
							on_use      	 = minetest.item_eat(2)
							})


## Manually Configure Nodes
If you prefer you don't need to use the API to register flowers all the relevant functions that flowers_nt uses have been exposed so it is possible to manually configure a set of 6 nodes yourself which will then grow the same as the flowers created using the Flowers_NT API. 
	
This would be useful if you want significant customisation for a flower. It is not as easy as using the API but provides maximum flexability and may save you some time in coding and testing functions. 

### Flowers_NT Global Table

There is a single table were all flowers are registered:

**flowers_nt.registered_flowers**
The below values slightly replicate whats stored inside the standard minetest node registration. I could have stored them there by adding new fields to node registration table but didn't want to risk causing any problems for other mods so kept them stored in their own table. Some values are stored as I was unsure what may be useful or not later on eg color and desc_name. Where an existing flower node has been registered we add a simple placeholder which provides a pointer to the main record.

#### Values stored for non-existing

Value Key = mod_name..":"..flower_name  
*Note 1: no growth number just the name*  
*Note 2: It's important to keep the above key structure although the mod_name can be your own mods name.*

     ["Value Key"]   = {						
			reg_name  = reg_name,    - eg "orange_tulip"   			- string
			desc_name = desc_name,   - eg "Orange Tulip    			- string
			grow_on   = grow_on,     - eg {"default:dirt"} 			- table
			light_min = light_min,   - eg 12               			- number
			light_max = light_max,   - eg 15              			- number
			time_min  = time_min,    - eg 60              			- number
			time_max  = time_max,    - eg 180              			- number
			color     = color,       - eg "orange"         			- string
			existing  = existing,    - eg null or "default:tulip" 	- string
			is_water  = is_water     - eg false            			- boolean
			}

*On existing if no flower is already registered that needs to take the place for 
growth stage 3 then existing will be null/nil. If however there is an existing flower already registered then the registered name will be stored inside existing in the primary record and a pointer secondary record. Just makes lookups a tad easier*

#### Additional value when existing flower node present
If there is an existing flower the below is also added to flowers_nt.registered_flowers

Value Key = existing_reg_node_name eg "default:tulip"

     ["Value Key"] = {						
			parent = m_name..":"..reg_name eg "flowers_nt:orange_tulip" - string
			}
	
### Flowers_NT Functions

**flowers_nt.grow_flower_tmr(pos)**
Main flower timer to allow them to grow - calls flowers_nt.allowed_to_grow() and flowers_nt.set_grow_stage()

**flowers_nt.allowed_to_grow(pos)**
Uses the registered grow_on list to check if the node below is still growable for that flower type

**flowers_nt.set_grow_stage(pos)** 
Moves the flower to the next growth stage and restarts the timers

**flowers_nt.no_grow(pos)**
Stops a Picked and placed flower stage from growing by setting its meta for "flowers_nt" to 1

**flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)**
Does some checks then restarts flower growth cycle from Dormant stage 0 

**flowers_nt.seed_spread(pos,oldnode,player)**
After digging of flower seed head function checks the density of that flower type around the 
flower and if less than 4 randomly places a seed node in one of the 5 squares in front of the 
player who dug the flower if any of those nodes the flower can grow_on. The seed will spread 
+1/-1 node height, however this only occurs 50% of the time.

    ^ = Player face direction   
    O = Cut flower   
    X = Potential place locations
 
    X X X  
    X O X  
    __^__

**flowers_nt.get_name(node_name)**
From the registered node name this will return the registered flower name, parent name or if it's not a registered flower node it will return false.  
eg node name = "flowers_nt:orange_tulip_3" returns "flowers_nt:orange_tulip"  
eg node name = "default:tulip" returns "flowers_nt:orange_tulip"  
eg node name = "default:dirt" returns false 

**flowers_nt.on_place_water(itemstack, placer, pointed_thing)**
Haven't fully worked out why but if I on_place a mesh water plant to water even if the node is water pointable it will be placed on the bottom under the water. This function works around this issue so floating plants when manually placed float ontop of liquid nodes. returns itemstack
    
    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end

**flowers_nt.delete_decoration({"table","of","registered","decoration","names"})**
For the listed decoration names in the table, the decorations will be removed. Place single decoration names in a table eg {"flowers:tulip"} 
Many decorations are named the same as the node they place but this is not always the case.   
eg decoration name for node "flowers:tulip" = "flowers:tulip"   
eg decoration name for node "flowers:waterlily" = "default:waterlily"

### Registration example
This will take some time to configure manually but you can use the below as a template to create a registration file as such for a particular flower node set. You may encounter issues using the below as I haven't tested this extensively, so if you encounter problems ask on the forums or github and I'll try and help and I'm sure others will as well. So long as you keep the same node registration name structure and the requried functions/code in the body of the nodes anything else can be adjusted or changed to suite what you need. For example although my template below only covers drawtype = "plantlike" or "mesh" there is nothing to stop you using "nodebox" or any of the other node drawtypes. 

#### Register Flower to Flowers_NT Global Table
Firstly add the required values into flowers_nt.registered_flowers table.

I'll use the tulip from default as my example if you don't have an existing flower you can skip the second table addition and set exisiting in the first table to nil:

Add Primary Record:

    flowers_nt.registered_flowers["flowers_nt:orange_tulip"] ={
			reg_name  = "orange_tulip",
			desc_name = "Orange_Tulip",
			grow_on   = {"default:dirt", "default:dirt_with_grass"},
			light_min = 12,
			light_max = 15,
			time_min  = 60,
			time_max  = 180,
			color     = "orange",
			existing  = "default:tulip", -- or nil for no existing flower
			is_water  = false
    }

Add Secondary entry for existing flower:

    flowers_nt.registered_flowers["default:tulip"] ={
			parent    = "flowers_nt:orange_tulip"
    }

#### Register Node Stage 0 - Flower Dormant
This node is just an invisible marker, which holds the position that a flower does exist in that position, I borrowed this idea from Shara's endless apple mod.

	minetest.register_node(m_name..":"..reg_name.."_0", {
		description = S("Flower Name Dormant"),
		drawtype = "airlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		drop = "",
		groups = {not_in_creative_inventory = 1, flower = 1},
		on_timer = function(pos, elapsed)
						local node_name = minetest.get_node(pos).name
						local fl_reg_name = flowers_nt.get_name(node_name)						
						local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
						local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
						local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
						local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death
						
						-- not growable the marker is removed
						if not flowers_nt.allowed_to_grow(pos) then
							minetest.remove_node(pos)
						
						-- too dark or light then don't grow
						elseif minetest.get_node_light(pos) < light_min and not l_min_death or 
							   minetest.get_node_light(pos) > light_max and not l_max_death then
							
								minetest.get_node_timer(pos):start(time_min)
								
						elseif minetest.get_node_light(pos) < light_min and l_min_death or 
							   minetest.get_node_light(pos) > light_max and l_max_death then
							
								minetest.remove_node(pos)
						
						-- Grow the flower	
						else
							flowers_nt.set_grow_stage(pos)							
						end
					end
	})
	
Notes:   
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end

#### Register Node Stage 1 - Flower Seedling
	minetest.register_node(m_name..":"..reg_name.."_1", {
			description = S("Flower Name Seedling"),
			drawtype = "plantlike",              -- change to "mesh" if using mesh
			-- mesh = "mesh_name.obj",           -- uncomment if using mesh
			waving = 1,
			tiles = {"image_name.png"},          -- update
			inventory_image = "image_name.png",  -- update
			wield_image = "image_name.png",      -- update
			-- use_texture_alpha = "clip",        -- uncomment if using mesh
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			is_ground_content = true,
			buildable_to = true,
			sounds = node_sound_leaves(),        -- update
			selection_box = {
				type = "fixed",
				fixed = {-0.25,-0.5,-0.25, 0.25, 0.4, 0.25}
			},
			groups = {dig_immediate = 3, flammable = 2, flower = 1},

			after_place_node = function(pos, placer, itemstack)
								flowers_nt.no_grow(pos)
							   end,
							   
			after_dig_node = function(pos, oldnode, oldmetadata, digger)				
								flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
							  end,
			
			on_timer = function(pos, elapsed)
							local node_name = minetest.get_node(pos).name
							local fl_reg_name = flowers_nt.get_name(node_name)						
							local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
							local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
							local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
							local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death
							
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
						end
		})

Notes:   
For floating water plant then waving must = 3  
For mesh change drawtype to "mesh", mesh = "mesh.obj" and use_texture_alpha = "clip"  
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end
	   
#### Register Node Stage 2 - Flower Budding
	minetest.register_node(m_name..":"..reg_name.."_2", {
			description = S("Flower Name Budding"),
			drawtype = "plantlike",              -- change to "mesh" if using mesh
			-- mesh = "mesh_name.obj",           -- uncomment if using mesh
			waving = 1,
			tiles = {"image_name.png"},          -- update
			inventory_image = "image_name.png",  -- update
			wield_image = "image_name.png",      -- update
			-- use_texture_alpha = "clip",       -- uncomment if using mesh
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			is_ground_content = true,
			buildable_to = true,
			sounds = node_sound_leaves(),        -- update
			selection_box = {
				type = "fixed",
				fixed = {-0.25,-0.5,-0.25, 0.25, 0.4, 0.25}
			},
			groups = {dig_immediate = 3, flammable = 2, flower = 1},

			after_place_node = function(pos, placer, itemstack)
								flowers_nt.no_grow(pos)
							   end,

			after_dig_node = function(pos, oldnode, oldmetadata, digger)				
								flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
							  end,
			
			on_timer = function(pos, elapsed)
							local node_name = minetest.get_node(pos).name
							local fl_reg_name = flowers_nt.get_name(node_name)						
							local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
							local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
							local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
							local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death							
			
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
						end
		}
		
Notes:   
For floating water plant then waving must = 3   
For mesh change drawtype to "mesh", mesh = "mesh.obj" and use_texture_alpha = "clip"   
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end
			   
#### Register Node Stage 3 - Flowering
	minetest.register_node(m_name..":"..reg_name.."_3" or ":existing_mod_name:flower_registered", {	
			description = S(Flower Name),
			drawtype = "plantlike",              -- change to "mesh" if using mesh
			-- mesh = "mesh_name.obj",           -- uncomment if using mesh
			waving = 1,
			tiles = {"image_name.png"},          -- update
			inventory_image = "image_name.png",  -- update
			wield_image = "image_name.png",      -- update
			-- use_texture_alpha = "clip",       -- uncomment if using mesh
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			is_ground_content = true,
			buildable_to = true,
			sounds = node_sound_leaves(),        -- update
			selection_box = {
				type = "fixed",
				fixed = {-0.25,-0.5,-0.25, 0.25, 0.4, 0.25}
			},
			
			groups = {dig_immediate = 3, flammable = 2, flower = 1, color_"name" = 1}, -- update

			after_place_node = function(pos, placer, itemstack)
								flowers_nt.no_grow(pos)
							   end,

			after_dig_node = function(pos, oldnode, oldmetadata, digger)				
								flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
							  end,
			
			on_timer = function(pos, elapsed)				
						local node_name = minetest.get_node(pos).name
						local fl_reg_name = flowers_nt.get_name(node_name)						
						local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
						local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
						local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
						local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death
						
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
						end
			})
			
Notes:    
To override existing registered flower use ":" infront of the registered name eg ":default:tulip"    
For floating water plant then waving must = 3   
For mesh change drawtype to "mesh", mesh = "mesh.obj" and use_texture_alpha = "clip"   
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end
	   
#### Register Node Stage 4 - Flower Seed Head/Dead
	minetest.register_node(m_name..":"..reg_name.."_4",{
			description = S("Flower Name Seed Head"),
			drawtype = "plantlike",              -- change to "mesh" if using mesh
			-- mesh = "mesh_name.obj",           -- uncomment if using mesh
			waving = 1,
			tiles = {"image_name.png"},          -- update
			inventory_image = "image_name.png",  -- update
			wield_image = "image_name.png",      -- update
			-- use_texture_alpha = "clip",       -- uncomment if using mesh
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			is_ground_content = true,
			buildable_to = true,
			sounds = node_sound_leaves(),        -- update
			selection_box = {
				type = "fixed",
				fixed = {-0.25,-0.5,-0.25, 0.25, 0.4, 0.25}
			},
			groups = {dig_immediate = 3, flammable = 2, flower = 1},
			drop = m_name..":"..reg_name.."_5",
			
			after_place_node = function(pos, placer, itemstack)
								flowers_nt.no_grow(pos)
							   end,

			after_dig_node = function(pos, oldnode, oldmetadata, digger)
								flowers_nt.seed_spread(pos, oldnode, digger)			
								flowers_nt.flower_cycle_restart(pos,oldnode,oldmetadata)
							  end,
			
			on_timer = function(pos, elapsed)
						local node_name = minetest.get_node(pos).name
						local fl_reg_name = flowers_nt.get_name(node_name)						
						local light_min = flowers_nt.registered_flowers[fl_reg_name].light_min
						local light_max = flowers_nt.registered_flowers[fl_reg_name].light_max
						local l_min_death = flowers_nt.registered_flowers[fl_reg_name].l_min_death
						local l_max_death = flowers_nt.registered_flowers[fl_reg_name].l_max_death						
						
							if not flowers_nt.allowed_to_grow(pos)then
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
						end
		})
		
Notes:   
For floating water plant then waving must = 3   
For mesh change drawtype to "mesh", mesh = "mesh.obj" and use_texture_alpha = "clip"   
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end

#### Register Node Stage 5 - Flower Seed
		minetest.register_node(m_name..":"..reg_name.."_5", {
			description = S(Flower Name Seed"),
			drawtype = "plantlike",              -- change to "mesh" if using mesh
			-- mesh = "mesh_name.obj",           -- uncomment if using mesh
			waving = 1,
			tiles = {"image_name.png"},          -- update
			inventory_image = "image_name.png",  -- update
			wield_image = "image_name.png",      -- update
			-- use_texture_alpha = "clip",       -- uncomment if using mesh
			paramtype = "light",
			sunlight_propagates = true,
			walkable = false,
			is_ground_content = true,
			buildable_to = true,
			sounds = node_sound_leaves(),        -- update
			selection_box = {
				type = "fixed",
				fixed = {-0.25,-0.5,-0.25, 0.25, 0.4, 0.25}
			},
			groups = {dig_immediate = 3, seed = 1, flower = 1},
			
			on_place = function(itemstack, placer, pointed_thing)
						local node_below    = minetest.get_node(pointed_thing.under)
						local node_name   = node_below.name						
						local fl_reg_name = flowers_nt.get_name(itemstack:get_name())
						local rot_place   = flowers_nt.registered_flowers[fl_reg_name].rot_place
						local node_p2     = "N"
						local is_water    = flowers_nt.registered_flowers[fl_reg_name].is_water
						local a_pos         = pointed_thing.above
						
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
								minetest.set_node(a_pos, {name = fl_reg_name.."_0",param2 = node_p2})
								minetest.get_node_timer(a_pos):start(math.random(time_min, time_max))
								
								if not minetest.is_creative_enabled(placer:get_player_name()) then
									itemstack:take_item()
								end
							end

						else
							-- catches case: clicking dirt with water source above
							local node_a_name = minetest.get_node(a_pos).name
							if node_a_name == "air" then
								minetest.item_place_node(itemstack, placer, pointed_thing)
							end
						end	
						return itemstack
					end,
			
			after_place_node = function(pos, placer, itemstack)
									minetest.get_node_timer(pos):start(math.random(1, time_min/2))
							   end,
			
			on_timer = function(pos, elapsed)
							if not flowers_nt.allowed_to_grow(pos) then
								minetest.remove_node(pos)
								minetest.spawn_item(pos, m_name..":"..reg_name.."_5")
								
							elseif minetest.get_node_light(pos) < light_min or 
								   minetest.get_node_light(pos) > light_max then
								
									minetest.get_node_timer(pos):start(time_min)
								
							else
								flowers_nt.set_grow_stage(pos)
								
							end
						end
		})	

Notes: 
For floating water plant then waving must = 3
For mesh change drawtype to "mesh", mesh = "mesh.obj" and use_texture_alpha = "clip"   
For floating plants you'll need to add:   

    on_place = function(itemstack, placer, pointed_thing) 
                local ret_itemstack = flowers_nt.on_place_water(itemstack, placer, pointed_thing)
                return ret_itemstack
    end

#### Register LBM
So the node timers can start on mapgen an LBM must be registered for your flower/herb nodes. 

	local m_name = "your_mod_name"  -- update
	local reg_name = "flower_name"  -- update
	minetest.register_lbm({
	  name = m_name..":"..reg_name,       
	  run_at_every_load = true, 
	  nodenames = {m_name..":"..reg_name.."_0", 
				   m_name..":"..reg_name.."_1", 
				   m_name..":"..reg_name.."_2",
				   m_name..":"..reg_name.."_3" or "existing_mod_name:flower_registered" , -- Either your registered node name or existing node name
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

#### Register Mapgen Decoration
There are a few things to be aware of when registering the decoration for your flower. If you are registering a flower with an existing node you'll need to handle the existing decoration registration for that node. Either by deleting the entry from that mod (assuming you can) or the more safe road handling the deletion/removal from your mod which is a little cumbersome. I have added a small function which builds on work Termos did in this space and it does the dec removal process for you.

	if existing ~= nil then
		flowers_nt.delete_decoration({existing})
	end	
	
		minetest.register_decoration({
			name = "modname:flower_name",
			deco_type = "simple",
			place_on = flowers_nt.registered_flowers["modname:flower_name"].grow_on, -- if not floating water plant see notes
			sidelen = 16,
			noise_params = {
				offset = -0.02,
				scale = 0.04,
				spread = {x = 200, y = 200, z = 200},
				seed = 123456789,
				octaves = 3,
				persist = 0.6
			},
			biomes = {"biome name 1", "biome name 2"},
			y_max = 31000,
			y_min = 1,
			place_offset_y = 0,
			decoration = "modname:flower_name_3",
		})

Notes: 
For floating water plant y_offset will need to be at least 1 although this is dependant on your biome configuration for shorelines.   
For floating water plants don't forget to add dirt/sand not water or they wont be placed eg {"default:dirt"}
	
## Game and Mod Notes

### Minetest Game
Intergration and rollback for base Minetest game and mods should be very good. I have done most of my testing against the base MTG, however seems everytime I do do some testing/playing I manage to find some strange edge case which causes a crash. I am hopeful I have got most if not all of them now.

### Voxel Garden
Integration and rollback with Voxelsgarden and mods likewise is very good, there is some customisation in the i_game_vg.lua which might be useful if you have existing seeds or multiple stages you need to replace. The images for Voxel Garden are also tagged with a "vg" right before the stage number eg "flowers_nt_orange_tulip_vg_1.png" as it has a different look/feel to base MTG - I did my best to keep in theme. It's intresting to note Voxel Garden already had a 1 stage regrowth step/timer for mushrooms. 

### Bonemeal mod
It works but I had to copy out about half the code from bonemeal>>init.lua to i_bonemeal_override.lua and then make changes so I could override the bonemeal function bonemeal:on_use. I also stopped flowers from being placed if you use bonemeal on grass. I did the second very lightly by just adding an impossible check inside an if of "1==2". Both changes are marked with comments using "flowers_nt" so they can be searched up very easily. This does however leave a fairly heavy dependancy and maintenace overhead as if Bonemeal updates I'll have to update my override code and retest it all.
