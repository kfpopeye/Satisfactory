battery = component.proxy("3909A0A2414FAE74945E39B4BA310CF0")
if not battery then error("No battery found!") end
light = component.proxy("ED45EBA041045EB6E9909A8E10FA4904")
if not light then error("No light found!") end

circuit = battery:getPowerConnectors()[1]:getCircuit()

while true do
  if (circuit.batteryStorePercent <= 0.75) then
   light.colorSlot = 1
  elseif (circuit.batteryStorePercent < 1.0) then
   light.colorSlot = 2
  else
   light.colorSlot = 3
  end

  print(computer.millis(), circuit.batteryStorePercent * 100, "%")
  event.pull(10.0)
end
