-- -------------------------------------------------------------
-- |                                                           |
-- |   projectProduction.lua                                    |
-- |                                                           |
-- -------------------------------------------------------------
computer.log(1, "--- Project Production ---")

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

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
 return num
end

function displayManufacturer(m)
 clearScreen(gpu)
 print(m.internalName)
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-55s", "Project Component Production")) --55 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 gpu:setText(0, 1, "Device: " .. m:getType().displayName)
 gpu:setText(0, 2, "Recipe: " .. m:getRecipe().Name)
 local num = tableLength(m:getRecipe():getIngredients())
 gpu:setText(0, 3, "        Requires " .. num .. " ingredients.")
 local prod = makePercentage(m.Productivity)
 if prod < 100 then gpu:setForeground(1,1,0,1) end
 gpu:setText(0, 4, "Productivity: " .. prod .. "%")
 gpu:setForeground(1,1,1,1)

 local invs = m:getInputInv()
 local i = 0
 local row = 7
 gpu:setText(0, 6, "Input Inventories ------------------------------------------------------------------")
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
  else
   gpu:setText(0, row, "Empty")
   row = row + 1
  end
  i = i + 1
 end

 gpu:flush()
end

function loop()
 while true do
  -- assembler
  local device = component.proxy("5198135C41F35DC42D08C6B1BDF29E69")
  if device then displayManufacturer(device) else print("Machine #1 not found") end
  event.pull(5.0)
  -- particle accelerator
  device = component.proxy("01564603469D22B479BDD8B89332F453")
  if device then displayManufacturer(device) else print("Machine #2 not found") end
  event.pull(5.0)
  -- manufacturer #1
  device = component.proxy("3D1D25B64C1E87F9C527FAADDC4FEAB6")
  if device then displayManufacturer(device) else print("Machine #3 not found") end
  event.pull(5.0)
  -- assembler #2
  device = component.proxy("A257C42E40709C9B9B3C21A6317EC9A0")
  if device then displayManufacturer(device) else print("Machine #4 not found") end
  event.pull(5.0)
 end
end

--main chunk
local gpus = computer.getPCIDevices(classes.GPUT1)
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("B8801F4F425AF40E782CD7A53D7F1526")
if not screen then error("No screen") end

gpu:bindScreen(screen)
gpu:setSize(55, 12)
clearScreen(gpu)

local status, err = pcall(loop)
if not status then
 print(err)
end
