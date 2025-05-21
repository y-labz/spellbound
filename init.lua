-- Spellbound Mod for Minetest Game ---------------------------------
-- to spend time with the kids and inspire them to learn coding;
-- maybe include some beautiful math... ;
-- and to test some ideas... ;
-- y-labz, 2025 -----------------------------------------------------
--
-- Define your spellbook: subcommands and their logic
local spellbook = {}

spellbook.purge = function(name, args)
  -- minetest.chat_send_player(name, "Purging the land... 🌪️")
  minetest.chat_send_all(name .. " is purging the land... 🌪️")
  minetest.clear_objects({mode = "quick"})
end

spellbook.boom = function(name, args)
  local pos = minetest.get_player_by_name(name):get_pos()
  minetest.add_entity(pos, "tnt:tnt")
  -- minetest.add_entity(pos, "fire:permanent_flame")
  -- pos.x = pos.x + 2
  -- minetest.remove_node(pos)
  -- minetest.place_node(pos, {name="tnt:tnt"})
  minetest.chat_send_player(name, "Boom summoned 💥")
end

spellbook.teleport = function(name, args)
  local coords = {}
  for word in args:gmatch("[^%s]+") do
    table.insert(coords, tonumber(word))
  end
  if #coords == 3 then
    minetest.get_player_by_name(name):set_pos({x=coords[1], y=coords[2], z=coords[3]})
    minetest.chat_send_player(name, "Teleported to ("..table.concat(coords, ", ")..") ✨")
  else
    minetest.chat_send_player(name, "Usage: /spell teleport x y z")
  end
end

spellbook.help = function(name, args)
  local available = {}
  for k, _ in pairs(spellbook) do table.insert(available, k) end
  minetest.chat_send_player(name, "Available spells: " .. table.concat(available, ", "))
end

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

-- all kind of super powers -----------------------------------------
minetest.register_chatcommand("super", {
  description = "Turn ON my super man mode",
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    player:set_physics_override({
      gravity = 0.1,
      -- set gravity to 10% of its original value (0.1 * 9.81)
      speed = 10
    })
    return true, "Super Mode ON"
  end
})

minetest.register_chatcommand("superoff", {
  description = "Turn OFF my super man mode",
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    player:set_physics_override({
      gravity = 1,
      speed = 1
    })
    return true, "Super Mode OFF"
  end
})

minetest.register_chatcommand("setfire", {
  params = "<playername>",
  description = "set fire circle version 1",
  func = function(name, param)
    minetest.chat_send_all(name .. " is casting a fire spell ... ")

    local player = minetest.get_player_by_name(name)
    if minetest.get_player_by_name(param) ~= nil then
      player = minetest.get_player_by_name(param)
    end

    local pos0 = player:get_pos()
    -- minetest.chat_send_all("pos0.x = " .. tostring(pos0.x))
    -- minetest.chat_send_all("pos0.y = " .. tostring(pos0.y))
    -- minetest.chat_send_all("pos0.z = " .. tostring(pos0.z))
    local n = 20
    local r = 10  -- config todo param
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
      -- minetest.place_node(pos, {name="tnt:tnt"})
    end
  end
})

-- unsorted spells --------------------------------------------------
--
-- unsorted spells --------------------------------------------------
--
-- Mods should use minetest. Builtin should use core.
-- https://forum.luanti.org/viewtopic.php?t=14451
-- core.register_chatcommand("purge0", {
minetest.register_chatcommand("quickpurge", {
  params = "",
  description = "Quickly clears all objects from the map (lag cleanup).",
  privs = {server = true}, --/grant username server
  func = function(name, param)
    minetest.clear_objects({mode = "quick"})
    return ture, "Entities cleared. The air feels lighter."
  end
})

