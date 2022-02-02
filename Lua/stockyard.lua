function catalogContainers()
 local containers = component.proxy(component.findComponent("stockyard"))
 if not containers then error("Containers was nil") end
 for _, cntr in pairs(containers) do
  local invs = cntr:getInventories()[1]
  local name = "Unnamed"

  if(invs) then -- fluid buffers do not have an inventory
   local t = nil
   local stack = invs:getStack(0)
   if (stack and stack.item) then t = stack.item.type end
   if(t) then name = t.name end
  else
   name = cntr:getFluidType().name
  end

  print (cntr.hash, name)
  containerHashAndName[cntr.hash] = name
 end
 print("Containers found: " .. tableLength(containerHashAndName))
end

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

function tableContains (T, h)
 for _, value in pairs(T) do
  if (value == h) then return true end
 end
 return false
end

function printContainer(col, row, percentage, name)
 gpu:setForeground(1,1,1,1)
 if not (name == "Unnamed") then
  if (percentage < 50) then
   gpu:setForeground(1,0,0,1)
  elseif (percentage < 75) then
   gpu:setForeground(1,1,0,1)
  end
 else
  gpu:setForeground(0.25,0.25,0.25,1)
 end
 gpu:setText(col, row, string.format("%-20s", name) .. string.format("%3s", percentage) .. "%")
end

function updateOutput()
 clearScreen(gpu)
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-54s", "Stockyard Inventory")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local containers = component.proxy(component.findComponent("stockyard"))
 if not containers then error("Containers was nil") end

 local row = 1
 local col = 0
 for _, cntr in pairs(containers) do
  --print ("Type: " .. cntr:getType().displayName)
  local invs = cntr:getInventories()[1]
  local count = 0
  local max = -1
  local name = containerHashAndName[cntr.hash]
  local i = 0

  if(invs) then -- fluid buffers do not have an inventory
   while (i < invs.Size) do
    local t = nil
    local stack = invs:getStack(i)
    if (stack.item) then t = stack.item.type end
    if(t) then
     count = count + stack.count
     max = t.max * invs.Size
     if (name == "Unnamed") then
      name = t.name
      containerHashAndName[cntr.hash] = name
     end
    end
    i = i + 1
   end --while
  else
   count = cntr.fluidContent
   max = cntr.maxFluidContent
   if (name == "Unnamed") then
    name = cntr:getFluidType().name
    containerHashAndName[cntr.hash] = name
   end
  end

  percentage = math.floor(count / max * 100)
  printContainer(col, row, percentage, name)
  row = row + 1
  if (row == 12) then
   row = 1
   col = 27
  end
 end

 gpu:flush()
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

containerHashAndName = {}
catalogContainers()

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
