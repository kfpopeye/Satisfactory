-- -------------------------------------------------------------
-- |                                                           |
-- |   light.lua                                               |
-- |                                                           |
-- -------------------------------------------------------------
computer.log(1, "--- Power Monitor v1.0---")

gridName = "Northern Desert"
if gridName == "" then error("Forgot to set grid name.") end

--Verbosity is 0 debug, 1 info, 2 warning, 3 error and 4 fatal
function pdebug(msg) if (debug) then computer.log(0, msg) end end
function pinfo(msg) computer.log(1, msg) end
function pwarn(msg) computer.log(2, msg) end
function perror(msg) computer.log(3, msg) error(msg) end
function pfatal(msg) computer.log(4, msg) end

function clearScreen(g)
 local w,h = g:getSize()
 g:setBackground(0, 0, 0, 0)
 g:setForeground(1, 1, 1, 1)
 g:fill(0, 0, w, h, " ")
end

function convertToTime(ms)
 local tenths = ms // 100
 local hh = (tenths // (60 * 60 * 10)) % 24
 local mm = (tenths // (60 * 10)) % 60
 local ss = (tenths // 10) % 60
 local t = tenths % 10
 return string.format("%02d:%02d:%02d.%01d", hh, mm, ss, t)
end

function updateScreen()
 if (hasScreen) then
  updateScreenTab()
 else
  logInfo()
 end
end

function logInfo()
 pinfo("------------Energy Production this session----------------")
 pinfo("Total session time: " .. convertToTime(computer.millis()))
 pinfo("Maximum power produced: " .. string.format("%.2f", productionMax))
 pinfo("Minimum power produced: " .. string.format("%.2f", productionMin))
 if (circuit.hasBatteries) then
  pinfo("Maximum battery capacity: " .. string.format("%.2f", circuit.batteryCapacity))
  pinfo("Current battery storage: " .. string.format("%.2f", circuit.batteryStore))
 else
  pinfo("No batteries detected.")
 end
end

function updateScreenTab()
 clearScreen(gpu)
 gpu:setBackground(0, 0, 0, 0)
 gpu:setForeground(1, 1, 1, 1)
 gpu:setText(0, 0, "------------Energy Production this session----------------")
 gpu:setText(0, 1, "Total session time: " .. convertToTime(computer.millis()))
 gpu:setText(0, 2, "Maximum power produced: " .. string.format("%.2f", productionMax))
 gpu:setText(0, 3, "Minimum power produced: " .. string.format("%.2f", productionMin))
 if (circuit.hasBatteries) then
  gpu:setText(0, 5, "Maximum battery capacity: " .. string.format("%.2f", circuit.batteryCapacity))
  gpu:setText(0, 6, "Current battery storage: " .. string.format("%.2f", circuit.batteryStore))
 else
  gpu:setText(0, 5, "No batteries detected.")
 end
 gpu:flush()
end

function main()
 while true do
  event.pull(5.0)
  circuit = light:getPowerConnectors()[1]:getCircuit()
  if (not circuit) then error("Circuit was nil") end

  if (circuit.hasBatteries) then
   if (circuit.batteryStorePercent <= 0.75) then
    light.colorSlot = 1 --red
    computer.textNotification ("Batteries are running low at " .. gridName, "KFpopeye")
   elseif (circuit.batteryStorePercent < 1.0) then
    light.colorSlot = 2 --yellow
   else
    light.colorSlot = 3 --green
   end
  end

  if (circuit.production > productionMax) then productionMax = circuit.production end
  if (circuit.production < productionMin) then productionMin = circuit.production end
  updateScreen()

  pinfo(computer.millis() .. " " .. circuit.batteryStorePercent * 100 .. "%")
 end
end

--main chunk
hasScreen = false
local tabScreen = computer.getPCIDevices(classes.FINComputerScreen)[1] 
if not tabScreen then pwarn("No Screen tab found!") end
gpu = computer.getPCIDevices(classes.GPUT1)[1]
if not gpu then pwarn("No GPU T1 found!") end

if(tabScreen and gpu) then
 gpu:bindScreen(tabScreen)
 gpu:setSize(120, 50)
 pinfo("Found screen tab and GPU")
 hasScreen = true
end

light = component.proxy("64E8DCDF43E41D5CC037F5BD9E2E00AB")
if not light then perror("No light found!") end
light.colorSlot = 0 --white
light.isLightEnabled = true
light.isTimeOfDayAware = false
light.intensity = 100.0

circuit = light:getPowerConnectors()[1]:getCircuit()
if (not circuit) then error("Circuit was nil") end
productionMax = circuit.production
productionMin = circuit.production
local status, err = pcall(main)
if not status then
 light.colorSlot = 0
 print(err)
end
