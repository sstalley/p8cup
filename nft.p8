pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--game logic

offsetx=32
offsety=32
mapw=8
maph=8
hidden = {}
tedges=0
aniitvl=0.25  --tree frame time
samples=0
flashitvl=0.5 --period of flash
flashpcnt=0.1 --how long to flash
movedtime=0.4 --time for drone to move
tbatt = 100 -- total battery
nmaps = 3 -- how many maps
mapxoffset = 9
mapx=0
mapn=-1 --starting map-1

function resetmap()
 for col=0,mapw-1 do
  hidden[col] = {}
  for row =0,maph-1 do
   hidden[col][row] = true
  end
 end
 fedges = 0
 samples = 0
 tdist = 0
 batt = tbatt
 done = false
 playing = false

end

function totaledges()
 tedges = 0
 --horizontal edges
 for col=mapx,mapx+mapw-1 do
  for row=0,maph-2 do
   if mget(col,row) != mget(col,row+1) do
    tedges += 1
   end
  end
 end
 
 --vertical edges
 for col=mapx,mapx+mapw-2 do
  for row=0,maph-1 do
   if mget(col,row) != mget(col+1,row) do
    tedges += 1
   end   
  end
 end
  
 return tedges

end

function _init()
 cy=5
 cx=0
 done = false
 droney = cy
 dronex = cx
 movedstart = 0
 mapn = (mapn + 1) % nmaps
 mapx = mapn * mapxoffset
 tedges = totaledges()
 resetmap()
 unhide(cx+1, cy)
 unhide(cx, cy)
 updatesamples()
 cup_init()

end

function updateedges()
 fe = 0
 --horizontal edges
 for col=0,mapw-1 do
  for row=0,maph-2 do
   f1 = not hidden[col][row]
   f2 = not hidden[col][row+1]
   diff = mget(col+mapx,row) != mget(col+mapx,row+1)
   if f1 and f2 and diff do
    fe += 1
   end
  end
 end
 
 --vertical edges
 for col=0,mapw-2 do
  for row=0,maph-1 do
   f1 = not hidden[col][row]
   f2 = not hidden[col+1][row]
   diff = mget(col+mapx,row) != mget(col+1+mapx,row)
   if f1 and f2 and diff do
    fe += 1
   end   
  end
 end
 
 if fe == tedges do
  done = true
 end
 fedges = fe
end

function updatesamples()
 s = 0
 for col=0,mapw-1 do
  for row=0,maph-1 do
   if not hidden[col][row] do
    s += 1
   end
  end
 end
 samples = s
end

function unhide(x, y)
 hidden[x][y] = false
 updateedges()
 updatesamples()
end

function dist(x1, y1, x2, y2)
 dx = x2 - x1
 dy = y2 - y1
 return sqrt(dx*dx + dy*dy)
end

function movedrone(x, y)
 newdx=x
 newdy=y
 movedstart=time()
 tdist += dist(dronex, droney, x, y)
 batt = tbatt - (tdist + samples)/2
end

function checkmove(x,y)
 if not hidden[x][y] or movedstart != 0 then
  return
 end
 movedrone(x, y) 
end

function _update()
 if playing then
  player_update()
 else
  demo_update()
 end
end

function demo_update()
 if movedstart == 0 then
  loc = next_cup_loc()
  printh('new loc:('..loc[1]..', '..loc[2]..')', 'cuplog')
  checkmove(loc[1], loc[2])
 end
 if btnp(🅾️) then
  _init()
  playing=true
 end
end

function player_update()
 if btnp(⬅️) then cx=(cx-1)%mapw end
 if btnp(➡️) then cx=(cx+1)%mapw end
 if btnp(⬆️) then cy=(cy-1)%maph end
 if btnp(⬇️) then cy=(cy+1)%maph end
 if btnp(❎) then checkmove(cx, cy) end
 if btnp(🅾️) then _init() playing=false end

end
-->8
-- ai for cup

-- used to figure out what way to turn
coffsets = {{0,0},{0,1},{1,1},{1,0}}

-- where are my neighbors?
cneighbors = {{0,1},{1,0},{0,-1},{-1,0}}

--sets the coordinates of the 2x2 cell containing a & b
function set_cell()
 cellx = min(ax, bx)
 celly = min(ay, by)
 --b above so check backwards
 if ax == bx and ay > by then
   cellx -=1
 --b after so check above
 elseif ay == by and ax < bx then
   celly -=1
 end
   
end

function cup_init()
 ax = dronex
 ay = droney
 -- find b
 for i, neig in ipairs(cneighbors) do
   local nx = ax+neig[1]
   local ny = ay+neig[2]
   printh('local nx:'..nx, 'log')
   printh('local ny:'..ny, 'log')

   --for j, h in pairs(hidden) do 
   -- printh('j:'..j, 'log')
   -- for k, hi in pairs(h) do
   --  printh('hidden('..j..', '..k..'):'..(hi and 't' or 'f'), 'log')
   -- end   
   --end
   local skip = false
   if nx < 0 or nx > mapw then
    skip = true
   elseif ny < 0 or ny > maph then
    skip = true
   end
   
   if not skip and not hidden[nx][ny] then 
    printh('setting b...', 'log')

    bx = ax + neig[1]
    by = ay + neig[2]
  end
 end
 set_cell()
