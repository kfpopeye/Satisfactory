battery = component.proxy("3909A0A2414FAE74945E39B4BA310CF0")
light = component.proxy("ED45EBA041045EB6E9909A8E10FA4904")
while true do
  if (battery.powerStorePercent <= 0.75) then
   light.isLightEnabled = true
   print(computer.millis(), battery.powerStorePercent * 100, "%", "Light on !!!!!!!!!!!!!!")
  else
   light.isLightEnabled = false
   print(computer.millis(), battery.powerStorePercent * 100, "%", "Light off")
  end

  event.pull(10.0)
end