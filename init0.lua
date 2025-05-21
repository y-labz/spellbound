-- Spellbound Mod for Minetest Game ---------------------------------
-- to spend time with the kids and inspire them to learn coding;
-- maybe include some beautiful math... ;
-- and to test some ideas... ;
-- y-labz, 2025 -----------------------------------------------------
--
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

    local pos0 = player:getpos()
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

