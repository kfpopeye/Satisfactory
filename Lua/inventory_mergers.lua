-- -------------------------------------------------------------
-- |                                                           |
-- |   inventory_merger.lua                                    |
-- |                                                           |
-- -------------------------------------------------------------

computer.log(1, "--- Inventory Merger ---")
containerId = "08BC875F4652A329EBC31793BFECB856"
panelID = "5EB0142944C39F6C3209D4A358DE5940"
groupName = "tickle" -- if all the codeable mergers are grouped, enter the group name inside the quotes otherwise
                     -- all codeable mergers will be used.
itemMaxLimit = 0 -- setting this to greater than 0 will fill container with this many of each item, instead of filling partial stacks

debug = false -- supresses debug comments

passthruMode = false --If there is no console panel, setting this to true will make unit process passthrough ports only

-- Important information
-- 1. Merger names must follow the format "groupName part direction direction"
--    where direction indicates 2 optional passthru ports = middle (or centre), left or right
-- 2. Tabbed screen and control panel are option but control panel must have 2 text screens, a button and a lever.

--Verbosity is 0 debug, 1 info, 2 warning, 3 error and 4 fatal
function pdebug(msg) if (debug) then computer.log(0, msg) end end
function pinfo(msg) computer.log(1, msg) end
function pwarn(msg) computer.log(2, msg) end
function perror(msg) computer.log(3, msg) error(msg) end
function pfatal(msg) computer.log(4, msg) end

function wait (a) 
 local sec = tonumber(computer.millis() + (a * 1000)); 
 while (computer.millis() < sec) do end 
end

--clears the screen tab
function clearTabScreen()
 if not hasScreen then return end
 local w,h = gpu:getSize()
 gpu:setForeground(1,1,1,1)
 gpu:setBackground(0,0,0,0)
 gpu:fill(0,0,w,h," ")
 gpu:flush()
end

function clearScreen(g)
 local w,h = g:getSize()
 g:setForeground(1,1,1,1)
 g:setBackground(0,0,0,0)
 g:fill(0,0,w,h,".")
 g:flush()
end

