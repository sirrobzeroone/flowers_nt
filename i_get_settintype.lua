-- Excessive but intresting :)

-- modname and path
	local m_name = minetest.get_current_modname()
	local m_path = minetest.get_modpath(m_name)

function flowers_nt.get_setting(get_setting)
	local output
	
	-- http://lua-users.org/wiki/FileInputOutput
	-- Nothing clear on the above re-liscence I'm assuming CC0/free to use.
	-- see if the file exists
	local function file_exists(file)
	  local f = io.open(file, "rb")
	  if f then f:close() end
	  return f ~= nil
	end

	-- get all lines from a file, returns an empty 
	-- list/table if the file does not exist
	local function lines_from(file)
	  if not file_exists(file) then return {} end
	  local lines = {}
	  for line in io.lines(file) do 
		lines[#lines + 1] = line
	  end
	  return lines
	end

	-- Find our setting
	local file = m_path .."/settingtypes.txt"
	local lines = lines_from(file)

	-- find our value
	for k,v in pairs(lines) do
	  
		if string.sub(v,1,1) ~="#" and 
		   string.sub(v,1,1) ~="" and
		   string.sub(v,1,1) ~="[" then
	  
			if string.find(v, get_setting) then
			  local split = string.split(v, " ")
			  output = split[#split]
			  break
			end
		end 
	end
	return output
end