end

function update_cup(x, y)
 a = mget(mapx+ax,ay)
 b = mget(mapx+bx,by)
 c = mget(mapx+x,y)
 if a == c then
  ax = x
  ay = y
 elseif b == c then
  bx = x
  by = y
 end
 set_cell()
end

function next_cup_loc()

 -- may need to update a&b here 

 -- find closest unsampled locaiton in cell
 best_dist = 99
 for i, ofst in pairs(coffsets) do
  cx = cellx + ofst[1]
  cy = celly + ofst[2]
  printh('checking ('..cx..', '..cy')', 'cuplog')

  cd = dist(cx, cy, dronex, droney)
  if hidden[cx][cy] and cd < best_dist then
   printh('new best_dist'..cd, 'cuplog')
   best_ofst = ofst
   best_dist = cd
  end 
 end
 x = cx+best_ofst[1]
 y = cy+best_ofst[2]
 
 
 return {x, y}
end
-->8
--draw calls

function drawedges()

 --horizontal edges
 for col=0,mapw-1 do
  for row=0,maph-2 do
   f1 = not hidden[col][row]
   f2 = not hidden[col][row+1]
   diff = mget(mapx+col,row) != mget(mapx+col,row+1)
   if f1 and f2 and diff do
    spr(6,offsetx+col*8, offsety+row*8+4)
   end
  end
 end
 
 --vertical edges
 for col=0,mapw-2 do
  for row=0,maph-1 do
   f1 = not hidden[col][row]
   f2 = not hidden[col+1][row]
   diff = mget(mapx+col,row) != mget(mapx+col+1,row)
   if f1 and f2 and diff do
    spr(5,offsetx+col*8+4, offsety+row*8)
   end   
  end
 end

end

function drawcurse()
 spr(4, offsetx+cx*8, offsety+cy*8)
end

function drawcell()
 -- cell
 spr(17, offsetx+ cellx   *8, offsety+ celly   *8)
 spr(17, offsetx+(cellx+1)*8, offsety+ celly   *8, 1, 1, true)
 spr(17, offsetx+(cellx+1)*8, offsety+(celly+1)*8, 1, 1, true,  true)
 spr(17, offsetx+ cellx   *8, offsety+(celly+1)*8, 1, 1, false, true)

 -- a & b
 spr(18, offsetx+ax*8, offsety+ay*8)
 spr(19, offsetx+bx*8, offsety+by*8)

end

function drawdrone()
 ts = (time() / flashitvl) % 2

 if 0 < ts and ts < flashpcnt then
  dspr=16
 elseif 1 < ts and ts < 1+flashpcnt then
  dspr=32
 else
  dspr=0
 end

 x = offsetx+dronex*8
 y = offsety+droney*8
 
 if movedstart > 0 then
  pcnt = (time() - movedstart)/movedtime
  nx = offsetx+newdx*8
  ny = offsety+newdy*8
  if pcnt >= 1 then -- we are done
   dronex = newdx
   droney = newdy
   movedstart = 0
   unhide(dronex, droney)
   if not playing then
    update_cup(dronex, droney)
   end
 
  end
  x = x * (1-pcnt) + nx * pcnt
  y = y * (1-pcnt) + ny * pcnt
 end
 
 spr(dspr, x, y)
end

function drawmap()
 for col=0,mapw-1 do
  for row =0,maph-1 do
   
   if done do
    treespr=mget(col+mapx, row)
    if treespr == 2 do
      treespr = 3
    end
   elseif hidden[col][row] do
    treespr=3
   else
    treespr=mget(col+mapx, row)
   end
   --flip the trees every few frames
   flipx = (time() / aniitvl) % 2 > 1
   spr(treespr, offsetx+col*8, offsety+row*8, 1, 1, flipx)
  end
 end
end

function _draw()
 cls()
 drawedges()
 drawmap()
 if playing then
  drawcurse()
 else
  drawcell()
 end
 
 drawdrone()
 print('edges:   '..fedges..'/'..tedges,16, 1, 12)
 print('samples: '..samples, 16, 1+6, 9)
 print('distance:'..tdist, 16, 1+2*6, 8)
 print('battery: '..batt..'%', 16, 1+3*6, 11)
 if movedstart > 0 then
  prompt = 'drone moving...'
 else
  prompt = 'select a sample location'
 end
 print(prompt, 16, 100, 7) 
 print('stalley et al. 2022', 16, 122, 7)
end
__gfx__
000000000003300000098000000dd00022000022000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000003300000089000000dd00020000002000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00b00003333000089a80000dddd0000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000333300009a890000dddd0000000000000cc000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
000770000333333009a89a800dddddd000000000000cc000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
0080080000044000000440000005500000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000440000005500020000002000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000022000022000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222200220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa020000000000cc000000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa02000000000cccc0000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000200000000cccccc00eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000cccccc00eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008008000000000000cccc0000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000020000000000cc000000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101000101010101010101000101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202010101000102020202020201000102020101020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020101000102010101010101000102020101020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020101000102020202020201000102020101020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202010101000101010101010201000102020101020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020101010101000102020202020201000102020202020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020101010101000101010101010101000101020202020101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101000101010101010101000101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
