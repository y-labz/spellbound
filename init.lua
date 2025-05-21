-- Spellbound Mod for Minetest Game ---------------------------------
-- * to spend time with the kids and inspire them to learn coding;
-- * maybe include some beautiful math... ;
-- * and to test some ideas... ;
-- y-labz, 2025 -----------------------------------------------------

local spellbook = {}

---------------------------------------------------------------------
-- all kind of super powers -----------------------------------------
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
  -- todo add limits

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
-- unsorted spells --------------------------------------------------
spellbook.purge = function(name, args)
  -- Quickly clears all objects from the map
  -- Usage: /spell purge
  -- minetest.chat_send_player(name, "Purging the land... 🌪️")
  minetest.chat_send_all(name .. " is purging the land... 🌪️")
  minetest.clear_objects({mode = "quick"})
end

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

end

spellbook.tele= function(name, args)
  local coords = {}
  for word in args:gmatch("[^%s]+") do
    table.insert(coords, tonumber(word))
  end
  if #coords == 3 then
    minetest.get_player_by_name(name):set_pos({x=coords[1], y=coords[2], z=coords[3]})
    minetest.chat_send_player(name, "Teleported to ("..table.concat(coords, ", ")..") ✨")
  else
    minetest.chat_send_player(name, "Usage: /spell tele x y z")
  end
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

