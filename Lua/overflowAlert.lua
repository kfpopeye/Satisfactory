--scans the container and creates a table of anything therein
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
   print(i, lowInventories[intName], lowInventories[intName]["count"], lowInventories[intName]["max"])
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

function setLight(x)
 if (x > 0) then
  light:setColor(255, 255, 0, 255)
 else
  light:setColor(0, 0, 0, 0)
 end 
end

--the main loop
function main()
 while true do
  local inventory = createInventoryList()
  local x = tableLength(inventory)
  setLight(x)
  event.pull(15.0)
 end
end

--main chunk (setup)
container = component.proxy("9F1ADF3D4830D68D92EAA6B8BC63D066")
if not container then error("No container found!") end
lightpole = component.proxy("8B52AE6947429C102FDA78B05FCD9DC8")
if not lightpole then error("No light pole found!") end
light = lightpole:getModule(0, light)
if not light then error("No light found!") end

local status, err = pcall(main)
if not status then
 light:setColor(255, 0, 0, 255)
 print(err)
end
