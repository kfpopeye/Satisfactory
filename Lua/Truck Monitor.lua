function wait (a) 
    local sec = tonumber(computer.millis() + (a * 1000)); 
    while (computer.millis() < sec) do 
    end 
end

function clearScreen(g)
 local w,h = g:getSize()
 g:setForeground(1,1,1,1)
 g:setBackground(0,0,0,0)
 g:fill(0,0,w,h," ")
 g:flush()
end

function convertSecToTime(time)
 if(not time) then print ("convertSecToTime() received nil") end
 if time < 0 then time = 0 end
 time = time / ETfactor
 local days = math.floor(time / 86400)
 local hours = math.floor((time % 86400) / 3600)
 local minutes = math.floor(((time % 86400) % 3600) / 60)
 local seconds = math.floor((((time % 86400) % 3600) % 60))
 return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

function loadTruckData()
 local truckFiles = fs.childs("/")
 if (#truckFiles == 1) then
  print("No truck data found but thats OK.")
  return
 end

 for _, tFile in pairs(truckFiles) do
  if (tFile ~= "dev") then
   print("Processing: " .. tFile)
   local vehFile = fs.open("/" .. tFile, "r")
   vehFile:seek("set")
   local veh_hash = tonumber(fs.path(4, tFile))
   local t1 = vehFile:read(999)
   vehFile:close()

   local lines = {}
   local i = 1
   for line in t1:gmatch("([^\n]*)\n?") do
    lines[i] = line
    i = i + 1
   end
   local data = {}
   data["scanner"] = lines[1]
   data["percent"] = tonumber(lines[2])
   data["lastTripTime"] = tonumber(lines[3])
   data["lastTrip"] = tonumber(lines[4])
   vehicles[lines[1]] = data
  end
 end
end

function saveVehicleData(scannerNick)
 if (not hasHDD) then return end

 local vehFile
 local filePath = "/" .. scannerNick .. ".scanner"
 if (fs.exists(filePath)) then
  vehFile = fs.remove(filePath)
 end
 vehFile = fs.open(filePath, "w")

 vehFile:write(vehicles[scannerNick]["scanner"], "\n")
 vehFile:write(vehicles[scannerNick]["percent"], "\n")
 vehFile:write(vehicles[scannerNick]["lastTripTime"], "\n")
 vehFile:write(vehicles[scannerNick]["lastTrip"])
 vehFile:close()
end

function printReports()
 clearScreen(gpu)
 local row = 0
 gpu:setText(0, row, "Times are shown in earth standard.")
 row = row + 1

 for _, v in pairs(vehicles) do  
  gpu:setText(0, row, v["scanner"] .. "   Time since last: " .. convertSecToTime(computer.time() - v["lastTrip"]))
  row = row + 1
  local percent = string.format("%.2f", v["percent"])
  if (v["lastTripTime"] < 10) then
   gpu:setText(1, row, percent .. "% full. Trip time: N\\A")
  else
   gpu:setText(1, row, percent .. "% full. Trip time: " .. convertSecToTime(v["lastTripTime"]))
  end
 
  if (v["report"]) then
   for n, c in pairs(v["report"]) do
    row = row + 1
    gpu:setText(2, row, n .. ": " .. c)
   end
  else
   row = row + 1
   gpu:setText(2, row, "No previous report.")
  end
  row = row + 2
 end
 gpu:flush()
end

function updateVehicle(v, scanner)
 if (vehicles[scanner.nick] == nil) then
  local data = {}
  data["lastTrip"] = computer.time()
  data["scanner"] = scanner.nick
  vehicles[scanner.nick] = data
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

 vehicles[scanner.nick]["report"] = report
 vehicles[scanner.nick]["percent"] = stackCount / inv.size * 100
 vehicles[scanner.nick]["lastTripTime"] = computer.time() - vehicles[scanner.nick]["lastTrip"]
 vehicles[scanner.nick]["lastTrip"] = computer.time() -- GAME time (faster) not real time
 saveVehicleData(scanner.nick)
 print(scanner.nick .. " : " .. vehicles[scanner.nick]["percent"] .. "% full")
end

function mainLoop()
 print("Looping")
 while(true) do
  e, sender, veh = event.pull(1)
  if (e == "OnVehicleEnter") then
   if(veh.isSelfDriving) then
    updateVehicle(veh, sender)
   else
    print ("Vehicle was not self driving.")
   end
   sender:setColor(1, 0, 0, 1)
   computer.beep()
  elseif (e == "OnVehicleExit") then
   sender:setColor(1, 0, 0, 0) 
  end
  printReports()
 end
end

-- ********************* Globals ******************
vehicles = {}
ETfactor = 1

local earthTime = computer.time()
local compTime = computer.millis() / 1000

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
if not ts1 then error("Scanner 1 is missing") end

ts2 = component.proxy("106C4BF2436BAF5583FD04ABEA480F9B")
if not ts2 then error("Scanner 2 is missing") end

event.clear()
event.listen(ts1)
event.listen(ts2)

hasHDD = false
-- Shorten name
fs = filesystem
-- Initialize /dev
if fs.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end
-- find HD
local drive_uuid
for idx, drive in pairs(fs.childs("/dev")) do
 if(drive ~= "serial") then drive_uuid = drive end
end
-- Mount our drive to root
if (drive_uuid) then
 fs.mount("/dev/"..drive_uuid, "/")
end
if(fs.exists("/")) then
 print("Harddrive found. Data will be persistent.")
 hasHDD = true
 loadTruckData()
else
 print("NO harddrive found!")
end

printReports()

wait(5)
ETfactor = ( (computer.time() - earthTime) / ((computer.millis()/1000) - compTime) )
print(ETfactor)

--start refilling containers
local status, err = pcall(mainLoop)
if not status then
 print(err)
 computer.beep()
 computer.beep()
end
