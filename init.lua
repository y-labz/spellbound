local mod_name = minetest.get_current_modname()
local path_mod = minetest.get_modpath(mod_name)
local path_world = minetest.get_worldpath()

local u = dofile(path_mod .. "/lib/utils.lua")
local m = dofile(path_mod .. "/lib/maths.lua")
local spellbook = {}

---------------------------------------------------------------------
-- all kind of super powers: speed, fire and so on
---------------------------------------------------------------------
spellbook.super = function(name, args)
  -- Turn ON my superman mode
  -- Usage: /spell super
  local player = minetest.get_player_by_name(name)
  player:set_physics_override({
    gravity = 0.1,
    speed = 10
  })
  u.sound1(player:get_pos())
  minetest.chat_send_all(name .. " is now superman")
  return true, "Super Mode ON"
end

---------------------------------------------------------------------
spellbook.superoff = function(name, args)
  -- Turn OFF my superman mode
  -- Usage: /spell superoff
  local player = minetest.get_player_by_name(name)
  player:set_physics_override({
    gravity = 1,
    speed = 1
  })
  minetest.chat_send_all(name .. " is no longer superman")
  return true, "Super Mode OFF"
end

---------------------------------------------------------------------
-- todo: firespiral, firecylinder?
spellbook.firering = function(name, args)
  -- Summon a fire ring to myself or another player
  -- Usage: /spell firering [playername] [n_fire] [radius]

  -- default setting:
  local target = name
  local n = 10
  local r = 5

  -- process args if given:
  if args then
    local arg_tab = {}
    for a in args:gmatch("[^%s]+") do
      table.insert(arg_tab, a) --all strings here
    end
    local target2 = nil
    local n2 = nil
    local r2 = nil
    -- fuzzy parsing
    for _, v in ipairs(arg_tab) do
      -- if tonumber(v) == nil and not target2 then
      if tonumber(v) == nil then
        -- playername str cannot be turned to number
        target2 = v
      else
        -- if value can be converted to number
        -- the first number should be n
        if not n2 then
          n2 = tonumber(v)
        elseif not r2 then
          r2 = tonumber(v)
        end
      end
    end
    -- update parameters if new
    if target2 then target = target2 end
    if n2 then n = n2 end
    if r2 then r = r2 end
  end
  -- todo add limits??

  -- setup the target:
  local player
  local player_t = minetest.get_player_by_name(target)
  if player_t then
    player = player_t
  else
    minetest.chat_send_player(name, "ERROR, no player " .. target)
    return false
  end

  local origin = player:get_pos() -- circle origin
  local pos = vector.zero()
  -- pos.y = origin.y - 1
  local rad1 = math.pi * 2 / n
  for i=0, n-1 do
    pos.x = origin.x + r * math.cos(i * rad1)
    pos.y = origin.y
    pos.z = origin.z + r * math.sin(i * rad1)
    -- minetest.set_node(pos, {name="default:torch"})
    minetest.remove_node(pos)
    minetest.place_node(pos, {name="fire:permanent_flame"})
    -- minetest.place_node(pos, {name="default:torch"})
  end

  u.sound1(origin)
  minetest.chat_send_all(name .. " is casting a fire spell ... ")
end

