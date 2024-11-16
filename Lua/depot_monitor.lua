-- -------------------------------------------------------------
-- |                                                           |
-- |   depot_monitor.lua                                       |
-- |                                                           |
-- -------------------------------------------------------------

computer.log(1, "--- Depot Monitor ---")

groupName = "tickle" -- if all the codeable mergers are grouped, enter the group name inside the quotes otherwise
                     -- all codeable mergers will be used.
                     
function tableContains (T, h)
	for _, value in pairs(T) do
		if (value == h) then return true end
	end
	return false
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function mountDrive()
	hasHDD = false
	-- Shorten name
	fs = filesystem
	-- Initialize /dev
	if fs.initFileSystem("/dev") == false then
    	computer.panic("Cannot initialize /dev")
	end
	-- find HD
	local drive_uuid
	for idx, drive in pairs(fs.children("/dev")) do
		if(drive ~= "serial") then drive_uuid = drive end
	end
	-- Mount our drive to root
	if (drive_uuid) then
		fs.mount("/dev/" .. drive_uuid, "/")
	end
	if(fs.exists("/")) then
		print("Harddrive found. Data will be persistent.")
		hasHDD = true
	else
		print("NO harddrive found!")
	end
end

function saveData()
	if (not hasHDD) then return end
	
	local wroteData = false
	local dataFile
	local filePath = "/user.dat"
	if (fs.exists(filePath)) then
		dataFile = fs.remove(filePath)
	end
	dataFile = fs.open(filePath, "w")
	
	for i, s in pairs(itemList) do
		if(s["refill"]) then
			dataFile:write(s["type"].name, "\n")
			wroteData = true
		end
	end
	dataFile:close()
	if (not wroteData) then dataFile = fs.remove(filePath) end
end

function setupItemList()
	local userList = {}
	if(hasHDD) then
		local dataFile
		local filePath = "/user.dat"
		if (fs.exists(filePath)) then
			dataFile = fs.open(filePath, "r")
			local t1 = dataFile:read(999)
			dataFile:close()
			local i = 1
			for line in t1:gmatch("([^\n]*)\n?") do
		    	userList[i] = line
		    	i = i + 1
			end
		else
			print("User.dat file not found.")
		end		
	end
	
	local list = storage:getAllItemsFromCentralStorage()
	for i, s in pairs(list) do	
		--get item current and max amounts
		local info = {}
		info["count"] = storage:getItemCountFromCentralStorage(s.type)
		info["max"] = storage:getCentralStorageItemLimit(s.type)
		info["inTransit"] = 0
		info["type"] = s.type
		
		if(tableLength(userList) > 0) then
			if(tableContains(userList, s.type.name)) then
				info["refill"] = true
			else
				info["refill"] =  false
			end
		else
			info["refill"] =  false
		end
		
		table.insert(itemList, info)
	end
end

function refreshTabScreen(x, y)
	local w, h = gpu:getSize()
	-- clear background
	gpu:setBackground(0,0,0,0)
	gpu:fill(0, 0, w, h, " ")

	for i, s in pairs(itemList) do
		local itemInfo
		if(s["refill"]) then
			itemInfo = "[X] " .. s["type"].name .. "  (" .. s["count"] .. "/" .. s["max"] .. ")"
		else
			itemInfo = "[ ] " .. s["type"].name .. "  (" .. s["count"] .. "/" .. s["max"] .. ")"
		end
		if (s["inTransit"] > 0) then itemInfo = itemInfo .. "  <<<" end
		gpu:setText(0, i, itemInfo)
	end	
	
	if (x and y) then 
		Mx = x
		My = y
	end
	if (Mx and My) then
		local item = itemList[My]
		if (item) then
			gpu:setText(0, h-1, Mx .. "," .. My .. " - " .. item["type"].name)
		else
			gpu:setText(0, h-1, Mx .. "," .. My)
		end
	end

	gpu:flush()
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
		mergers = component.proxy(component.findComponent(classes.Build_CodeableMerger_C))
	else
		mergers = component.proxy(component.findComponent(groupName))
	end
	if tableLength(mergers) == 0 then error("No Codeable Mergers found!") end
	return mergers
end

