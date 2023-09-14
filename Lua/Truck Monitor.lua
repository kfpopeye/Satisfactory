function clearScreen(g)
 local w,h = g:getSize()
 g:setForeground(1,1,1,1)
 g:setBackground(0,0,0,0)
 g:fill(0,0,w,h," ")
 g:flush()
end

function convertToTime(ms)
 if(not ms) then print ("convertToTime() received nil") end
 if ms < 0 then ms = 0 end
 local tenths = ms // 100
 local hh = (tenths // (60 * 60 * 10)) % 24
 local mm = (tenths // (60 * 10)) % 60
 local ss = (tenths // 10) % 60
 local t = tenths % 10
 return string.format("%02d:%02d:%02d.%01d", hh, mm, ss, t)
end

function printReports()
 clearScreen(gpu)
 local row = 0

 for _, v in pairs(vehicles) do  
  print(v["scanner"] .. " : " .. v["percent"] .. "% full")
  gpu:setText(0, row, v["scanner"])
  row = row + 1
   if (v["lastTripTime"] < 100) then
   gpu:setText(1, row, v["percent"] .. "% full. Trip time: N\\A")
  else
   gpu:setText(1, row, v["percent"] .. "% full. Trip time: " .. convertToTime(v["lastTripTime"]))
  end
 
  for n, c in pairs(v["report"]) do
   row = row + 1
   gpu:setText(2, row, n .. ": " .. c)
  end
  row = row + 2
 end
 gpu:flush()
end

function updateVehicle(v, scanner)
 if (vehicles[v.hash] == nil) then
  local data = {}
  data["lastTrip"] = computer.millis()
  data["scanner"] = scanner.nick
  vehicles[v.hash] = data
 end

 local inv = v:getStorageInv()
 local count = 1
 local stackCount = 0
 local report = {}
 while (count < inv.size) do
  local t = nil
  local s = inv:getStack(count)
  if (s.item) then t = s.item.type end
  if(t) then
   stackCount = stackCount + 1
   local c = s.count
   local name = t.name
   if(report[name]) then
    report[name] = report[name] + c
   else
    report[name] = c
   end
  end
  count = count + 1
 end  --end while
 vehicles[v.hash]["report"] = report
 vehicles[v.hash]["percent"] = stackCount / inv.size * 100
 vehicles[v.hash]["lastTripTime"] = computer.millis() - vehicles[v.hash]["lastTrip"]
 printReports()
 vehicles[v.hash]["lastTrip"] = computer.millis()
end

function mainLoop()
 print("Looping")
 while(true) do
  e, sender, veh = event.pull(0)
  if (e == "OnVehicleEnter") then
   if(veh.isSelfDriving) then updateVehicle(veh,sender) end
   sender:setColor(1, 0, 0, 1)
   if(not veh.isSelfDriving) then print ("Vehicle was not self driving.") end
   computer.beep()
  elseif (e == "OnVehicleExit") then
   sender:setColor(1, 0, 0, 0) 
  end
 end
end

-- ********************* Globals ******************
vehicles = {}

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("9F80B1FD4D6D92754BF44B88A421EAB8")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(50, 20)
clearScreen(gpu)

ts1 = component.proxy("4AA24AF14328B63152360BA5A69AC8F8")
if not ts1 then error("Truckstop 1 is missing") end

ts2 = component.proxy("106C4BF2436BAF5583FD04ABEA480F9B")
if not ts2 then error("Truckstop 2 is missing") end

event.listen(ts1)
event.listen(ts2)
event.clear()

--start refilling containers
local status, err = pcall(mainLoop)
if not status then
 print(err)
 computer.beep()
 computer.beep()
end
