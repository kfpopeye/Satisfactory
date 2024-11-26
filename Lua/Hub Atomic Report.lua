-- -------------------------------------------------------------
-- |                                                           |
-- |   Hub atomic report.lua                                   |
-- |                                                           |
-- -------------------------------------------------------------
computer.log(1, "--- Atomic Atomic Report v1.1 ---")

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
  if (fact[n]["productivity"] < 50) then
    g:setForeground(1,0,0,1)
  elseif (fact[n]["productivity"] < 75) then
    g:setForeground(1,1,0,1)
  end
  g:setText(col + 1, row, n .. prod .. fact[n]["outputs"])
  row = row + 1
  local indent = " "
  while (indent:len() < (n:len() + prod:len())) do indent = indent .. " " end
  g:setText(col + 1, row, indent .. fact[n]["inputs"])
  g:setForeground(1,1,1,1)
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
  if (row > 33) then
   g:setText(col + 1, 33, "list truncated")
  else
   g:setText(col + 1, row, string.format("%-20s", n) .. string.format("%3s", cont[n]) .. "%")
   row = row + 1
  end
 end
  
 g:flush()
end

-- ***************** main loop ********************
function mainLoop()
	while true do
	 local data = {event.pull()}
	 e, receiver, sender, port, data = (function(e, receiver, sender, port, ...)
	 return e, receiver, sender, port, {...}
	 end) (table.unpack(data))

	 if e == "NetworkMessage" then
	  print("Updating data from port: " .. port)
	  if (port == 42) then
	   lastUpdateTime["Atomic Bay"] = computer.millis()
	   updateData(data, containersPort42, factoriesPort42, reactorsPort42)
	   updateScreen(gpu1, containersPort42, factoriesPort42, reactorsPort42, "Atomic Bay")
	  elseif (port == 43) then
	   lastUpdateTime["Atomic Cave"] = computer.millis()
	   updateData(data, containersPort43, factoriesPort43, reactorsPort43)
	   updateScreen(gpu2 , containersPort43, factoriesPort43, reactorsPort43, "Atomic Cave")
	  elseif (port == 44) then
	   lastUpdateTime["Atomic Waterfall"] = computer.millis()
	   updateData(data, containersPort44, factoriesPort44, reactorsPort44)
	   updateScreen(gpu3, containersPort44, factoriesPort44, reactorsPort44, "Atomic Waterfall")
	  elseif (port == 45) then
	   lastUpdateTime["Atomic Alcove"] = computer.millis()
	   updateData(data, containersPort45, factoriesPort45, reactorsPort45)
	   updateScreen(gpu4, containersPort45, factoriesPort45, reactorsPort45, "Atomic Alcove")
	  end 
	  if lastUpdateTime["Atomic Bay"] then	  
	   if updateTimeLimit < computer.millis()-lastUpdateTime["Atomic Bay"] then
	   	gpu1:setForeground(1,0,0,1) --red
	   end	   
	   gpu1:setText(0, 34, "Last update: " .. computer.millis()-lastUpdateTime["Atomic Bay"] .. "ms")
	   gpu1:setForeground(1,1,1,1)
	   gpu1:flush()
	  else  
	   gpu1:setText(0, 34, "Last update: ---------- ms")
	   gpu1:flush()
	  end
	  if lastUpdateTime["Atomic Cave"] then
	   if updateTimeLimit < computer.millis()-lastUpdateTime["Atomic Cave"] then
	   	gpu2:setForeground(1,0,0,1) --red
	   end	
	   gpu2:setText(0, 34, "Last update: " .. computer.millis()-lastUpdateTime["Atomic Cave"] .. "ms")
	   gpu2:setForeground(1,1,1,1)
	   gpu2:flush()
	  else  
	   gpu2:setText(0, 34, "Last update: ---------- ms")
	   gpu2:flush()
	  end
	  if lastUpdateTime["Atomic Waterfall"] then
	   if updateTimeLimit < computer.millis()-lastUpdateTime["Atomic Waterfall"] then
	   	gpu3:setForeground(1,0,0,1) --red
	   end
	   gpu3:setText(0, 34, "Last update: " .. computer.millis()-lastUpdateTime["Atomic Waterfall"] .. "ms")
	   gpu3:setForeground(1,1,1,1)
	   gpu3:flush()
	  else  
	   gpu3:setText(0, 34, "Last update: ---------- ms")
	   gpu3:flush()
	  end
	  if lastUpdateTime["Atomic Alcove"] then
	   if updateTimeLimit < computer.millis()-lastUpdateTime["Atomic Alcove"] then
	   	gpu4:setForeground(1,0,0,1) --red
	   end
	   gpu4:setText(0, 34, "Last update: " .. computer.millis()-lastUpdateTime["Atomic Alcove"] .. "ms")
	   gpu4:setForeground(1,1,1,1)
	   gpu4:flush()
	  else  
	   gpu4:setText(0, 34, "Last update: ---------- ms")
	   gpu4:flush()
	  end
	 end
	end
end

-- ***************** globals ********************
containersPort42 = {}
factoriesPort42 = {}
reactorsPort42 = {}
containersPort43 = {}
factoriesPort43 = {}
reactorsPort43 = {}
containersPort44 = {}
factoriesPort44 = {}
reactorsPort44 = {}
containersPort45 = {}
factoriesPort45 = {}
reactorsPort45 = {}
lastUpdateTime = {}

--number of milliseconds that are allowed to pass before warning is issued
updateTimeLimit = 10000

-- ***************** devices ********************
local gpus = computer.getPCIDevices(classes.GPUT1)
if tableLength(gpus) == 0 or tableLength(gpus) < 0 then error("GPU T1 count error!") end
local screens = component.findComponent(classes.Build_Screen_C)
if tableLength(screens) == 0 or tableLength(screens) < 4 then error("Screens count error!") end
if not tableLength(screens) == tableLength(gpus) then error("Gpu to screens count mismatch!") end

gpu1 = gpus[1]
gpu1:bindScreen(component.proxy(screens[1]))
gpu1:setSize(60, 35)
clearScreen(gpu1)
updateScreen(gpu1, containersPort42, factoriesPort42, reactorsPort42, "Atomic Bay")
gpu1:flush()


gpu2 = gpus[2]
gpu2:bindScreen(component.proxy(screens[2]))
gpu2:setSize(60, 35)
clearScreen(gpu2)
updateScreen(gpu2 , containersPort43, factoriesPort43, reactorsPort43, "Atomic Cave")
gpu2:flush()

gpu3 = gpus[3]
gpu3:bindScreen(component.proxy(screens[3]))
gpu3:setSize(60, 35)
clearScreen(gpu3)
updateScreen(gpu3, containersPort44, factoriesPort44, reactorsPort44, "Atomic Waterfall")
gpu3:flush()

gpu4 = gpus[4]
gpu4:bindScreen(component.proxy(screens[4]))
gpu4:setSize(60, 35)
clearScreen(gpu4)
updateScreen(gpu4, containersPort45, factoriesPort45, reactorsPort45, "Atomic Alcove")
gpu4:flush()

local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then error("No network card") end

event.ignoreAll()
event.clear()
event.listen(net)
net:open(42)
net:open(43)
net:open(44)
net:open(45)
print("Opened ports")

--call main loop
print("Calling main loop")
local status, err = pcall(mainLoop)
if not status then
 print(err)
 computer.beep()
 computer.beep()
end
