-- -------------------------------------------------------------
-- |                                                           |
-- |   stockyard.lua                                           |
-- |                                                           |
-- -------------------------------------------------------------

computer.log(1, "--- Stockyard Monitor V1.0 ---")
groupName = "" -- if all the containers are grouped, enter the group name inside the quotes 
                        -- otherwise all containers will be monitored.

--Verbosity is 0 debug, 1 info, 2 warning, 3 error and 4 fatal
function pdebug(msg) if (debug) then computer.log(0, msg) end end
function pinfo(msg) computer.log(1, msg) end
function pwarn(msg) computer.log(2, msg) end
function perror(msg) computer.log(3, msg) computer.beep() error(msg)end
function pfatal(msg) computer.log(4, msg) end

function getContainers()
 if (groupName == "") then
  c = component.proxy(component.findComponent(classes.FGBuildableStorage))
  local t = component.proxy(component.findComponent(classes.Build_IndustrialTank_C))
  if (t) then
    for _, value in ipairs(t) do
     table.insert(c, value)
    end
  end
 else
  c = component.proxy(component.findComponent(groupName))
 end
 if not c then perror("Containers was nil") end
 return c
end

function catalogContainers()
 local containers = getContainers()
 
 for _, cntr in pairs(containers) do
  local invs = cntr:getInventories()[1]
  local name = "Unused"
  local nick = ""
  if (groupName == "") then
   nick = cntr.nick
  else
   nick = string.gsub(cntr.nick, groupName, "")
  end
  if(invs) then -- fluid buffers do not have an inventory
   local t = nil
   local stack = invs:getStack(0)
   if (stack and stack.item) then t = stack.item.type end
   if(t) then name = t.name .. nick end
  else
   name = cntr:getFluidType().name .. nick
  end
  table.insert(containerHashAndName, {cntr.hash, name})
 end

 table.sort(containerHashAndName, function (a, b) return a[2] < b[2] end)
 pinfo("Containers found: " .. tableLength(containerHashAndName))
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
 if(hasScreen) then
  gpu:setForeground(1,1,1,1)
  if not (name == "Unused") then
   if (percentage < 50) then
    gpu:setForeground(1,0,0,1)
   elseif (percentage < 75) then
    gpu:setForeground(1,1,0,1)
   end
  else
   gpu:setForeground(0.25,0.25,0.25,1)
  end
  gpu:setText(col, row, string.format("%-20s", name) .. string.format("%3s", percentage) .. "%")
 else
  if (percentage) then --nil is used to signal print out of final message
   if (message == nil) then message = "" end
   if (percentage < 50) then
    message = message .. (string.format("%-20s", name) .. string.format("%3s", percentage) .. "%** ")
   elseif (percentage < 75) then
    message = message .. (string.format("%-20s", name) .. string.format("%3s", percentage) .. "%*  ")
   else
    message = message .. (string.format("%-20s", name) .. string.format("%3s", percentage) .. "%   ")
   end
  end
  if (col == 2) then
   pinfo(message)
   message = nil
  end
 end
end

function getContainerByHash(hash)
 local containers = getContainers()
 if not containers then perror("Containers was nil") end
 for _, cntr in pairs(containers) do
  if (cntr.hash == hash) then return cntr end
 end
 computer.log(3, "getContainerByHash(): Hash not found.")
 computer.reset()
end

function updateOutput()
 if(hasScreen) then
  clearScreen(gpu)
  gpu:setBackground(0, 0.5, 1.0, 0.5)
  gpu:setForeground(0, 0, 0, 1)
  gpu:setText(0, 0, string.format("%-54s", "Stockyard Inventory")) --55 chars (padded with spaces after)
  gpu:setBackground(0,0,0,0)
  gpu:setForeground(1,1,1,1)
 else
  pinfo("-----------------------------------------------------------------------")
 end

 local row = 1
 local col = 0

 for ndx, c in ipairs(containerHashAndName) do
  local hash = c[1]
  local name = c[2]
  local cntr = getContainerByHash(hash)
  local invs = cntr:getInventories()[1]
  local count = 0
  local max = -1
  local i = 0

  if(invs) then -- fluid buffers do not have an inventory
   while (i < invs.Size) do
    local t = nil
    local stack = invs:getStack(i)
    if (stack.item) then t = stack.item.type end
    if(t) then
     count = count + stack.count
     max = t.max * invs.Size
     if (name == "Unused") then
      name = t.name .. string.gsub(cntr.nick, groupName, "")
      containerHashAndName[ndx] = {cntr.hash, name}
     end
    end
    i = i + 1
   end --while
  else
   count = cntr.fluidContent
   max = cntr.maxFluidContent
   if (name == "Unused") then
    name = cntr:getFluidType().name
    containerHashAndName[ndx] = {cntr.hash, name}
   end
  end

  percentage = math.floor(count / max * 100)
  printContainer(col, row, percentage, name)
  if (hasScreen) then
   row = row + 1
   if (row == 12) then
    row = 1
    col = 27
   end
  else
   col = col + 1
   if (col == 3) then col = 0 end
  end
 end --end for

 if (hasScreen) then
  gpu:flush()
 else
  printContainer(2, row, nil, nil)
 end
end

hasScreen = true

--main chunk
local gpus = computer.getPCIDevices(classes.GPUT1)
gpu = gpus[1]
if not gpu then
 warn("No GPU T1 found! Add one for increased functionality.")
 hasScreen = false
else
 local screen = component.proxy("3426D01E46D6C3A9AB9361B0E7E1D005")
 if not screen then error("No screen") end

 gpu:bindScreen(screen)
 gpu:setSize(55, 12)
 clearScreen(gpu)
end

local icon = {"|", "/", "-", "\\"}
local iconIndex = 5

containerHashAndName = {}
catalogContainers()

while true do
 if(iconIndex > 4) then 
  updateOutput()
  iconIndex = 1 
 end
 if (hasScreen) then
  gpu:setBackground(0, 0.5, 1.0, 0.5)
  gpu:setForeground(0, 0, 0, 1)
  gpu:setText(54, 0, icon[iconIndex])
  gpu:flush()
 else
  computer.stop()
 end
 iconIndex = iconIndex + 1
 event.pull(1)
end
