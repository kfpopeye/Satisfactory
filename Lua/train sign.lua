function printScreen(str)
 print(str)
 clearScreen()
 local line0 = string.format("%-20s", station.name)
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
  i = i + 1
  event.pull(0.0625)
 end
end


function clearScreen()
 gpu:setBackground(0, 0, 0, 0)
 gpu:setForeground(1, 1, 1, 1)
 gpu:fill(0, 0, w, h, " ")
end

-- get first T1 GPU avialable from PCI-Interface
gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then
 error("No GPU T1 found!")
end

-- get first Screen-Driver available from PCI-Interface
local screen = component.proxy("B58895234477BC6EC6C3FCAC68B3A392")
if not screen then
 error("No screen")
end

station = component.proxy("A29A211244D1514CEB6C128E2335F462")
if not station then error("No station found!") end

-- setup gpu
gpu:bindScreen(screen)
gpu:setSize(20, 3)
w,h = gpu:getSize()
print("Res:", w, h)
clearScreen()

lastStop = "none"

while true do
 t_table = station:getTrackGraph():getTrains()[1]:getTimeTable()
 if(t_table:getCurrentStop()) then
  nextStop = t_table:getStops()[t_table:getCurrentStop() + 1].station.name
 else
  nextSop = "Unknown"
 end
 printScreen(nextStop)
 event.pull(2)
end