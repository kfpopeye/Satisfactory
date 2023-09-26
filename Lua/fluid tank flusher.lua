--the main loop
function main()
 while true do
  local level = container.fluidContent / container.maxFluidContent
  print("Fluid level = " .. level)
  if (level > .75) then
   print("Get outta the shower! I\'m flushing.")
   container:Flush()
  end
  event.pull(15.0)
 end
end

--main chunk (setup)
container = component.proxy("05B44ED14F2C7648DDBB19BEA59978BA")
if not container then error("No container found!") end

local status, err = pcall(main)
if not status then
 print(err)
end