---------------------------------------------------------------------
spellbook.glasscube = function(name, args)
  -- Summons a glass cage to trap / protect a player
  -- Usage: /spell glasscube [T=playername] [L=10] [M=default:glass]

  -- default parameters
  local par = {
    T = name,  -- default target me
    L = 10,    -- input Length to calc, not exact outcome
    M = "default:glass"
  }
  par = u.update_param(par, args)
  -- length between 4 and 100, well disciplined little number
  par.L = math.max(8, math.min(100, par.L)) - 1
  -- local half = par.L / 2
  -- local half = math.floor((par.L - 1) / 2 + 0.5)
  local half = math.floor(par.L / 2 + 0.5)

  -- setup the target:
  local player
  local player_t = minetest.get_player_by_name(par.T)
  if player_t then
    player = player_t
  else
    minetest.chat_send_player(name, "ERROR, no player " .. par.T)
    return false
  end
  local origin = vector.round(player:get_pos())

  -- Base corner of the outer cube
  local base_min = {
    x = origin.x - half,
    y = origin.y - 2, --tested ok, stands on floor
    z = origin.z - half
  }
  local base_max = {
    x = origin.x + half,
    y = origin.y - 2 + par.L,
    z = origin.z + half
  }
  -- set outer layer
  u.build_cube_shell(base_min, base_max, par.M)
  -- Inner layer (1 block inside)
  local inner_min = vector.add(base_min, {x=1, y=1, z=1})
  local inner_max = vector.add(base_max, {x=-1, y=-1, z=-1})
  u.build_cube_shell(inner_min, inner_max, par.M)

  u.sound2(origin)
  minetest.chat_send_all(name .. " summoned a cage around " .. par.T .. "!")
  return true
end

