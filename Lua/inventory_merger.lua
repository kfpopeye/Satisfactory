containerId = "AAE9404C461553BEF5AAE18CCD31C717"
groupName = "" -- if all the codeable mergers are grouped, enter the group name inside the quotes
itemMaxLimit = 0 -- setting this to greater than 0 will fill container with this many of each item, instead of filling partial stacks

--clears the screen tab
function clearTabScreen()
 if not hasScreen then return end
 local w,h = gpu:getSize()
 gpu:setBackground(0,0,0,0)
 gpu:fill(0,0,w,h,".")
 gpu:flush()
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function updateInfo() --120 x 30
 if not hasScreen then return end
 local row = 14
 local col = 0
 
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 gpu:fill(0, row, 30, 1, " ")
 gpu:setText(col, row, "Items transitting: " .. itemsInTransit)
 gpu:flush()
end

function printInventoryToScreen(msg) -- resolution 120x30
 if not hasScreen then return end
 local row = 0
 local col = 0
 if not inventoryBuffer then inventoryBuffer = {} end
 if (msg) then
  table.insert(inventoryBuffer, msg)
 else
  gpu:setBackground(0,0,0,0)
  gpu:fill(0, row, 120, row + 12, " ")
  gpu:flush()
  gpu:setBackground(0,0,0,0)
  gpu:setForeground(1,1,1,1)
  for k,v in pairs(inventoryBuffer) do
   gpu:setText(col, row, inventoryBuffer[k])
   inventoryBuffer[k]=nil
   row = row + 1
   if (row == 12) then
    row = 0
    col = col + 30
   end
  end
  gpu:flush()
 end
end

--scans the container and creates a list of anything thats a partial stack
function createInventoryList()
 print("Scanning container...")
 local lowInventories = {}
 local invs = container:getInventories()[1]
 local i = 0
 while (i < invs.Size) do
  local t = nil
  local stack = invs:getStack(i)
  if (stack.item) then t = stack.item.type end
  if(t) then
   local c = stack.count
   local m = t.max
   local intName = t.internalName
   local name = t.name
   if(c < m) then
    if(lowInventories[intName]) then
     lowInventories[intName]["max"] = lowInventories[intName]["max"] + m
     lowInventories[intName]["count"] = lowInventories[intName]["count"] + c
    else
     local info = {}
     info["max"] = m
     info["count"] = c
     info["name"] = name
     lowInventories[intName] = info
    end
   end
   print(" Slot", i, name, c, m)
   printInventoryToScreen("Slot #" .. i .. ": " .. name .. "(" .. c .. "/" .. m .. ")")
  else
   printInventoryToScreen("Slot #" .. i .. ": Empty")
  end
  i = i + 1
 end
 print()
 return lowInventories
end

function isPassThrough(mrgr, dir)
 local s = mrgr.nick
 if(s:find("left") and (dir == direction.left)) then
  return true
 elseif(s:find("middle") and (dir == direction.middle)) then
  return true
 elseif(s:find("right") and (dir == direction.right)) then
  return true
 end
 return false
end

function getMergers()
 local mergers = nil

 if (groupName == "") then
  mergers = component.proxy(component.findComponent(findClass("CodeableMerger")))
 else
  mergers = component.proxy(component.findComponent(groupName))
 end

 return mergers
end

function findMerger(intName)
 local dbgMsg = nil
 local returnMerger = nil
 local returnInput = -1
 local mergers = getMergers()
 local count = tableLength(mergers)
 if count == 0 then error("No Codeable Mergers found!") else print(count, "mergers found.") end

 for _, merger in pairs(mergers) do
  local x = 0
  dbgMsg = " Nick: " .. merger.nick
  while (x < 3) do
   local i = merger:getInput(x)
   if (i and i.type) then
    dbgMsg =  dbgMsg .. " - Input #" .. x .. " " .. i.type.name
    if i.type.internalName == intName then
     if not isPassThrough(merger, x) then
      returnMerger = merger
      returnInput = x
     else
      dbgMsg =  dbgMsg .. "(passthru)"
     end
    end
   else
    dbgMsg =  dbgMsg .. " - Input #" .. x .. " Empty"
   end
   x = x + 1
  end
  print(dbgMsg)
 end
 print()
 return returnMerger, returnInput
end

function checkEvents()
 e, sender = event.pull(0)
 if (e == "ItemTransfer") then
  itemsInTransit = itemsInTransit - 1
  updateInfo()
 end
end

function processPassthruInputs()
 local dbgMsg = nil
 local mergers = getMergers()
 local count = tableLength(mergers)
 if count == 0 then error("No Codeable Mergers found!") else print("Passthru() found " .. count .. " mergers.") end

 for _, merger in pairs(mergers) do
  local x = 0
  while (x < 3) do
   local i = merger:getInput(x)
   if (i and i.type) then
    dbgMsg = merger.nick
    if isPassThrough(merger, x) then
     if merger.canOutput then
      dbgMsg = dbgMsg .. " - passthru " .. i.type.name .. " on input " .. x
      merger:transferItem(x)
     else
      dbgMsg = dbgMsg .. " - cannot output " .. i.type.name
     end
    end
   end
   x = x + 1
  end --endwhile
  if dbgMsg then print(dbgMsg) end
 end --endfor
 print()
end

-- ***************** constants ********************
direction = {left = 2, middle = 1, right = 0}

-- ***************** devices ********************
hasScreen = false
local screen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
if not screen then print("No Screen found. Did you add a screen driver?") end
gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then print("No GPU found. Did you add a graphical processing unit T1?") end
if screen and gpu then
 gpu:bindScreen(screen)
 hasScreen = true
 clearTabScreen()
end

container = component.proxy(containerId)
if not container then error("No Container found!") end
for _, connector in pairs(container:getFactoryConnectors()) do event.listen(connector) end
event.clear()
slotsToRefill = createInventoryList()
local count = tableLength(slotsToRefill)
if count == 0 then
 needsRefill = false
 print("No slots were partially filled. Nothing to do.")
 computer.beep()
 computer.stop()
else
 needsRefill = true
 printInventoryToScreen()
end

itemsInTransit = 0
while needsRefill do
 needsRefill = false
 for intName, infoTable in pairs(slotsToRefill) do
  local dbgMsg = nil
  if(intName) then
   if(slotsToRefill[intName]["count"] < slotsToRefill[intName]["max"]) then
    needsRefill = true
    local merger, input = findMerger(intName)
    if(merger) then
     dbgMsg = merger.nick .. " has: " .. slotsToRefill[intName]["name"]
     if merger.canOutput and merger:transferItem(input) then
       itemsInTransit = itemsInTransit + 1
       slotsToRefill[intName]["count"] = slotsToRefill[intName]["count"] + 1
     else
      dbgMsg = dbgMsg .. " but cannot transfer."
     end
    else
     dbgMsg = "No merger has " .. slotsToRefill[intName]["name"]
    end
    print(dbgMsg)
    print()
   end
  end
  processPassthruInputs()
  checkEvents()
 end --endfor
end

while itemsInTransit > 0 do
 processPassthruInputs()
 checkEvents()
end

computer.beep()
print ("Done")
