-- Using 1D index for 2D here
-- z3  09  10  11  12
-- z2  05  06  07  08
-- z1  01  02  03  04
--     x1  x2  x3  x4
-- move1 xp i+1  | move2 xn i-1
-- move3 zp i+nx | move4 zn i-nx

-------------------------------------------------------------------------
-- define movements and grid coordinates
-------------------------------------------------------------------------
local function gen_grid_xz(nx, nz, dx)
  local grid = {}
  local coordx, coordz = 0, 0
  for z = 1, nz do
    coordx = 0 --!!
    for x = 1, nx do
      table.insert(grid, {x=coordx, y=0, z=coordz})
      coordx = coordx + dx
    end
    coordz = coordz + dx
  end
  return grid
end

local def_moves = {}
def_moves[1] = function(i, nx) return i + 1  end
def_moves[2] = function(i, nx) return i - 1  end
def_moves[3] = function(i, nx) return i + nx end
def_moves[4] = function(i, nx) return i - nx end

local function valid_move(id, id2, nx, nz)
  -- outside range
  if id2 < 1 or id2 > nx*nz then return false end
  -- right edge, nx multipples, no +1 allowed
  if id%nx == 0 and id2 == id+1 then return false end
  -- left edge, nx multipples +1, no -1 allowed
  if id%nx == 1 and id2 == id-1 then return false end
  -- finally all test passed
  return true
end

