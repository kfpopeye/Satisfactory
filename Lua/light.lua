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
 clearScreen(gpu)
 gpu:setBackground(0, 0, 0, 0)
 gpu:setForeground(1, 1, 1, 1)
 gpu:setText(0, 0, "------------Energy Production this session----------------")
 gpu:setText(0, 1, "Total session time: " .. convertToTime(computer.millis()))
 gpu:setText(0, 2, "Maximum power produced: " .. string.format("%.2f", productionMax))
 gpu:setText(0, 3, "Minimum power produced: " .. string.format("%.2f", productionMin))
 gpu:flush()
end

battery = component.proxy("3909A0A2414FAE74945E39B4BA310CF0")
if not battery then error("No battery found!") end
light = component.proxy("ED45EBA041045EB6E9909A8E10FA4904")
if not light then error("No light found!") end

local tabScreen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
if not tabScreen then error("No Screen tab found!") end
gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then error("No GPU T1 found!") end
gpu:bindScreen(tabScreen)
gpu:setSize(120, 50)

circuit = battery:getPowerConnectors()[1]:getCircuit()

productionMax = circuit.production
productionMin = circuit.production

while true do
  if (circuit.batteryStorePercent <= 0.75) then
   light.colorSlot = 1
  elseif (circuit.batteryStorePercent < 1.0) then
   light.colorSlot = 2
  else
   light.colorSlot = 3
  end

  if (circuit.production > productionMax) then productionMax = circuit.production end
  if (circuit.production < productionMin) then productionMin = circuit.production end
  updateScreen()

  print(computer.millis(), circuit.batteryStorePercent * 100, "%")
  event.pull(10.0)
end
