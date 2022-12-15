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

function displayContainers()
 local containers = component.proxy(component.findComponent("STORAGE"))
 if not containers then error("Containers was nil") end
 print("Number of containers: " .. tableLength(containers))
 if (tableLength(containers) == 0) then return end

 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 11, string.format("%-54s", "Container Inventory")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local row = 12
 for _, cntr in pairs(containers) do
  --print ("Type: " .. cntr:getType().displayName)
  local invs = cntr:getInventories()[1]
  local count = 0
  local max = -1
  local name = cntr.nick:sub(9)
  local i = 0

  while (i < invs.Size) do
   local t = nil
   local stack = invs:getStack(i)
   if (stack.item) then t = stack.item.type end
   if(t) then
    count = count + stack.count
    max = t.max * invs.Size
   end
   i = i + 1
  end --while

  local percentage = math.floor(count / max * 100)
  gpu:setText(1, row, string.format("%-20s", name) .. string.format("%3s", percentage) .. "%")
  net:broadcast(port, "container", name, percentage)
  row = row + 1
 end --for
end

function displayFactories()
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-54s", "Factories Output Status")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local factories = component.proxy(component.findComponent("ATOMICBAY"))
 if not factories then error("Factories was nil") end
 print("Number of factories: " .. tableLength(factories))

 local row = 0
 for _, fctry in pairs(factories) do
  local output = " -> "
  row = row + 1
  local invs
  if (fctry:getType().Name == "Build_GeneratorNuclear_C") then
   invs = fctry:getInventories()[1]
  else
   invs = fctry:getOutputInv()
  end
  --print(fctry:getType().Name .. " " .. fctry.nick .. " " .. invs.Size)
  local i = 0

  while (i < invs.Size) do
   local t = nil
   local stack = invs:getStack(i)
   if (stack.item) then t = stack.item.type end
   if (t) then
    local c = stack.count
    local m = t.max
    local n = t.name
    output = output .. n .. ": " .. c .. "/" .. m
   else
    output = output .. "empty"
   end --if   
   i = i + 1
   if (i < invs.Size) then output = output .. " | " end
  end --while
  
  local name = fctry.nick:sub(11) --removes "ATOMICBAY "
  gpu:setText(1, row, (name .. output))
  net:broadcast(port, "factory", name, output)
 end --for
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("3A9AEF754BD02F4E2491C6B1949870CE")
if not screen then error("No screen") end

net = computer.getPCIDevices(findClass("NetworkCard"))[1]
if not net then error("No network card") end

port = 42

gpu:bindScreen(screen)
gpu:setSize(55, 25)

while true do
 clearScreen(gpu)
 displayFactories()
 displayContainers()
 gpu:setText(0, 24, "Time: " .. convertToTime(computer.millis()))
 gpu:flush()
 event.pull(5)
end