function convertToTime(ms)
 if ms < 0 then ms = 0 end
 local tenths = ms // 100
 local hh = (tenths // (60 * 60 * 10)) % 24
 local mm = (tenths // (60 * 10)) % 60
 local ss = (tenths // 10) % 60
 local t = tenths % 10
 return string.format("%02d:%02d:%02d.%01d", hh, mm, ss, t)
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function updateInfo()
 updateScreenInfo()
 updatePanelInfo()
end

function updatePanelInfo()
 -- text displays are 30 char wide
 if (not hasPanel) then return end
 
 local iLeft = 0
 for _, infoTable in pairs(slotsToRefill) do
  iLeft = iLeft + (infoTable["max"] - infoTable["count"])
 end

 local t = convertToTime(refillTimeOut - (computer.millis() - lastTransferTime))
 progScreen.text = "Time out in: " .. t .. 
                   "\nItems transitting: " .. itemsInTransit .. 
                   "\nTypes transitting: " .. tableLength(slotsToRefill) .. 
                   "\nItems left: " .. iLeft - itemsInTransit

 if (itemsInTransit == 0 and not needsRefill) then 
  progScreen.text = "**** COMPLETE ****"
 end
 if (timedOut) then
  local n = ""
  for _, infoTable in pairs(slotsToRefill) do
   if(not infoTable["mrgrId"]) then
    n = n .. infoTable["name"] .. ", "
   end  
  end
  progScreen.text = "**** TIMED OUT ****\nMissing " .. string.sub(n, 1, -3)
 end
end

function updateScreenInfo()
 if not hasScreen then
  pinfo("Items transitting: " .. itemsInTransit)
  pinfo("Time out in: " .. convertToTime(refillTimeOut - (computer.millis() - lastTransferTime)))
  return
 end
 
 local row = 26
 local col = 0
 local height = 18
 local width = 120

 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 gpu:fill(col, row, width, height, " ")

 gpu:setBackground(1,1,1,1)
 gpu:setForeground(0,0,0,1)
 gpu:setText(col, row, "Progress" .. string.rep(" ", 112))
 row = row + 1
 
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 gpu:setText(col, row, "Items transitting: " .. itemsInTransit)
 if itemsInTransit == 0 and not needsRefill then 
  gpu:setForeground(0,1,0,1)
  gpu:setText(col + 25, row, "**** COMPLETE ****")
  gpu:setForeground(1,1,1,1)
 end
 if timedOut then 
  gpu:setForeground(1,1,0,1)
  gpu:setText(col + 25, row, "**** TIMED OUT ****")
  gpu:setForeground(1,1,1,1)
 end
 row = row + 1

 if (mergerCount == -1) then getMergers() end
 gpu:setText(col, row, "Codeable mergers found: " .. mergerCount)
 row = row + 1
 local s = "Time out in: " .. convertToTime(refillTimeOut - (computer.millis() - lastTransferTime))
 gpu:setText(col, row, s)
 pdebug(s)
 row = row + 2
 
 gpu:setBackground(1,1,1,1)
 gpu:setForeground(0,0,0,1)
 gpu:setText(col, row, "Items sent")
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,0,1)
 gpu:setText(col + 12, row, "Yellow indicates no merger found.")
 row = row + 1

 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 local rowStart = row
 local pScreenTxt = "Transferring parts:\n"
 for _, infoTable in pairs(slotsToRefill) do
  local n = string.sub((infoTable["name"] .. "          "), 1, 10)
  if(infoTable["mrgrId"]) then
   gpu:setForeground(1,1,1,1)
  else
   gpu:setForeground(1,1,0,1) --yellow
  end
  gpu:setText(col, row, n .. " (" .. (infoTable["count"] .. " + " .. infoTable["inTransit"]) .. "\\" .. infoTable["max"] .. ")")
  pScreenTxt = pScreenTxt .. n .. "\n"
  row = row + 1
  if (row == rowStart + 12) then
   row = rowStart
   col = col + 30
  end
 end
 gpu:flush()
end

function printInventoryToScreen()
 addInventoryToScreenBuffer()
end

-- passing a slotNum will add it to the buffer, passing nil will display buffer to screen
function addInventoryToScreenBuffer(slotNum, name, count, max)
 if not hasScreen then return end

 if not inventoryBuffer then inventoryBuffer = {} end
 if (slotNum) then
  local msg = nil
   local s = string.format("%-2s", (slotNum + 1))
   if count == 0 and max == 0 then
    msg = "Slot #" .. s .. ": Empty"
   else
    msg = "Slot #" .. s .. ": " .. string.sub((name .. "                              "), 1, 30) .. " (" .. count .. "\\" .. max .. ")"
   end
   table.insert(inventoryBuffer, msg)
 else
  local row = 0
  local col = 0
  local height = 25
  local width = 120

  gpu:setBackground(0,0,0,0)
  gpu:fill(col, row, width, height, " ")
  gpu:flush()

  gpu:setBackground(1,1,1,1)
  gpu:setForeground(0,0,0,1)
  gpu:setText(col, row, "Catalogued container inventory".. string.rep(" ", 90))

  gpu:setBackground(0,0,0,0)
  gpu:setForeground(1,1,1,1)
  row = row + 1
  col = col + 1
  local rowStart = row
  for k,v in pairs(inventoryBuffer) do
   gpu:setText(col, row, inventoryBuffer[k])
   inventoryBuffer[k]=nil
   row = row + 1
   if (row == rowStart + 24) then
    row = rowStart
    col = col + 60
   end
  end
  gpu:flush()
 end
end

function rescanContainer()
 local newList = createInventoryList()
 for intName, infoTable in pairs(newList) do
  if (slotsToRefill[intName]) then
   newList[intName]["inTransit"] = slotsToRefill[intName]["inTransit"]
  end
 end
 slotsToRefill = newList
end

--scans the container and returns a list of anything thats a partial stack
function createInventoryList()
 pinfo("Scanning container...")
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
     info["mrgrId"] = nil
     info["inTransit"] = 0
     lowInventories[intName] = info
     pinfo("Slot" .. i .. name .. c .. m)
    end
   end
   pdebug("Slot" .. i .. name .. c .. m)
   addInventoryToScreenBuffer(i, name, c, m) 
  else
   addInventoryToScreenBuffer(i, "Empty", 0, 0)
  end
  i = i + 1
 end
 return lowInventories
end

function isPassThrough(mrgr, dir)
 local s = mrgr.nick
 if((dir == direction.left) and s:find("left")) then
  return true
 elseif((dir == direction.middle) and s:find("middle")) then
  return true
 elseif((dir == direction.middle) and s:find("centre")) then
  return true
 elseif((dir == direction.right) and s:find("right")) then
  return true
 end
 return false
end

function getMergers()
 local mergers = nil

 if (groupName == "") then
  mergers = component.proxy(component.findComponent(classes.CodeableMerger_C))
 else
  mergers = component.proxy(component.findComponent(groupName))
 end

 mergerCount = tableLength(mergers)
 return mergers
end

function findMerger(intName)
 local dbgMsg = nil
 local returnMerger = nil
 local returnInput = -1
 local mergers = getMergers()
 if count == 0 then perror("No Codeable Mergers found!") end

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
  pdebug(dbgMsg)
 end
 return returnMerger, returnInput
end

function checkEvents()
 e, sender, val1 = event.pull(0)
 if (e == "ItemTransfer") then
  if (slotsToRefill and slotsToRefill[val1.type.internalName]) then
   itemsInTransit = itemsInTransit - 1
   slotsToRefill[val1.type.internalName]["inTransit"] = slotsToRefill[val1.type.internalName]["inTransit"] - 1
   slotsToRefill[val1.type.internalName]["count"] = slotsToRefill[val1.type.internalName]["count"] + 1
  else
   pwarn("Received unexpected item: " .. val1.type.Name)
  end
 elseif (e == "Trigger" and sender == button) then
  infoScreen.Text = "Rescanning...."
  rescanContainer()
  computer.beep()
 elseif (e == "ChangeState" and sender == lever) then
  event.ignore(lever)
  lever.State = not lever.State
  event.clear()
  event.listen(lever)
  event.pull(0)
  infoScreen.Text = "Cannot change pass-thru\nmode while transferring parts."
  computer.beep()
 end
end

function processPassthruInputs()
 local dbgMsg = nil
 local mergers = getMergers()
 if count == 0 then perror("No Codeable Mergers found!") end

 for _, merger in pairs(mergers) do
  local x = 0
  while (x < 3) do
   local i = merger:getInput(x)
   if (i and i.type) then
    if isPassThrough(merger, x) then
     if merger.canOutput then
      dbgMsg = " " .. merger.nick .. " - passed thru " .. i.type.name .. " on input " .. x
      merger:transferItem(x)
     else
      dbgMsg = " " .. merger.nick .. " - cannot output " .. i.type.name
     end
    end
   end
   x = x + 1
  end --endwhile
  if (dbgMsg) then pdebug(dbgMsg) end
 end --endfor
end

function refillContainer()
 if (passthruMode) then
  pinfo("Passthru mode not refilling.")
  return
 else
  pinfo("Refilling.")
 end
 while needsRefill and not timedOut do
  needsRefill = false
  for intName, infoTable in pairs(slotsToRefill) do
   local dbgMsg = nil
   if(slotsToRefill[intName]["count"] + slotsToRefill[intName]["inTransit"] < slotsToRefill[intName]["max"]) then
    needsRefill = true
    local merger, input = findMerger(intName)
    if(merger) then
     slotsToRefill[intName]["mrgrId"] = merger.id
     dbgMsg = merger.nick .. " has: " .. slotsToRefill[intName]["name"]
     if merger.canOutput and merger:transferItem(input) then
       lastTransferTime = computer.millis()
       itemsInTransit = itemsInTransit + 1
       slotsToRefill[intName]["inTransit"] = slotsToRefill[intName]["inTransit"] + 1
     else
      dbgMsg = dbgMsg .. " but cannot transfer."
     end
    else
     dbgMsg = "No merger has " .. slotsToRefill[intName]["name"]
    end
    pdebug(dbgMsg)
   end
   processPassthruInputs()
   updateInfo()
   checkEvents()
   if(computer.millis() - lastTransferTime > refillTimeOut) then
    timedOut = true
    pinfo("Timed out")
   end
  end --endfor
 end -- endwhile
end

-- this is executed only if there is a console panel
function waitForStart()
 -- reset globals
 mergerCount = 0
 itemsInTransit = 0
 lastTransferTime = computer.millis()
 timedOut = false
 needsRefill = true
 local waiting = true
 button:setColor(1,1,0,1)
 pinfo("Push button to start refilling.")
 infoScreen.text = "Push button to start refilling."

 while (waiting) do
  e, sender = event.pull(0)
  if (e == "Trigger" and sender == button) then
   waiting = false
   button:setColor(0,1,0,1)
   computer.beep()
  elseif (e == "ChangeState" and sender == lever) then
   if (lever.state) then
    pinfo("Setting pass thru mode on")
    infoScreen.text = "Setting pass thru mode on.\nPush button to start."
    needsRefill = false
    itemsInTransit = 100
   else
    pinfo("Setting pass thru mode off")
    infoScreen.text = "Setting pass thru mode off.\nPush button to start refilling."
    needsRefill = true
    itemsInTransit = 0
   end
   computer.beep()
  end
 end
end

-- ***************** main chunk ********************
pinfo("Starting main chunk.")

-- ***************** constants ********************
direction = {left = 2, middle = 1, right = 0}
refillTimeOut = 5 * 60 * 1000 --5 min in ms

-- ***************** globals ********************
mergerCount = -1
lastTransferTime = computer.millis()
timedOut = false
if (passthruMode) then
 needsRefill = false
 itemsInTransit = 100
else
 needsRefill = true
 itemsInTransit = 0
end

-- ***************** devices ********************
pinfo("Configuring devices.")
hasScreen = false
local screen = computer.getPCIDevices(classes.FINComputerScreen)[1]
if not screen then pwarn("No Screen found. Add a screen driver for improved information output.") end
gpu = computer.getPCIDevices(classes.GPUT1)[1]
if not gpu then pwarn("No GPU found. Add a graphical processing unit T1 for improved information output.") end
if screen and gpu then
 gpu:bindScreen(screen)
 gpu:setSize(120, 50)
 hasScreen = true
 clearTabScreen()
end

--------------------------------
container = component.proxy(containerId)
if not container then perror("No Container found!") end
for _, connector in pairs(container:getFactoryConnectors()) do event.listen(connector) end
--------------------------------
hasPanel = false
panel = component.proxy(panelID)
if (panel) then
 hasPanel = true
 pinfo("Found control panel")
 for _, module in pairs(panel:getModules()) do
  if (debug) then print(module:getType().Name) end
  if (module:getType().Name == "ModuleSwitch") then lever = module print("Found lever") end
  if (module:getType().Name == "ModuleButton") then button = module print("Found button") end
  if (module:getType().Name == "ModuleTextDisplay" and infoScreen) then
   pinfo("Found text screen 2")
   progScreen = module
   progScreen.Size = 25
   progScreen.Text = "Progress screen"
  end
  if (module:getType().Name == "ModuleTextDisplay" and not infoScreen) then
   pinfo("Found text screen 1")
   infoScreen = module
   infoScreen.size = 25
   infoScreen.text = "Information screen"
  end
 end
 lever.State = false
 event.listen(lever)
 event.listen(button)
else
 pwarn("Add a control panel for better functionality.")
end
event.clear()

-- ***************** main loop ********************
::startMain::
pinfo("Starting loop.")
if (hasPanel) then
 createInventoryList()
 printInventoryToScreen()
 waitForStart()
end

--check if anything needs to be refilled
slotsToRefill = createInventoryList()
printInventoryToScreen()
local count = tableLength(slotsToRefill)

if (count == 0) then
 needsRefill = false
 pinfo("No slots were partially filled. Nothing to do.")
 if (hasPanel) then infoScreen.text = "No slots were partially filled.\nNothing to do." end
 computer.beep()
 wait(2)
else
 needsRefill = true
 if (hasPanel) then infoScreen.text = "Refilling in progress." end
end

-- set passthru mode from console
if (hasPanel and lever.state) then
 passthruMode = true
 needsRefill = false
 itemsInTransit = 100
end

--start refilling containers
local status, err = pcall(refillContainer)
if not status then
 computer.log(4, err)
 computer.beep()
 if (hasPanel) then
  button:setColor(1,0,0, 1)
  progScreen.Size = 50
  progScreen.Text = "ERROR"
  infoScreen.Text = "An error has occured.\nRefer to the console for more details."
 end
 computer.stop()
end

if (hasPanel) then infoScreen.text = "Refill complete.\nWaiting for transitting items." end
 --continue passing parts through untill all parts have arrived or times out
 pinfo("Starting passthru mode.")
 while itemsInTransit > 0 and not timedOut do
 processPassthruInputs()
 updateInfo()
 checkEvents()
 if(computer.millis() - lastTransferTime > refillTimeOut) then
  timedOut = true
  pinfo("Timed out")
  local n = ""
  for _, infoTable in pairs(slotsToRefill) do
   if(not infoTable["mrgrId"]) then
    n = n .. infoTable["name"] .. ", "
   end  
  end
  pinfo("Missing " .. string.sub(n, 1, -3))
 end
end

updateInfo()
if(passthruMode) then
 passthruMode = false
 lever.state = false
end
computer.beep()
pinfo("Done")

if (hasPanel) then
 infoScreen.text = "Transitting complete.\nWaiting to start..."
 goto startMain
end
