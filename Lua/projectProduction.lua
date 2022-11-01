function clearScreen(g)
 local w,h = g:getSize()
 g:setBackground(0, 0, 0, 0)
 g:setForeground(1, 1, 1, 1)
 g:fill(0, 0, w, h, " ")
end

function round(n)
 return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function makePercentage(x)
 local num = x * 100
 num = round (num)
 return num .. "%"
end

function displayManufacturer(m)
 clearScreen(gpu)
 print(m.internalName)
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-54s", "Project Component Production")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 gpu:setText(0, 1, "Device: " .. m.internalName)
 gpu:setText(0, 2, "Recipe: " .. m:getRecipe().Name)
 gpu:setText(0, 3, "Productivity: " .. makePercentage(m.Productivity))

 local invs = m:getInputInv()
 local i = 0
 local row = 5
 gpu:setText(0, 4, "Input Inventories ------------------------------------------------------------------")
 while (i < invs.Size) do
  local t = nil
  local stack = invs:getStack(i)
  if (stack.item) then t = stack.item.type end
  if(t) then
   local c = stack.count
   local m = t.max
   local n = t.name
   gpu:setText(0, row, n .. ": " .. c .. "/" .. m)
   row = row + 1
  end
  i = i + 1
 end

 gpu:flush()
end

function loop()
 while true do
  -- assembler
  local device = component.proxy("0A6C31324A7C46DDA492208DA283E78A")
  if device then displayManufacturer(device) end
  event.pull(5.0)
  -- particle accelerator
  device = component.proxy("FC82C7254610ACB66E7448997ABC247A")
  if device then displayManufacturer(device) end
  event.pull(5.0)
  -- manufacturer #1
  device = component.proxy("2118E96042B43F36CC1B98B2A8677EAA")
  if device then displayManufacturer(device) end
  event.pull(5.0)
  -- manufacturer #2
  device = component.proxy("49F4FD0B438AA551DC9509BE7762C838")
  if device then displayManufacturer(device) end
  event.pull(5.0)
 end
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("61BF6C8449CD3E52CF4615819277F011")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(55, 12)
clearScreen(gpu)

local status, err = pcall(loop)
if not status then
 print(err)
end
