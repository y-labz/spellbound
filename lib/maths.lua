local maths = {}

-------------------------------------------------------------------------
function maths.rotate_up_vector(up)
  -- up must be number
  if type(up) ~= "number" then
    up = tonumber(up)
  end

  local vec = {1, 2, 3}
  if up < 1 or up > 3 then
    return vec  -- fallback: no change
  end
  local value = vec[up]
  table.remove(vec, up)
  table.insert(vec, value)
  return vec
end
-- rotate_up_vector(1) -- {2, 3, 1}
-- rotate_up_vector(2) -- {1, 3, 2}
-- rotate_up_vector(3) -- {1, 2, 3}

-------------------------------------------------------------------------
function maths.spiral_archimedes(theta, a, b)
  local r = a + b * theta
  local x = r * math.cos(theta)
  local y = r * math.sin(theta)
  return {x, y, r}
end

-------------------------------------------------------------------------
return maths

