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

function updatePort42(data)
 local d1, d2, d3, d4, d5, d6, d7 = table.unpack(data)
  if d1 == "ping" then
   print ("Received ping on port: " .. port)
   netp42:send(sender, port, "pong")
  elseif d1 == "container" then
   containersPort42[d2] = d3
   print(table.unpack(data))
  elseif d1 == "factory" then
   factoriesPort42[d2] = d3
   print(table.unpack(data))
  end
end

function updateScreen()
 clearScreen(gpu)
 local row = 0

 gpu:setBackground(0, 1.0, 0.5, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, row, string.format("%-59s", "Atomic Bay Monitoring")) --55 chars (padded with spaces after)
 row = row + 1

 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, row, string.format("%-54s", "Factories Output Status")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 row = row + 1
 for n, m in pairs(factoriesPort42) do
  gpu:setText(1, row, n .. m)
  row = row + 1
 end

 row = row + 1
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, row, string.format("%-54s", "Container Inventory")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 row = row + 1
 for n, m in pairs(containersPort42) do
  gpu:setText(1, row, string.format("%-20s", n) .. string.format("%3s", m) .. "%")
  row = row + 1
 end
 
 row = row + 1
 gpu:setText(0, row, "Time: " .. convertToTime(computer.millis()))
 gpu:flush()
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("AB23A01048A8DA61D40B91AE992645F3")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(120, 30)
clearScreen(gpu)

local netp42 = computer.getPCIDevices(findClass("NetworkCard"))[1]
if not netp42 then error("No network card") end

event.ignoreAll()
event.clear()
event.listen(netp42)
netp42:open(42)

print("Opened port")

containersPort42 = {}
factoriesPort42 = {}

while true do
 local data = {event.pull()}
 e, receiver, sender, port, data = (function(e, receiver, sender, port, ...)
  return e, receiver, sender, port, {...}
 end) (table.unpack(data))

 if e == "NetworkMessage" then
  if (port == 42) then updatePort42(data) end
  updateScreen()
 end
end