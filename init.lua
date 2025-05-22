local mod_name = minetest.get_current_modname()
local path_mod = minetest.get_modpath(mod_name)
local path_world = minetest.get_worldpath()

local u = dofile(path_mod .. "/lib/utils.lua")
local m = dofile(path_mod .. "/lib/maths.lua")
local spellbook = {}

---------------------------------------------------------------------
-- all kind of super powers: speed, fire and so on ------------------
---------------------------------------------------------------------
spellbook.super = function(name, args)
  -- Turn ON my superman mode
  -- Usage: /spell super
  local player = minetest.get_player_by_name(name)
  player:set_physics_override({
    gravity = 0.1,
    speed = 10
  })
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
  minetest.chat_send_all(name .. " is casting a fire spell ... ")
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

  if minetest.get_player_by_name(target) ~= nil then
    player = minetest.get_player_by_name(target)
  else
    minetest.chat_send_all("ERROR, no player " .. target)
    return false
  end

  local pos0 = player:get_pos() -- circle origin
  local pos = {x=0, y=0, z=0}
  -- pos.y = pos0.y - 1
  local rad1 = math.pi * 2 / n
  for i=0, n-1 do
    pos.x = pos0.x + r * math.cos(i * rad1)
    pos.y = pos0.y
    pos.z = pos0.z + r * math.sin(i * rad1)
    minetest.remove_node(pos)
    -- minetest.set_node(pos, {name="default:torch"})
    -- minetest.place_node(pos, {name="default:torch"})
    minetest.place_node(pos, {name="fire:permanent_flame"})
  end
end

---------------------------------------------------------------------
-- todo, tnt cannot be added...
spellbook.boom = function(name, args)
  -- Summon a TNT to player
  -- Usage: /spell boom [playername]
  local pos = minetest.get_player_by_name(name):get_pos()
  minetest.add_entity(pos, "tnt:tnt") --bug todo
  -- minetest.add_entity(pos, "fire:permanent_flame")
  -- pos.x = pos.x + 2
  -- minetest.remove_node(pos)
  -- minetest.place_node(pos, {name="tnt:tnt"})
  minetest.chat_send_player(name, "Boom summoned 💥")
end

---------------------------------------------------------------------
-- build things like xyz models, big walls, spirals and so on -------
---------------------------------------------------------------------
-- todo: 3D Print mimic with different materials for different layers
spellbook.build = function(name, args)
  -- Build structures using xyz file input
  -- Usage: /spell build [xyz_file] [scale] [up_dir] [material]
  -- Usage: 2 strings, 1st file, 2nd material, 2 numbers, scale & up_dir 1/2/3
  -- Usage: could be mixed up or some default

  local player = minetest.get_player_by_name(name)
  local pos0 = player:get_pos()
  local look_dir = player:get_look_dir()

  -- default parameters:
  local filename = "helix_201.xyz"
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
  -- handle up vector, up comes at last, upv[3]
  local upv = m.rotate_up_vector(up_dir)

  local fullpath = path_mod .. "/dat/" .. filename
  minetest.chat_send_player(name, "file: " .. fullpath)

  if u.file_exists(fullpath) then
    minetest.chat_send_player(name, "found file")
    local points = u.lines_from(fullpath)
    local p1 = {0, 0, 0}
    local p2 = {x=0, y=0, z=0}
    local distx = dist * look_dir.x
    local distz = dist * look_dir.z --north in map
    local disty = 0  --same level as foot
    minetest.chat_send_player(name, "found lines " .. tostring(#points))

    for i, line in ipairs(points) do
      p1 = u.parse_line_xyz(line)
      if u.valid_xyz(p1) then
        p2.x = pos0.x + distx + scale * p1[upv[1]]
        p2.z = pos0.z + distz + scale * p1[upv[2]]
        p2.y = pos0.y + disty + scale * p1[upv[3]] --y is up in game
        --todo offset ymin from foot level...
        minetest.remove_node(p2)
        -- minetest.set_node(p2, {name="default:stone"})
        minetest.set_node(p2, {name = material})
      end
    end
  else
    minetest.chat_send_player(name, "File not found: " .. fullpath)
  end

  return true, "Building done."
end

---------------------------------------------------------------------
-- unsorted spells --------------------------------------------------
---------------------------------------------------------------------
spellbook.t = function(name, args)
  -- Test function for dev
  -- Usage: /spell t [args]
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
  minetest.chat_send_player(name, "Available spells: " .. table.concat(available, ", "))
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

