local utils = {}

function utils.greet(name)
  minetest.log("action", "[Luanti] Spell cast by " .. name)
end

-------------------------------------------------------------------------
-- play sounds...
function utils.sound1(p)
  minetest.sound_play("magic", {
    pos = p,
    max_hear_distance = 16,
    gain = 1.0,
  })
end

function utils.sound2(p)
  minetest.sound_play("magic-strike", {
    pos = p,
    max_hear_distance = 16,
    gain = 1.0,
  })
end

-------------------------------------------------------------------------
-- see if the file exists
function utils.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-------------------------------------------------------------------------
-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function utils.lines_from(file)
  if not utils.file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

-------------------------------------------------------------------------
-- ok, could be more generic, like sep as arg1, but
-- reg exp of , ; space different, unfamiliar... maybe later.
function utils.parse_line_xyz(line)
  local tmp = {}
  local res = {}

  -- check empty or # comments --
  local c0 = string.sub(line, 1, 1)
  if c0 == "" or c0 == '#' then return res end

  -- test sep comma, see if 3 elements
  for txt in string.gmatch(line, '([^,]+)') do
    table.insert(tmp, txt)
  end
  if #tmp == 3 then --seems ok, then remove space, turn to number
    for i, v in ipairs(tmp) do
      res[i] = tonumber(v)
    end
    return res
  else
    tmp = {} --reset tmp table and check other sep
  end

  -- test sep ; semicolon
  for txt in string.gmatch(line, "[^;]+") do
    table.insert(tmp, txt)
  end
  if #tmp == 3 then
    for i, v in ipairs(tmp) do
      res[i] = tonumber(v)
    end
    return res
  else
    tmp = {} --reset tmp table and check other sep
  end

  -- test sep space, must be placed AFTER the first two sep types
  -- in the END, otherwise "1.1; | 2.2; | 3.3;" could happen, bug!
  for txt in line:gmatch("%S+") do
    table.insert(tmp, txt)
  end
  if #tmp == 3 then
    for i, v in ipairs(tmp) do
      res[i] = tonumber(v)
    end
    return res
  elseif #tmp == 0 then --empty line with spaces
    return {}
  -- else
    -- tmp = {} --reset tmp table and check other sep
  end

  -- print("parse line error!") --todo
  minetest.log("error", "utils.parse_line_xyz error!")
  return {}
end

-------------------------------------------------------------------------
-- verify x, y, z numbers in the table
function utils.valid_xyz(tab)
  if #tab ~= 3 then
    return false
  end
  for _, v in ipairs(tab) do
    if type(v) ~= "number" then
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------
-- generate point table from file
function utils.gen_xyz_table(file)
  local lines = utils.lines_from(file)
  local xyz_table = {}
  local xyz
  for _, line in ipairs(lines) do
    xyz = utils.parse_line_xyz(line)
    if utils.valid_xyz(xyz) then
      table.insert(xyz_table, xyz)
    end
  end
  return xyz_table
end

-------------------------------------------------------------------------
-- get min of some coordinates for offset
function utils.get_min_coord(xyz_tab, axis)
  -- xyz_tab = {{x1,y1,z1}, {x2,y2,z2},...}, e.g. axis=2 for y axis
  -- return y_min of all points
  local min_val = math.huge  -- start with +infinity
  for _, coord in ipairs(xyz_tab) do
    if coord[axis] and coord[axis] < min_val then
      min_val = coord[axis]
    end
  end
  return min_val
end

-------------------------------------------------------------------------
-- build up height h from one position
function utils.build_h(pos, h, material)
  for i=1, h do
    minetest.remove_node(pos)
    minetest.place_node(pos, {name=material})
    pos.y = pos.y + 1
  end
end

-------------------------------------------------------------------------
-- Function to set the blocks in a cube shell
function utils.build_cube_shell(minp, maxp, material)
  for x = minp.x, maxp.x do
    for y = minp.y, maxp.y do
      for z = minp.z, maxp.z do
        local is_surface = (
        x == minp.x or x == maxp.x or
        y == minp.y or y == maxp.y or
        z == minp.z or z == maxp.z
      )
        if is_surface then
          minetest.set_node({x=x, y=y, z=z}, {name=material})
          -- minetest.remove_node({x=x, y=y, z=z})
          -- minetest.place_node({x=x, y=y, z=z}, {name=material})
          -- does not work here due to place behavior
        end
      end
    end
  end
end

-------------------------------------------------------------------------
-- update parameters with arguments
function utils.update_param(params, args)
  local params_new = {}
  -- parse args string, components with "="
  -- e.g. args = " arg0 a=1 b=0.2 arg1 c=mat arg2 "
  -- -> params_new = { a=1, b=0.2, c="mat" }
  -- next step: compare params_new with params
  -- e.g. params = { a=90, b=0, c="ta", d=1, e=43 }
  -- update params values where the ids occur in params_new
  -- then return params

  -- Step 1: parse args string for key=value pairs
  for key, value in string.gmatch(args, "(%w+)%s*=%s*([^%s]+)") do
    -- Attempt to convert numeric values
    local num = tonumber(value)
    if num then
      params_new[key] = num
    else
      params_new[key] = value
    end
  end

  -- Step 2: update params using parsed values
  for k, v in pairs(params_new) do
    if params[k] ~= nil then
      params[k] = v
    end
  end

  return params
end

-------------------------------------------------------------------------
return utils