-------------------------------------------------------------------------
-- some helper functions
-------------------------------------------------------------------------
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(1, i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

local function shuffled_copy(tbl)
  local copy = {}
  for i, v in ipairs(tbl) do
    copy[i] = v
  end
  shuffle(copy)
  return copy
end

local function contains(t, a)
  for _, v in ipairs(t) do
    if v == a then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------
-- all about digging or building, then the maze function
-------------------------------------------------------------------------
local function safe_remove(pos)
  --WARNING[Server]: Map::getNodeMetadata(): Block not found
  --to handle that warning, ensure the block exists
  local node = minetest.get_node_or_nil(pos)
  if node then
    -- local meta = minetest.get_meta(pos)
    minetest.remove_node(pos)
  else
    minetest.debug("load:" .. minetest.pos_to_string(pos))
    minetest.load_area(vector.subtract(pos, 8), vector.add(pos, 8))
    minetest.remove_node(pos)
  end
end

local function dig_tunnel(p1, p2, H, W, extra)
  local dist = vector.distance(p1, p2)
  local dir = vector.direction(p1, p2) --normalized
  local step = 0.5 --config
  H = H - 1
  W = W - 1
  -- handle extra depth for smooth corner
  if extra then
    p1 = p1 - (0.5*W) * dir
    p2 = p2 + (0.5*W) * dir
    dist = dist + W
  end
  -- Choose any non-parallel vector
  local up = vector.new(0, 1, 0)
  if math.abs(dir.x) < 0.001 and math.abs(dir.z) < 0.001 then
    -- x,z small, y big, almost parallel
    minetest.debug("for vertical tunnel use build_cuboid")
    return false
  end
  -- vector pointing to the right hand side, horizontally
  local rhs = vector.normalize(vector.cross(dir, up))
  -- do the loops...
  for dp = 0, dist, step do
    for dy = 0, H, step do
      for ds = -0.5*W, 0.5*W, step do --s: side
        local p = p1 + dp*dir + dy*up + ds*rhs
        safe_remove(p)
      end
    end
  end
  -- minetest.debug("done digging tunnel")
  return true
end

--recursive backtracking, depth first search
local function carve_maze(id, visited, nx, nz, grid)
  table.insert(visited, id)
  local random_moves = shuffled_copy(def_moves)
  for _, m in ipairs(random_moves) do
    local id2 = m(id, nx)
    -- minetest.debug('carve_maze: id2 = ' .. id2)
    if valid_move(id, id2, nx, nz) and not contains(visited, id2) then
      --set nodes here to air from grid[id] to grid[id2]
      --minetest.debug('digging:'..tostring(id).."-->"..tostring(id2))
      --build_cuboid( grid[id], grid[id2] + {x=0,y=-2,z=0}, 'air')
      --tunnel H and W hard coded here, dont want too many args
      dig_tunnel(grid[id], grid[id2], 5, 4, true) --config
      carve_maze(id2, visited, nx, nz, grid)
    end 
  end
end

-------------------------------------------------------------------------
-- more digging / building, ball, cuboid...
-------------------------------------------------------------------------
local function dig_ball(origin, radius)
  -- remove center
  safe_remove(origin)
  for r = 1, radius, 0.5 do
    local l = 2 * math.pi * r
    local n = math.ceil(l) * 2
    local step = 2*math.pi / n
    -- local v = vector.zero()
    -- minetest.debug('r='..tostring(r)..' n='..tostring(n))

    for ah = 0, 2*math.pi, step do
      -- for av = 0, 2*math.pi, 2*math.pi/n do
      for av = -math.pi/2, math.pi/2, step do
        local v = {
          x = r * math.cos(av) * math.cos(ah),
          y = r * math.sin(av),
          z = r * math.cos(av) * math.sin(ah)
        }
        safe_remove(origin + v)
        -- build ball here with other material possible
      end
    end
  end
end

local function build_cuboid(pos1, pos2, material)
  local minp = {
    x = math.min(pos1.x, pos2.x),
    y = math.min(pos1.y, pos2.y),
    z = math.min(pos1.z, pos2.z)
  }
  local maxp = {
    x = math.max(pos1.x, pos2.x),
    y = math.max(pos1.y, pos2.y),
    z = math.max(pos1.z, pos2.z)
  }

  for x = minp.x, maxp.x do
    for y = minp.y, maxp.y do
      for z = minp.z, maxp.z do
        minetest.set_node({x=x, y=y, z=z}, {name=material})
      end
    end
  end
end

local function amazingbase(name, args)
  --dig entrance tunnel
  local entr_v = vector.new(0, -50, 100) --config
  local pos0 = minetest.get_player_by_name(name):get_pos()
  local pos1 = pos0 + entr_v --use as grid[ini] for maze
  local entr_conf = {H = 5, W = 4} --config
  minetest.debug("digging entrance tunnel to the maze...")
  dig_tunnel(pos0, pos1, entr_conf.H, entr_conf.W, false)

  --dig maze as protection level for our base
  local maze_conf = {nx = 5, nz = 5, dx = 20}
  local visited = {}
  local grid = gen_grid_xz(maze_conf.nx, maze_conf.nz, maze_conf.dx)
  math.randomseed(os.time())
  local ini_id = math.random(1, #grid)
  local shift = pos1 - grid[ini_id]
  for i, v in ipairs(grid) do
    grid[i] = v + shift -- +vector.new(0, -1, 0)
  end
  minetest.debug("digging the maze...")
  carve_maze(ini_id, visited, maze_conf.nx, maze_conf.nz, grid)

  --dig exit of the maze that leads to our base ball
  --so 4 corners, find which one is farest from ini
  local corner_ids = { 1, maze_conf.nx,
    (maze_conf.nx * (maze_conf.nz - 1)) + 1, #grid }
  local exit_co = 1 --1 to 4, one of them
  local long_dist = vector.distance(grid[exit_co], grid[ini_id])
  for i, v in ipairs(corner_ids) do
    local idist = vector.distance(grid[v], grid[ini_id])
    if idist > long_dist then exit_co = i end
  end
  local grid_exit = grid[corner_ids[exit_co]]
  local exit_dir = vector.direction(grid[ini_id], grid_exit)
  local exit_conf = { L=100, dy=-20, H=5, W=4 } --config
  local pos_base = (grid_exit +
                    exit_conf.L * exit_dir +
                    vector.new(0, exit_conf.dy, 0) )
  minetest.debug("digging the exit...")
  dig_tunnel(grid_exit, pos_base, exit_conf.H, entr_conf.W, false)

  --dig base at the end
  local base_radius = 30
  minetest.debug("digging the base...")
  dig_ball(pos_base + vector.new(0, base_radius, 0), base_radius)

  return true
end

