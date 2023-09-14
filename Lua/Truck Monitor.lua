function clearScreen(g)
 local w,h = g:getSize()
 g:setForeground(1,1,1,1)
 g:setBackground(0,0,0,0)
 g:fill(0,0,w,h," ")
 g:flush()
end

function mainLoop()
 while(true) do
  e, sender, veh = event.pull(0)
  if (e == "OnVehicleEnter") then
   local inv = veh:getStorageInv()
   local count = 1
   local stackCount = 0
   while (count < inv.size) do
    local s = inv:getStack(count)
    if (s and s.count > 0) then stackCount = stackCount + 1 end
    count = count + 1
   end
   if (sender == ts1) then
    if(veh.isSelfDriving) then gpu:setText(0, 0, sender.nick .. " : " .. stackCount / inv.size * 100 .. "% full         ") end
    ts1:setColor(1, 0, 0, 1)
   end
   if (sender == ts2) then
    if(veh.isSelfDriving) then gpu:setText(0, 1, sender.nick .. " : " .. stackCount / inv.size * 100 .. "% full         ") end
    ts2:setColor(1, 0, 0, 1)
   end
   gpu:flush()
   if(veh.isSelfDriving) then
    print(sender.nick .. " : " .. stackCount / inv.size * 100 .. "% full")
   else
    print ("Vehicle was not self driving.")
   end
   computer.beep()
  elseif (e == "OnVehicleExit") then
   if (sender == ts1) then ts1:setColor(1, 0, 0, 0) end
   if (sender == ts2) then ts2:setColor(1, 0, 0, 0) end
  end
 end
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("9F80B1FD4D6D92754BF44B88A421EAB8")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(25, 2)
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
