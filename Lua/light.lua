battery = component.proxy("3909A0A2414FAE74945E39B4BA310CF0")
light = component.proxy("ED45EBA041045EB6E9909A8E10FA4904")
while true do
  if (battery.powerStorePercent <= 0.75) then
   light.colorSlot = 1
  elseif (battery.powerStorePercent < 1.0) then
   light.colorSlot = 2
  else
   light.colorSlot = 3
  end

  print(computer.millis(), battery.powerStorePercent * 100, "%")
  event.pull(10.0)
end