function findMerger(theType)
 local intName = theType.internalName
 local dbgMsg = nil
 local returnMerger = nil
 local returnPort = -1
 local mergers = getMergers()

 for _, merger in pairs(mergers) do
  local x = 0
  dbgMsg = " Nick: " .. merger.nick
  while (x < 3) do
   local i = merger:getInput(x)
   if (i and i.type) then
    dbgMsg =  dbgMsg .. " - Port #" .. x .. " " .. i.type.name
    if i.type.internalName == intName then
     if not isPassThrough(merger, x) then
      returnMerger = merger
      returnPort = x
     else
      dbgMsg =  dbgMsg .. "(passthru)"
     end
    end
   else
    dbgMsg =  dbgMsg .. " - Port #" .. x .. " Empty"
   end
   x = x + 1
  end
  --print(dbgMsg)
 end
 return returnMerger, returnPort
end

function processPassthruInputs()
 local dbgMsg = nil
 local mergers = getMergers()

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
  --if (dbgMsg) then pdebug(dbgMsg) end
 end --endfor
end

function refillDepot()
	for _, item in ipairs(itemList) do
		if (item["refill"] and item["count"] + item["inTransit"] < item["max"]) then
			local merger, port = findMerger(item["type"])
			if(merger) then
		    	if merger.canOutput and merger:transferItem(port) then
		      		item["inTransit"] = item["inTransit"] + 1
		    	end
		    else
		    	print("No merger had " .. item["type"].name)
		    end
		end
	end
end

function processSyncSplitter()
	if not syncSplitter then return end
	
	if not depot.isUploadInventoryEmpty then return end
	
	local input = syncSplitter:getInput()
	if (input.type) then
		if (storage:canUploadItemsToCentralStorage(input.type)) then
			if (syncSplitter:canOutput(direction.middle)) then
				syncSplitter:transferItem(direction.middle)
			end
		else --send to sync
			if(syncSplitter:canOutput(direction.right)) then 
				syncSplitter:transferItem(direction.right)
				print("Sent to Awesome Sink: " .. input.type.name)
			end
		end
	end
end

-- ***************** main loop ********************
function mainLoop()
	while true do
		e, sndr, p1, p2, p3, p4 = event.pull(1)

		if e == "OnMouseDown" then
			print("poink!")
		elseif e == "OnMouseUp" then
			local item = itemList[p2]
			if (item) then itemList[p2]["refill"] = not itemList[p2]["refill"] end
			saveData()
		elseif e == "OnMouseMove" then
			refreshTabScreen(p1, p2)
		elseif e == "ItemRequest" then
			--if syncSplitter receives ite deduct from inTransit
			for _, item in ipairs(itemList) do
				if (item["type"] == type) then
					item["inTransit"] = item["inTransit"] - 1
					if (item["inTransit"] < 0) then item["inTransit"] = 0 end
					break
				end
			end
		elseif e == "ItemAmountUpdated" then
			--else if ddu receives item update item counts p1=type, p2=amount
			for _, item in ipairs(itemList) do
				if (item["type"] == p1) then
					item["count"] = p2
					break
				end
			end
	 	end
	 	refillDepot()
	 	processPassthruInputs()
	 	processSyncSplitter()
	 	refreshTabScreen()
	 end --end while
end

-- ***************** main chunk ********************
print("Starting main chunk.")

-- ***************** devices ********************
depot = component.proxy("A03353CE46B6FF779D4A0496078BFE45")
if not depot then error("No Dimensional Depot Uploader found!")end
storage = depot.centralStorage

-- get first T1 GPU avialable from PCI-Interface
gpu = computer.getPCIDevices(classes.GPUT1)[1]
if not gpu then error("No GPU T1 found!")end

-- get first Screen-Driver available from PCI-Interface
local screen = computer.getPCIDevices(classes.FINComputerScreen)[1]
-- if no screen found, try to find large screen from component network
if not screen then
	local comp = component.findComponent(classes.Screen)[1]
	if not comp then error("No Screen found!") end
	screen = component.proxy(comp)
end

-- syncSplitter is used to divert items to sync if depot can't take anymore
syncSplitter = component.proxy(component.findComponent("syncSplitter"))[1]

-- setup gpu
gpu:bindScreen(screen)
gpu:setSize(120, 50)

-- setup listeners
event.clear()
if(syncSplitter) then event.listen(syncSplitter) else print("No sync splitter.") end
event.listen(gpu)
event.listen(storage)

-- ***************** constants ********************
direction = {left = 2, middle = 1, right = 0}
itemList = {}

mountDrive()
setupItemList()
refreshTabScreen()
gpu:flush()

--call main loop
print("Calling main loop")
local status, err = pcall(mainLoop)
if not status then
 print(err)
 computer.beep()
 computer.beep()
end
