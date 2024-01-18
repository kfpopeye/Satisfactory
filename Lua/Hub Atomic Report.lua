-- -------------------------------------------------------------
-- |                                                           |
-- |   Hub atomic report.lua                                   |
-- |                                                           |
-- -------------------------------------------------------------

function clearScreen(g)
 local w,h = g:getSize()
 g:setBackground(0, 0, 0, 0)
 g:setForeground(1, 1, 1, 1)
 g:fill(0, 0, w, h, " ")
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function tableContains (T, h)
 for _, value in pairs(T) do
  if (value == h) then return true end
 end
 return false
end

function convertToTime(ms)
 local tenths = ms // 100
 local hh = (tenths // (60 * 60 * 10)) % 24
 local mm = (tenths // (60 * 10)) % 60
 local ss = (tenths // 10) % 60
 local t = tenths % 10
 return string.format("%02d:%02d:%02d.%01d", hh, mm, ss, t)
end

function updateData(data, ctable, ftable, rtable)
 local d1, d2, d3, d4, d5, d6, d7 = table.unpack(data)
  if d1 == "container" then
   ctable[d2] = d3
  elseif d1 == "factory" then
   local fdata = {}
   fdata["outputs"] = d3
   fdata["inputs"] = d4
   if(d5) then fdata["productivity"] = d5 else fdata["productivity"] = "--" end   
   ftable[d2] = fdata
  elseif d1 == "reactor" then
   local fdata = {}
   fdata["outputs"] = d3
   fdata["inputs"] = d4
   if(d5) then fdata["productivity"] = d5 else fdata["productivity"] = "--" end   
   rtable[d2] = fdata
  end
end

function updateScreen(g, cont, fact, react, name)
 clearScreen(g)
 local row = 0
 local col = 0

 g:setBackground(0, 1.0, 0.5, 0.5)
 g:setForeground(0, 0, 0, 1)
 g:setText(col, row, string.format("%-59s", name .. " Monitoring")) --55 chars (padded with spaces after)
 row = row + 1

 g:setBackground(0, 0.5, 1.0, 0.5)
 g:setForeground(0, 0, 0, 1)
 g:setText(col, row, string.format("%-54s", "Factories Output\\Input Status")) --55 chars (padded with spaces after)
 g:setBackground(0,0,0,0)
 g:setForeground(1,1,1,1)
 row = row + 1
 if (tableLength(fact) == 0) then g:setText(col + 1, row, "No factories") end

 local list = {}
 for n, m in pairs(fact) do
  table.insert(list, n)
 end
 table.sort(list)

 -- factories
 for _, n in ipairs(list) do
  local prod = "(" .. fact[n]["productivity"] .. "%) "
  g:setText(col + 1, row, n .. prod .. fact[n]["outputs"])
  row = row + 1
  local indent = " "
  while (indent:len() < (n:len() + prod:len())) do indent = indent .. " " end
  g:setText(col + 1, row, indent .. fact[n]["inputs"])
  row = row + 1
 end
 
 row = row + 1
 g:setBackground(0, 0.5, 1.0, 0.5)
 g:setForeground(0, 0, 0, 1)
 g:setText(col, row, string.format("%-54s", "Reactor Status")) --55 chars (padded with spaces after)
 g:setBackground(0,0,0,0)
 g:setForeground(1,1,1,1)
 row = row + 1
  
 --reactors
 for m, n in pairs(react) do
  local prod = "(" .. n["productivity"] .. "%) "
  if (n["productivity"] < 50) then
    g:setForeground(1,0,0,1)
  elseif (n["productivity"] < 75) then
    g:setForeground(1,1,0,1)
  end
  g:setText(col + 1, row, m .. prod .. n["outputs"])
  row = row + 1
  local indent = " "
  while (indent:len() < (m:len() + prod:len())) do indent = indent .. " " end
  g:setText(col + 1, row, indent .. n["inputs"])
  g:setForeground(1,1,1,1)
  row = row + 1
 end
 
 --containers
 row = row + 1
 g:setBackground(0, 0.5, 1.0, 0.5)
 g:setForeground(0, 0, 0, 1)
 g:setText(col, row, string.format("%-54s", "Container Inventory")) --55 chars (padded with spaces after)
 g:setBackground(0,0,0,0)
 g:setForeground(1,1,1,1)
 row = row + 1
 if (tableLength(cont) == 0) then g:setText(col + 1, row, "No containers") end

 list = {}
 for n, m in pairs(cont) do
  table.insert(list, n)
 end
 table.sort(list)

 for _, n in ipairs(list) do
  g:setText(col + 1, row, string.format("%-20s", n) .. string.format("%3s", cont[n]) .. "%")
  row = row + 1
 end
 
 g:setText(0, 33, "Runtime: " .. convertToTime(computer.millis()))
 g:flush()
end

--main chunk
local gpus = computer.getPCIDevices(classes.GPUT1)
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("692B7B7F4400A3996908FFA1A3204A9C")
if not screen then error("No screen1") end

gpu:bindScreen(screen)
gpu:setSize(60, 35)
clearScreen(gpu)

local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then error("No network card") end

event.ignoreAll()
event.clear()
event.listen(net)
net:open(45)
print("Opened ports")

containersPort45 = {}
factoriesPort45 = {}
reactorsPort45 = {}

while true do
 local data = {event.pull()}
 e, receiver, sender, port, data = (function(e, receiver, sender, port, ...)
  return e, receiver, sender, port, {...}
 end) (table.unpack(data))

 if e == "NetworkMessage" then
  print("Updating data from port: " .. port)
  updateData(data, containersPort45, factoriesPort45, reactorsPort45)
  updateScreen(gpu, containersPort45, factoriesPort45, reactorsPort45, "Atomic Alcove")
 end
end