---------------------------------------------------------------------
-- build things like xyz models, huge walls, spirals and so on
---------------------------------------------------------------------
-- todo: 3D Print mimic with different materials for different layers
spellbook.build = function(name, args)
  -- Build structures using xyz file input
  -- Usage: /spell build [xyz_file] [scale] [up_dir] [material]
  -- Usage: 2 strings, 1st file, 2nd material, 2 numbers, scale & up_dir 1/2/3
  -- Usage: could be mixed up or some default

  local player = minetest.get_player_by_name(name)
  local origin = player:get_pos()
  local look_dir = player:get_look_dir()

  -- default parameters:
  local filename = "helix.xyz"
  local material = "default:stone" --depend!
  local scale = 1
  local up_dir = 3 --most cases z is pointing upward?
  local dist = 20 --config

  -- process args if given:
  if args then
    local arg_tab = {}
    for a in args:gmatch("[^%s]+") do
      table.insert(arg_tab, a) --all strings here
    end
    -- tmp var...
    local f2, m2, s2, u2 = nil, nil, nil, nil
    -- fuzzy parsing
    for _, v in ipairs(arg_tab) do
      if tonumber(v) == nil and not f2 then
        f2 = v
      elseif tonumber(v) == nil and not m2 then
        m2 = v
      elseif tonumber(v) and not s2 then
        s2 = tonumber(v)
      elseif tonumber(v) and not u2 then
        u2 = tonumber(v)
      end
    end -- not very elegant, but works
    -- update parameters if new
    if f2 then filename = f2 end
    if m2 then material = m2 end
    if s2 then scale = s2 end
    if u2 then up_dir = u2 end
  end
  -- todo add limits??
  -- handle up vector, up dir comes at last, upv[3]
  local upv = m.rotate_up_vector(up_dir)

  local fullpath = path_mod .. "/models/" .. filename
  minetest.chat_send_player(name, "file: " .. fullpath)

  if u.file_exists(fullpath) then
    minetest.chat_send_player(name, "found it, start building...")
    local points = u.gen_xyz_table(fullpath)
    local ymin = u.get_min_coord(points, upv[3])
    local p2 = vector.zero()
    local distx = dist * look_dir.x
    local distz = dist * look_dir.z --north in map
    -- local disty = 0  --same level as foot
    minetest.chat_send_player(name, "#nodes: " .. tostring(#points))

    for _, p in ipairs(points) do
      p2.x = origin.x + distx + scale * p[upv[1]]
      p2.z = origin.z + distz + scale * p[upv[2]]
      --y is up in game; so lowest point y is now 0, foot level:
      p2.y = origin.y + scale * (p[upv[3]] - ymin)
      minetest.set_node(p2, {name = material})
    end
  else
    minetest.chat_send_player(name, "File not found: " .. fullpath)
    return false
  end

  u.sound2(origin)
  minetest.chat_send_player(name, "Building done.")
  return true
end

---------------------------------------------------------------------
spellbook.archimedes = function(name, args)
  -- Build a cool archimedes spiral structure
  -- Usage: /spell archimedes [H=10] [M=default:brick]

  -- default parameters
  local par = {
    H = 10,  -- Height of the spiral wall
    M = "default:brick"  -- Material
  }
  par = u.update_param(par, args) --if special wishes

  -- config part, not included in args yet
  local theta_max = 2 * math.pi * 4
  local N0 = 100 -- ini for the first round
  local N -- when radius grows, need nore points to avoid gap
  local theta = 0.1 --init angle
  local a, b = 5, 1

  local me = minetest.get_player_by_name(name)
  local origin = me:get_pos()
  local p1 = vector.zero()
  local tmp

  while theta <= theta_max do
    tmp = m.spiral_archimedes(theta, a, b)
    p1.x = tmp[1] + origin.x
    p1.z = tmp[2] + origin.z
    p1.y = origin.y
    u.build_h(p1, par.H, par.M)
    --update angle and N
    -- if theta > 2*math.pi then
    N = N0 * math.ceil(theta / (2*math.pi))
    --N0,N0*2,*3,and so on,could be more analytical,works,whatever
    theta = theta + 2*math.pi / N
  end

  u.sound2(origin)
  minetest.chat_send_all(name .. "just built an archimedes altar")
  return true
end

---------------------------------------------------------------------
spellbook.wall = function(name, args)
  -- Build a wall in front of the target player
  -- Usage: /spell wall [T=name] [H=40] [L=80] [D=30] [M=default:brick]
  -- Usage: the order does not matter, but the format Key=Value

  -- default parameters
  local par = {
    T = name,             -- target name
    H = 40,               -- Height of the wall
    L = 80,               -- Length of the wall
    D = 30,               -- Distance to the player
    M = "default:brick"   -- Material
  }
  par = u.update_param(par, args)

  -- setup the target:
  local player
  local player_t = minetest.get_player_by_name(par.T)
  if player_t then
    player = player_t
  else
    minetest.chat_send_player(name, "ERROR, no player " .. par.T)
    return false
  end

  local look_dir = player:get_look_dir()
  local player_pos = player:get_pos()
  -- pos.y = pos.y + player:get_properties().eye_height
  -- local p0 = vector.add(pos, vector.multiply(look_dir, par.D))
  local p0 = player_pos + look_dir * par.D --vector operators
  p0.y = player_pos.y --on the same level
  -- p0 = vector.round(p0)
  p0 = p0:round() --roundup to integers
  local up_vector = vector.new(0, 1, 0) --up, y positive
  local look_dir_horizont = vector.new(look_dir.x, 0, look_dir.z)
  local wall_edge_dir = vector.cross(up_vector, look_dir_horizont)
  -- v2 = vector.normalize(v2)
  wall_edge_dir = wall_edge_dir:normalize()
  local p1

  for i = 0, par.H do --start from 0 to preserve the bottom level
    for j = math.round(par.L/2)*(-1), math.round(par.L/2) do
      p1 = p0 + i * up_vector + j * wall_edge_dir
      p1 = vector.round(p1)
      minetest.remove_node(p1)
      minetest.place_node(p1, {name = par.M})
    end
  end

  u.sound2(player_pos)
  minetest.chat_send_all(name .. "summoned a wall...")
  return true
end

---------------------------------------------------------------------
-- beam (like teleport) related functions
---------------------------------------------------------------------
local path_beam = path_world .. '/beam/'
-- Because mkdir() is idempotent — calling it repeatedly is fine;
-- it'll just skip if the dir already exists. No harm done.
minetest.mkdir(path_beam)
minetest.log("action", "[beam] directory check: " .. path_beam)

-- if not minetest.mkdir(path_beam) then
--   minetest.log("action", "[beam] directory already exists at: " .. path_beam)
-- else
--   minetest.log("action", "[beam] Created data directory at: " .. path_beam)
-- end

---------------------------------------------------------------------
spellbook.beamlist = function(name, args)
  -- Get a list of available beam positions
  -- Usage: /spell beamlist
  local dir_list = minetest.get_dir_list(path_beam)
  minetest.chat_send_player(name, tostring(#dir_list) .. ' beam positions found:')
  minetest.chat_send_player(name, table.concat(dir_list, "  ;  "))
end

---------------------------------------------------------------------
spellbook.beamsave = function(name, args)
  -- Save a beam position with a name
  -- Usage: /spell beamsave [position_name]
  -- Usage: pos_number will be used if no name given
  local pos = minetest.get_player_by_name(name):get_pos()
  local pos_txt = vector.to_string(pos)
  local posname = args
  if posname == nil or posname == "" then
    local dir_list = minetest.get_dir_list(path_beam)
    posname = 'pos_' .. tostring(#dir_list + 1)
  end

  if u.file_exists(path_beam .. posname) then
    posname = posname .. "2"
    minetest.chat_send_player(name, "posname conflict, using " .. posname)
  end

  local res = minetest.safe_file_write(path_beam .. posname, pos_txt)

  if res then
    u.sound1(pos)
    minetest.chat_send_player(name, "beamsave done: " .. path_beam .. posname)
    return true
  else
    minetest.chat_send_player(name, "beamsave ERROR!")
    return false
  end
end

---------------------------------------------------------------------
spellbook.beam = function(name, args)
  -- Teleport / beam myself to a saved position
  -- Usage: /spell beam [position_name]
  -- Usage: (0, 10, 0) will be used if no name given
  local player = minetest.get_player_by_name(name)
  local pos2 = vector.new(0, 10, 0)

  if args == nil or args == "" then
    player:set_pos(pos2)
    u.sound1(pos2)
    minetest.chat_send_player(name, "beamed to (0, 10, 0)")
    return true
  elseif u.file_exists(path_beam .. args) then
    local line = u.lines_from(path_beam .. args)
    pos2 = vector.from_string(line[1])
    player:set_pos(pos2)
    u.sound1(pos2)
    minetest.chat_send_player(name, "beamed to " .. args)
    return true
  else
    minetest.chat_send_player(name, "location not found: " .. args)
    return false
  end
end

---------------------------------------------------------------------
-- unsorted spells
---------------------------------------------------------------------
spellbook.t = function(name, args)
  -- Test function for dev
  -- Usage: /spell t [args]

  minetest.log("action", "_VERSION: " .. _VERSION)

  minetest.chat_send_all(name .. " is testing the spells...")
  if args then
    minetest.chat_send_all("args: " .. args)
  else
    minetest.chat_send_all("no args given")
  end

  local arg_tab = {}
  for a in args:gmatch("[^%s]+") do
    table.insert(arg_tab, a)
  end

  for i, value in ipairs(arg_tab) do
    minetest.chat_send_all("arg: " .. i .. value)
  end

  u.greet(name)

end

spellbook.purge = function(name, args)
  -- Quickly clears all objects (like animals) from the map
  -- Usage: /spell purge
  -- minetest.chat_send_player(name, "Purging the land... 🌪️")
  minetest.chat_send_all(name .. " is purging the land... 🌪️")
  minetest.clear_objects({mode = "quick"})
end

spellbook.help = function(name, args)
  -- print available spells
  -- Usage: /spell help
  local available = {}
  for k, _ in pairs(spellbook) do table.insert(available, k) end
  minetest.chat_send_player(name, "spells: " .. table.concat(available, ", "))
end

---------------------------------------------------------------------
-- Register the unified command
---------------------------------------------------------------------
minetest.register_chatcommand("spell", {
  params = "<subcommand> [args]",
  description = "Cast a modular spell: /spell <subcommand> [args]",
  privs = {interact = true},

  func = function(name, param)
    local subcmd, args = param:match("^(%S+)%s*(.*)$")
    if not subcmd then
      -- return false, "Usage: /spell <subcommand> [args]"
      spellbook["help"](name, param)
      return true
    end

    local spell = spellbook[subcmd]
    if spell then
      spell(name, args)
      return true
    else
      return false, "Unknown spell: '" .. subcmd .. "' 🔮"
    end
  end
})

