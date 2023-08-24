-- IF the string is more than 1 word (contains spaces) and greater than 5 characters
-- this will remove all lowercase letters, remove all dashes and convert spaces to periods
function createAbbrev(s)
 if (string.find(s, "%s")) then
  if (s:len() > 5) then
   return string.gsub(string.gsub(string.gsub(s, "%l", ""), "%s", "."), "%-", "")
  end
 end
 return s
end

function round(n)
 return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function makePercentage(x)
 local num = x * 100
 num = round (num)
 return num
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

function convertToTime(ms)
 local tenths = ms // 100
 local hh = (tenths // (60 * 60 * 10)) % 24
 local mm = (tenths // (60 * 10)) % 60
 local ss = (tenths // 10) % 60
 local t = tenths % 10
 return string.format("%02d:%02d:%02d.%01d", hh, mm, ss, t)
end

function displayContainers()
 local containers = component.proxy(component.findComponent("STORAGE"))
 if not containers then error("Containers was nil") end
 print("Number of containers: " .. tableLength(containers))
 if (tableLength(containers) == 0) then return end

 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 21, string.format("%-64s", "Container Inventory")) --65 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local row = 22
 local col = 1
 for _, cntr in pairs(containers) do
  --print ("Type: " .. cntr:getType().displayName)
  local invs = cntr:getInventories()[1]
  local count = 0
  local max = -1
  local name = cntr.nick:sub(9)
  local i = 0

  while (i < invs.Size) do
   local t = nil
   local stack = invs:getStack(i)
   if (stack.item) then t = stack.item.type end
   if(t) then
    count = count + stack.count
    max = t.max * invs.Size
   end
   i = i + 1
  end --while

  if (row > 25 and col == 1) then
   col = 30
   row = 22
  end

  local percentage = makePercentage(count / max)
  gpu:setText(col, row, string.format("%-20s", name) .. string.format("%3s", percentage) .. "%")
  net:broadcast(port, "container", name, percentage)
  row = row + 1
 end --for
end

function displayFactories()
 gpu:setBackground(0, 0.5, 1.0, 0.5)
 gpu:setForeground(0, 0, 0, 1)
 gpu:setText(0, 0, string.format("%-64s", "Factories Output\\Input Status")) --65 chars (padded with spaces after)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(1,1,1,1)

 local factories = component.proxy(component.findComponent(siteNick))
 if not factories then error("Factories was nil") end
 print("Number of factories: " .. tableLength(factories))

 local row = 0
 local invsSize = 0
 for _, fctry in pairs(factories) do
  local data_output = " OUT> "
  local data_input = " IN> "
  row = row + 1
  local invs

  if (fctry:getType().Name == "Build_GeneratorNuclear_C") then

   local n = fctry:getInventories()[1] -- 1 output inventory (waste)
   data_output = data_output .. "Nuclear Waste: " .. n.itemCount .. " "
   n = fctry:getInventories()[2] -- 2 fuel inventory (water)
   data_input = data_input .. "Water: " .. makePercentage(n.itemCount/50000) .. "% "
   n = fctry:getInventories()[3] -- 3 inventory potential (rods)
   data_input = data_input .. "Rods :" .. n.itemCount
  
   local name = fctry.nick:sub(siteNick:len() + 2) --removes "ATOMICBAY "
   local prod = makePercentage(fctry.productivity)
   gpu:setText(1, row, (name .. " (" .. prod .. "%)" .. data_output))
   row = row + 1
   local indent = " "
   while (indent:len() < (name:len() + tostring(prod):len() + 4)) do indent = indent .. " " end
   gpu:setText(1, row, indent .. data_input)
   net:broadcast(port, "factory", name, data_output, data_input, prod)

  else

   local rec = fctry:getRecipe()
   --print(fctry:getType().Name .. " Nick:" .. fctry.nick .. " Recipe:" .. rec.name  .. " Prod:" .. makePercentage(fctry.productivity) .. "%")
   invs = fctry:getOutputInv()
   invsSize = invs.Size - 1 -- Satisfactory reports back incorrect number HACK

   -- summarizes output products
   local rec_prod = rec:getProducts()
   --print("    Outputs: " .. invsSize)
   --print("        Number of products: " .. tableLength(rec_prod))
   local prodTable = {}
   for _, prodType in pairs(rec_prod) do
    local n = createAbbrev(prodType.Type.Name)
    prodTable[n] = "0%"
   end

   local i = 0
   while (i < invsSize) do
    local t = nil
    local stack = invs:getStack(i)
    if (stack.item) then t = stack.item.type end
    if (t) then
     local c = stack.count
     local m = t.max
     local n = createAbbrev(t.name)
     prodTable[n] = makePercentage(c/m) .. "%"
    end --if   
    i = i + 1
   end --while

   for name, amnt in pairs(prodTable) do data_output = data_output .. name .. ":" .. amnt .. " " end
   --print("        " .. data_output)

   -- summarizes input ingredients
   invs = fctry:getInputInv()
   invsSize = invs.Size
   --print("    Number of inputs: " .. invsSize)
   local rec_ingred = rec:getIngredients()
   --print("    Number of ingrediants: " .. tableLength(rec_ingred))
   local ingredTable = {}
   for _, ingredType in pairs(rec_ingred) do
    local n = createAbbrev(ingredType.Type.Name)
    ingredTable[n] = "0%"
   end
   i = 0
   while (i < invsSize) do
    local t = nil
    local stack = invs:getStack(i)
    if (stack.item) then t = stack.item.type end
    if (t) then
     local c = stack.count
     local m = t.max
     local n = createAbbrev(t.name)
     ingredTable[n] = makePercentage(c/m) .. "%"
    end --if   
    i = i + 1
   end --while

   for name, amnt in pairs(ingredTable) do data_input = data_input .. name .. ":" .. amnt .. " " end
   --print("        " .. data_input)

   -- outputs factory summaries to screen and network
   local name = fctry.nick:sub(siteNick:len() + 2) --removes "ATOMICBAY "
   local productivity = makePercentage(fctry.productivity)
   gpu:setText(1, row, (name .. " (" .. productivity .. "%)" .. data_output))
   row = row + 1
   local indent = " "
   while (indent:len() < (name:len() + tostring(productivity):len() + 4)) do indent = indent .. " " end
   gpu:setText(1, row, (indent .. data_input))
   net:broadcast(port, "factory", name, data_output, data_input, productivity)
  end --if nuclear plant
 end --for
end

--main chunk
local gpus = computer.getPCIDevices(findClass("GPUT1"))
gpu = gpus[1]
if not gpu then error("No GPU T1 found!") end

local screen = component.proxy("D7EBEEC6426C054B81264CA836E56FCC")
if not screen then error("No screen") end

net = computer.getPCIDevices(findClass("NetworkCard"))[1]
if not net then error("No network card") end

--ATOMICBAY 42
-- ATOMICAVE 43
port = 43
siteNick = "ATOMICCAVE"

gpu:bindScreen(screen)
gpu:setSize(65, 27)

while true do
 clearScreen(gpu)
 displayFactories()
 displayContainers()
 gpu:setText(0, 26, "Run time: " .. convertToTime(computer.millis()))
 gpu:flush()
 event.pull(5)
end
