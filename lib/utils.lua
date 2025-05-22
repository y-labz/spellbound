local util = {}

function util.greet(name)
  minetest.log("action", "[Luanti] Spell cast by " .. name)
end

-------------------------------------------------------------------------
-- see if the file exists
function util.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-------------------------------------------------------------------------
-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function util.lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

-------------------------------------------------------------------------
-- ok, could be more generic, like sep as arg1, but 
-- reg exp of , ; space different, unfamiliar... maybe later. 
function util.parse_line_xyz(line)
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
  else
    tmp = {} --reset tmp table and check other sep
  end

  -- print("parse line error!") --todo
  minetest.log("error", "util.parse_line_xyz error!")
  return {}
end

-------------------------------------------------------------------------
---verify x, y, z numbers in the table
function util.valid_xyz(tab)
  if #tab ~= 3 then
    return false
  end
  for i,v in ipairs(tab) do
    if type(v) ~= "number" then
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------
-- update parameters with arguments
function util.update_param(params, args)
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
return util

