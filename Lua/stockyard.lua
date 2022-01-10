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

function printCountainer(col, row, percentage, name)
 if (percentage < 50) then
  gpu:setForeground(1,0,0,1)
 elseif (percentage < 75) then
  gpu:setForeground(1,1,0,1)
 else
  gpu:setForeground(1,1,1,1)
 end
 gpu:setText(col, row, string.format("%-20s", name) .. percentage .. "%")
end

function updateOutput()
 clearScreen(gpu)
 local containers = component.proxy(component.findComponent(findClass("Build_StorageContainerMk2_C")))
 local x = tableLength(containers)
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-54s", "Stockyard Inventory")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local row = 1
 local emptyContainers = 0
 for _, cntr in pairs(containers) do
  if(cntr.nick == "container") then goto continue end
  local invs = cntr:getInventories()[1]
  local count = 0
  local max = 0
  local name = "*********"
  local i = 0

  while (i < invs.Size) do
   local t = nil
   local stack = invs:getStack(i)
   if (stack.item) then 
    t = stack.item.type
   end
   if(t) then
    count = count + stack.count
    max = t.max * invs.Size
    name = t.name
   end
   i = i + 1
  end --while

  if(count > 0) then
   percentage = math.floor(count / max * 100)
   printCountainer(0, row, percentage, name)
   row = row + 1
  else
   emptyContainers = emptyContainers + 1
  end
  ::continue::
 end

 gpu:setForeground(1,1,1,1)
 gpu:setText(0, 11, "Empty containers: " .. emptyContainers)
 gpu:flush()
 print("Containers found: " .. x)
 print("Containers reported: " .. row - 1)
 print("Empty containers: " .. emptyContainers)
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("BDC2EB1146532A25708ECC89560A4D4E")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(55, 12)
clearScreen(gpu)

local icon = {"|", "/", "-", "\\"}
local iconIndex = 5

while true do
 if(iconIndex > 4) then 
  updateOutput()
  iconIndex = 1 
 end 
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(54, 0, icon[iconIndex])
 gpu:flush()
 iconIndex = iconIndex + 1
 event.pull(1)
end
