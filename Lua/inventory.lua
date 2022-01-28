-- takes an inventory table and outputs it to the screen tab
function printTable2TabScreen(invTable, row)
 for n, s in pairs(invTable) do
  gpu:setText(0, row, s["name"] .. ": " .. s["count"] .. "/" .. s["max"])
  row = row + 1
 end
end

-- output refill results to the screen tab
function printResults2Screen(invList)
-- resolution 120x30
 clearScreen()
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)
 if(tableLength(invList) > 0) then
  gpu:setText(0, 0, "A splitter for the following items could not be found:")
  printTable2TabScreen(invList, 1)
 else
  gpu:setText(0, 0, "Refill successful.")
 end
 gpu:flush()
end

--clears the screen tab
function clearScreen()
 w,h = gpu:getSize()
 gpu:setBackground(0,0,0,0)
 gpu:fill(0,0,w,h," ")
 gpu:flush()
end

-- displays information while refilling to the lower text display
-- if param is nil then buffer is cleared
function displayModeInfo(str)
 if(not modeBuffer) then modeBuffer = {} end
 -- line 1 reserved for title
 modeBuffer[1] = "      Mode Information"
 local display = panel:getModule(1, 0)
 display.size = 30
 display.text = " "

 if(str) then
  if(#modeBuffer == 4) then table.remove(modeBuffer, 2) end
  table.insert(modeBuffer, str)
 end
 -- output buffer to display
 local txt = nil
 for _, s in pairs(modeBuffer) do
  if(txt) then txt = txt .. s .. "\n" else txt = s .. "\n" end
 end
 display.text = txt
end

--displays general information to the upper text display
function displaySystemInfo()
 if(not infoBuffer) then infoBuffer = {} end
 local infoDisplay = panel:getModule(1, 2)
 infoDisplay.size = 27
 infoDisplay.text = " "
 -- line 1 reserved for title
 infoBuffer[1] = "      System Information"
 -- line 2 reserved for splitter count
 local splitters = component.proxy(component.findComponent(findClass("CodeableSplitter")))
 infoBuffer[2] = "Splitters: " .. #splitters
 -- line 3 reserved for greedy mode
 if(greedyMode) then infoBuffer[3] = "Greedy mode: On" else infoBuffer[3] = "Greedy mode: Off" end
 -- line 4 reserved for current mode
 if(currentMode == modes.refilling) then infoBuffer[4] = "Mode: Refilling" else infoBuffer[4] = "Mode: Processing" end

 -- output buffer to display
 local txt = nil
 for _, s in pairs(infoBuffer) do
  if(txt) then txt = txt .. s .. "\n" else txt = s .. "\n" end
 end
 infoDisplay.text = txt
end

--causes the indicator light to change colour every 2 seconds and runs displaySystemInfo()
function indicateProgress(reset)
 if(reset) then progTime = computer.millis() end
 if(computer.millis() - progTime < 2000) then
  indicatorLight:setColor(0, 0, 1, 5)
 elseif (computer.millis() - progTime > 2000) then
  displaySystemInfo()
  indicatorLight:setColor(0, 1, 0, 1)
 end
 if(computer.millis() - progTime > 4000) then
  progTime = computer.millis()
 end
end

--finds user specified direction of output to storage container. Returns -1 by default.
function getDefinedOutput(splitter)
 s = splitter.nick
 if(s:find("left")) then
  return direction.left
 elseif(s:find("middle")) then
  return direction.middle
 elseif(s:find("right")) then
  return direction.right
 end
 displayModeInfo("Output undefined: " .. splitter.nick)
 return -1
end

--find a splitter that currently has the item type in its inventory
function findSplitter(itemNameInternal)
 local splitters = component.proxy(component.findComponent(findClass("CodeableSplitter")))
 for _, splitter in pairs(splitters) do
  local i = splitter:getInput()
  if (i and i.type) then
   if (i.type.internalName == itemNameInternal) then
    return splitter
   end
  end
 end
 print("No splitter has: " .. itemNameInternal)
 return nil
end

function checkEvents()
 e, sender = event.pull(0)
 if (e == "Trigger" and sender == button) then
  computer.beep()
  button:setColor(1, 0, 0, 5)
  refillContainer()
 elseif (e == "Trigger" and sender == stopButton) then
  currentMode = modes.stopped
  indicateProgress()
  button:setColor(0, 0, 1, 5)
  indicatorLight:setColor(1, 0, 0, 5)
  computer.beep()
  computer.stop()
 elseif (e == "ChangeState" and sender == lever) then
  computer.beep()
  greedyMode = not greedyMode
 elseif (e == "ItemTransfer") then
  itemsInTransit = itemsInTransit - 1
 end
end

--scans the container and creates a list of anything thats a partial stack
function createInventoryList()
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
   print(i, intName, c, m)
  else
   print (i, "empty")
  end
  i = i + 1
 end
 return lowInventories
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--main loop when refilling the container
function refillContainer()
 local lastRefillTime = computer.millis()
 clearScreen()
 displayModeInfo()
 itemsInTransit = 0
 local lowInventories = createInventoryList()
 local n = tableLength(lowInventories)

 while(n > 0) do
  currentMode = modes.refilling
  indicateProgress()
  for intName, infoTable in pairs(lowInventories) do
   if(intName) then
    local spltr = findSplitter(intName)
    if(spltr) then
     local dir = getDefinedOutput(spltr)
     if (dir == -1) then
      print("No output direction defined for:", spltr.nick)
     elseif(spltr:transferItem(dir)) then
      lastRefillTime = computer.millis()
      itemsInTransit = itemsInTransit + 1
      lowInventories[intName]["count"] = lowInventories[intName]["count"] + 1
      print("Refilling at:", spltr.nick)
     end
     if(lowInventories[intName]["count"] >= lowInventories[intName]["max"]) then lowInventories[intName] = nil end
    else
     print("No splitter has: " .. intName)
    end
   end
  end
  if(itemsInTransit > 0) then displayModeInfo("Items transitting: " .. itemsInTransit) end
  displayModeInfo("Filling " .. n .. " slots.")
  checkEvents()
  if(not greedyMode) then processSplitters() end
  if(computer.millis() - lastRefillTime > refillTimeOut) then
   displayModeInfo(nil)
   displayModeInfo("Time out reached")
   n = 0
  else
   n = tableLength(lowInventories)
  end
 end

 displayModeInfo(nil)
 printResults2Screen(lowInventories)
 currentMode = modes.processing
end

-- cycle through all coadable splitters and cause them to transfer an item if able but not in the direction of the tickle trunk
function processSplitters()
 local splitters = component.proxy(component.findComponent(findClass("CodeableSplitter")))
 for _, splitter in pairs(splitters) do  
  local defOut = getDefinedOutput(splitter)
  for t, v in pairs(direction) do
   if(v ~= defOut) then
    if (splitter:canOutput(v) and splitter:getInput()) then
     if(splitter:transferItem(v)) then
      print("Processing at:", t, splitter.nick)
     end
    end
   end
  end
 end
end

--the main loop
function loop()
 while true do
  checkEvents()
  if(itemsInTransit > 0) then displayModeInfo("Items transitting: " .. itemsInTransit) else displayModeInfo() end
  button:setColor(0, 0, 1, 5)
  processSplitters()
  indicateProgress()
 end
end

--main chunk (setup)
modes = {processing = 0, refilling = 1, stopped = 2}
currentMode = modes.processing
direction = {left = 0, middle = 1, right = 2}
refillTimeOut = 5 * 60 * 1000 --5 min in ms

container = component.proxy("08BC875F4652A329EBC31793BFECB856")
panel = component.proxy("728C909D46AD5BBCC0F910AD60CE19F7")
lever = panel:getModule(5, 0)
indicatorLight = panel:getModule(0, 3)
stopButton = panel:getModule(9, 0)
button = panel:getModule(0, 0)
button:setColor(0, 0, 1, 5)

local screen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
if not screen then error("No Screen found!") end
gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then error("No GPU T1 found!") end
gpu:bindScreen(screen)
clearScreen()

greedyMode = false
progTime = computer.millis() -- progress time
itemsInTransit = 0

event.clear()
for _, connector in pairs(container:getFactoryConnectors()) do event.listen(connector) end
event.listen(lever)
event.listen(button)
event.listen(stopButton)

displayModeInfo()
loop()
