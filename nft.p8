pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
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
 cx=1
 done = false
 droney = cy
 dronex = cx
 movedstart = 0
 mapn = (mapn + 1) % nmaps
 mapx = mapn * mapxoffset
 tedges = totaledges()
 resetmap()
 unhide(cx, cy)
 unhide(cx-1, cy)
 updatesamples()
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

function movedrone(x, y)
 newdx=x
 newdy=y
 movedstart=time()
 dx = dronex - x
 dy = droney - y
 tdist += sqrt(dx*dx + dy*dy)
 batt = tbatt - (tdist + samples)/2
end


function _update()
 if btnp(⬅️) then cx=(cx-1)%mapw end
 if btnp(➡️) then cx=(cx+1)%mapw end
 if btnp(⬆️) then cy=(cy-1)%maph end
 if btnp(⬇️) then cy=(cy+1)%maph end
 if btnp(❎) then movedrone(cx, cy) end
 if btnp(🅾️) then _init() end

end

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
 drawcurse()
 drawdrone()
 print('edges:   '..fedges..'/'..tedges,16, 1, 12)
 print('samples: '..samples, 16, 1+6, 9)
 print('distance:'..tdist, 16, 1+2*6, 8)
 print('battery: '..batt..'%', 16, 1+3*6, 11)
 
 print('stalley et al. 2022', 16, 122)
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
