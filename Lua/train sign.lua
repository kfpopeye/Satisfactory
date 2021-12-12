--120x30 resolution
function print2Tab(t)
 clearScreen(gpu2)
 gpu2:setBackground(0, 0, 0, 0)
 gpu2:setForeground(1, 1, 1, 1)
 local s = nil
 if(t.isSelfDriving) then
  s = "Train: " .. t:getName() .. " (Autopilot: On)"
 else
  s = "Train: " .. t:getName() .. " (Autopilot: Off)"
 end
 gpu2:setText(0, 0, s)
 local t_table = t:getTimeTable()
 if(t.isDocked and t_table:getStops()) then --time table resets at hub station?
  gpu2:setText(0, 1, "Docked at station: " .. t_table:getStops()[t_table:getCurrentStop()].station.name)
 else
  gpu2:setText(0, 1, "On route")
  printCargo(t)
 end
 gpu2:setText(0, 2, "Next station: " .. t_table:getStops()[t_table:getCurrentStop() + 1].station.name)
 local stops = "Schedule: "
 for _, stn in pairs(t_table:getStops()) do
  stops = stops .. stn.station.name .. " -> "
 end
 gpu2:setText(0, 3, stops)
 gpu2:flush()
end

function printInventory(invs, col)
 local i = 0
 local row = 6
 invs:sort()
 gpu2:setText(0, 5, "Inventories -----------------------------------------------------------------------------------------------")
 while (i < invs.Size) do
  local t = nil
  local stack = invs:getStack(i)
  if (stack.item) then t = stack.item.type end
  if(t) then
   local c = stack.count
   local m = t.max
   local n = string.sub(t.name, 1, 20)
   gpu2:setText(col, row, n .. ": " .. c .. "/" .. m)
   row = row + 1
  end
  i = i + 1
 end
 return row > 6
end

function printCargo(t)
 local dir = 0
 local column = 0
 for _, rv in pairs(t:getVehicles()) do
  if(rv:getInventories()[1]) then
   local invs = rv:getInventories()[1]
   if(invs and invs.Size > 0) then
    if(printInventory(invs, column)) then column = column + 30 end
   end
  end
 end
end

--20x3 resolution
function printScreen(str)
 print("Screen output:", str)
 clearScreen(gpu)
 local line0 = string.format("%-20s", station.name) --20 chars (padded with spaces after)
 local line1 = " Next stop:"
 local line2 = " " .. str
 local i = 0
 while (i < 20) do
  gpu:setBackground(0, 0.5, 1.0, 0.5)
  gpu:setForeground(0, 0, 0, 1)
  gpu:setText(0, 0, string.sub(line0, 1, (i + 1)))
  gpu:setBackground(0, 0, 0, 0)
  gpu:setForeground(1, 1, 1, 1)
  gpu:setText(0, 1, string.sub(line1, 1, (i + 1)))
  gpu:setText(0, 2, string.sub(line2, 1, (i + 1)))
  gpu:flush()
  i = i + 1
  event.pull(0.0625)
 end
end

function clearScreen(g)
 local w,h = g:getSize()
 g:setBackground(0, 0, 0, 0)
 g:setForeground(1, 1, 1, 1)
 g:fill(0, 0, w, h, " ")
end

-- Main chunk
station = component.proxy("A29A211244D1514CEB6C128E2335F462")
if not station then error("No station found!") end

local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("B58895234477BC6EC6C3FCAC68B3A392")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(20, 3)
clearScreen(gpu)

local tabScreen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
if not screen then error("No Screen tab found!") end
gpu2 = gpus[2]
if not gpu then error("No GPU T1 found!") end

gpu2:bindScreen(tabScreen)
clearScreen(gpu2)

while true do
 local train = station:getTrackGraph():getTrains()[1]
 if(not train.isPlayerDriven) then
  local t_table = train:getTimeTable()
  if(t_table:getCurrentStop()) then
   nextStop = t_table:getStops()[t_table:getCurrentStop() + 1].station.name
  else
   nextSop = "Unknown"
  end
  print2Tab(train)
  printScreen(nextStop)
 end
 event.pull(2)
end
