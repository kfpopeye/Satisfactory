-- -------------------------------------------------------------
-- |                                                           |
-- |  train sign.lua                                           |
-- |                                                           |
-- -------------------------------------------------------------
print ("---------- Train Sign v1.6 ----------")

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--120x50 resolution
function print2Tab(trn)
 clearScreen(gpu2)
 gpu2:setBackground(0, 0, 0, 0)
 gpu2:setForeground(1, 1, 1, 1)
 local s = nil
 local numFCars = 0
 for _, rv in pairs(trn:getVehicles()) do
  if rv:getInventories()[1] then numFCars = numFCars + 1 end
 end
 if(trn.isSelfDriving) then
  s = "Train: " .. trn:getName() .. " [" .. numFCars .. " freight cars] (Autopilot: On)"
 else
  s = "Train: " .. trn:getName() .. " [" .. numFCars .. " freight cars] (Autopilot: Off)"
 end
 gpu2:setText(0, 0, s)
 if (trn.hasTimeTable) then
  local t_table = trn:getTimeTable()
  local x = t_table:getCurrentStop()
  if (x == 0 ) then x = t_table.numStops end --t_table:getCurrentStop() returns 0 when at the last station HACK
  if(trn.isDocked) then
   gpu2:setText(0, 1, "Docked at station: " .. t_table:getStops()[x].station.name)
  else
   gpu2:setText(0, 1, "On route from: ".. t_table:getStops()[x].station.name)
   printCargo(trn)
  end
  gpu2:setText(0, 2, "Next station: " .. t_table:getStops()[t_table:getCurrentStop() + 1].station.name)
  local stops = "Schedule: "
  local stops2 = "          -> "
  local maxWidth, _ = gpu2:getSize()
  for x, stn in pairs(t_table:getStops()) do
  	local list = stops .. stn.station.name .. " -> "
	if #list > maxWidth then
		stops2 = stops2 .. stn.station.name .. " -> "
	else
		stops = stops .. stn.station.name .. " -> "
	end
  end
  local l = string.len(stops) - string.len(" -> ") --remove last arrow
  gpu2:setText(0, 3, string.sub(stops, 1, l))
  l = string.len(stops2) - string.len(" -> ") --remove last arrow
  gpu2:setText(0, 4, string.sub(stops2, 1, l))
 end
 gpu2:flush()
end

function printInventory(invs, col, fcar)
 local i = 0
 local row = 8
 local slotsUsed = 0
 gpu2:setText(0, 6, "Inventories ------------------------------------------------------------------------------------------------------------")
 
 if fcar > 4 then
	gpu2:setText(40, 6, "!!!! Train has more than 4 freight cars !!!")
	return
 end
 
 gpu2:setText(col, 7, "Freight Car #" .. fcar .. " -------------")
 if (invs.itemCount > 0) then
  while (i < invs.Size) do
   local t = nil
   local stack = invs:getStack(i)
   if (stack.item) then t = stack.item.type end
   if(t) then
    slotsUsed = slotsUsed + 1
    local c = stack.count
    local m = t.max
    if (t.form == 3) then  --gas
     c = c // 1000
     m = "1600"
    end
    local n = string.sub(t.name, 1, 20)
    gpu2:setText(col, row, n .. ": " .. c .. "/" .. m)
    row = row + 1
   end
   i = i + 1
  end --end while
 else
  gpu2:setText(col, row, "Freight car is empty")
  row = row + 1
 end 
 gpu2:setText(col, row, "  Slots used: " .. slotsUsed .. "/" .. invs.Size)
end

function printCargo(t)
 local dir = 0
 local column = 0
 local fcar = 1
 for _, rv in ipairs(t:getVehicles()) do
  local invs = rv:getInventories()[1]
  if(invs) then
   printInventory(invs, column, fcar)
   column = column + 30
   fcar = fcar + 1
  end
 end
end

--20x3 resolution
function printScreen(str)
 print("Screen output:", str)
 clearScreen(gpu)
 if gpu3 then clearScreen(gpu3) end
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
  
  if gpu3 then
	  gpu3:setBackground(0, 0.5, 1.0, 0.5)
	  gpu3:setForeground(0, 0, 0, 1)
	  gpu3:setText(0, 0, string.sub(line0, 1, (i + 1)))
	  gpu3:setBackground(0, 0, 0, 0)
	  gpu3:setForeground(1, 1, 1, 1)
	  gpu3:setText(0, 1, string.sub(line1, 1, (i + 1)))
	  gpu3:setText(0, 2, string.sub(line2, 1, (i + 1)))
	  gpu3:flush()
  end
  
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

-- ***************** main loop ********************
function mainLoop()
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
end

-- ***************** devices ********************
station = component.proxy(component.findComponent(classes.Build_TrainStation_C)[1])
if not station then error("No station found!") end

local screens = component.findComponent(classes.Build_Screen_C)
if not tableLength(screens) == 0 then error("No screens") end

local gpus = computer.getPCIDevices(classes.GPUT1)
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end
gpu:bindScreen(component.proxy(screens[1]))
gpu:setSize(20, 3)
clearScreen(gpu)

local tabScreen = computer.getPCIDevices(classes.FINComputerScreen)[1]
if not tabScreen then error("No Screen tab found!") end
gpu2 = gpus[2]
if not gpu2 then error("No GPU T1 found!") end

if tableLength(screens) > 1 then
	gpu3 = gpus[3]
	if not gpu3 then error("Not enough GPU T1 found!") end
	gpu3:bindScreen(component.proxy(screens[2]))
	gpu3:setSize(20, 3)
	clearScreen(gpu3)
end

gpu2:bindScreen(tabScreen)
gpu2:setSize(120, 50)
clearScreen(gpu2)

--call main loop
print("Calling main loop")
local status, err = pcall(mainLoop)
if not status then
 print(err)
 computer.beep()
 computer.beep()
end
