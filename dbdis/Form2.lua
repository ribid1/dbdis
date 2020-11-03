local vars, page
local leftcolumn
local rightcolumn
local notused

local function calcDistance(column)
	local i, j, k, l
	local totalhight = 0
	local icalc = 0
	local paired
	local timeSw_val, engineSw_val
	local drawcolumn = {}
	local ycalc = 0
	local yborder = 6
	local iRaender = 2
	
	-- was wird angezeigt, was nicht
	for i,j in ipairs(column) do
		paired = false
		if #vars[page].cd[j].sensors > 0 then 
			for k,l in ipairs(vars[page].cd[j].sensors) do
				if vars[l][2] ~= 0 then paired = true end
			end
		else
			paired = true	
			if j == "FlightTime" then
				 timeSw_val = system.getInputsVal(vars.timeSw)
				 if not (vars.timeSw ~= nil and timeSw_val ~= 0.0) then paired = false end
			end
			if j == "EngineTime" then
				engineSw_val = system.getInputsVal(vars.engineSw)
				if not (vars.engineSw ~= nil and engineSw_val ~= 0.0) then paired = false end
			end
		end
		if j == "UsedCapacity" and Calca_dispFuel then paired = true end
		if j == "Status1" and Global_TurbineState then paired = true end
		if j == "Status2" and Global_TurbineState2 then paired = true end
		if paired then
			vars[page].cd[j].visible = true
			table.insert(drawcolumn, j)
		else
			vars[page].cd[j].visible = false
		end
	end
	
	for i,j in ipairs(drawcolumn) do
		totalhight = totalhight + vars[page].cd[j].y
		vars[page].cd[j].sepdraw = vars[page].cd[j].sep
		vars[page].cd[j].distdraw = vars[page].cd[j].dist
		if vars[page].cd[j].sep == -1 then 
			totalhight = totalhight + yborder
		end
		if i < #drawcolumn then
			if vars[page].cd[j].sep > 0 then -- Box mit Trennzeichen
				if vars[page].cd[drawcolumn[i + 1]].sep == -1 then   -- nachfolgend hat eine Box
					vars[page].cd[j].sepdraw = 0
					if vars[page].cd[j].dist > -9 then  -- Distanz angegeben
						totalhight = totalhight + vars[page].cd[j].dist
					else --Distanz wird berechnet
						icalc = icalc + 1
					end
				else  -- nachfolgend hat keine Box
					totalhight = totalhight + vars[page].cd[j].sep
					if vars[page].cd[j].dist > -9 then  -- Distanz angegeben
						totalhight = totalhight + vars[page].cd[j].dist * 2
					else --Distanz wird berechnet
						icalc = icalc + 2
					end
				end
			else -- Box ohne Trennzeichen
				if vars[page].cd[j].dist > -9 then    -- Distanz angegeben
					totalhight = totalhight + vars[page].cd[j].dist
				else --Distanz wird berechnet
					icalc = icalc + 1
				end
			end
		else
			if vars[page].cd[j].dist > -9 then
				totalhight = totalhight + vars[page].cd[j].dist
				iRaender = 1
			end
			vars[page].cd[j].sepdraw = 0
		end
	end

	ycalc = math.floor((160 - totalhight) / (icalc + iRaender))
	
	for i,j in ipairs(drawcolumn) do
		if vars[page].cd[j].dist == -9 then 
			vars[page].cd[j].distdraw = ycalc
		end
	end
	
	--print(ycalc)
	return drawcolumn, math.floor((160 - totalhight - icalc * ycalc) / iRaender), ycalc
	
end
local function save_txt()
		local filename 
		if vars.template[page] then filename = "Apps/"..vars.appName.."/template_c"..page..".txt"
			else filename = "Apps/"..vars.appName.."/"..vars.model.."_c"..page..".txt"
		end
		local file = io.open(filename, "w+")
		local i, line
		if file then
			for i, line in ipairs(vars[page].leftcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page].cd[line].sep,"   ", vars[page].cd[line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars[page].rightcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page].cd[line].sep,"   ", vars[page].cd[line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars[page].notused) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page].cd[line].sep,"   ", vars[page].cd[line].dist, "\n")  
			end
			io.close(file)
		end
		collectgarbage()
end

local function load_txt()
  local line
  local i, t
  local column = "left"
  local value
  local file
  local temp = {}
  
  if not vars.template[page] then file = io.open("Apps/"..vars.appName.."/"..vars.model.."_c"..page..".txt", "r") end
  if not file then file = io.open("Apps/"..vars.appName.."/".."Template_c"..page..".txt", "r") end
  if file then
	vars[page].leftcolumn = {}
	vars[page].rightcolumn = {}
	vars[page].notused = {}
	line = io.readline(file)
	repeat
		if column == "left" then
			if line ~= "---" then
				table.insert(vars[page].leftcolumn, line)
				temp[line] = true
				i = 0
				for value in string.gmatch(io.readline(file), "%S+") do 
					i = i + 1
					if vars[page].cd[line] then
						if value then 
							if i == 1 then 
								vars[page].cd[line].sep = tonumber(value) 
							elseif i == 2 then 
								vars[page].cd[line].dist = tonumber(value) 
							end
						end
					else
						table.remove(vars[page].leftcolumn)
					end
				end
			else 
				column = "right"
			end	
		elseif column == "right" then 
			if line ~= "---" then
				table.insert(vars[page].rightcolumn, line)
				temp[line] = true
				i = 0
				for value in string.gmatch(io.readline(file), "%S+") do 
					i = i + 1
					if vars[page].cd[line] then
						if value then 
							if i == 1 then 
								vars[page].cd[line].sep = tonumber(value) 
							elseif i == 2 then 
								vars[page].cd[line].dist = tonumber(value) 
							end
						end
					else
						table.remove(vars[page].rightcolumn)
					end
				end
			else 
				column = "notused"
			end	
		else
			table.insert(vars[page].notused, line)
			temp[line] = true
			i = 0
			for value in string.gmatch(io.readline(file), "%S+") do 
				i = i + 1
				if vars[page].cd[line] then
					if value then 
						if i == 1 then 
							vars[page].cd[line].sep = tonumber(value) 
						elseif i == 2 then 
							vars[page].cd[line].dist = tonumber(value) 
						end
					end
				else
					table.remove(vars[page].notused)
				end
			end
		end
		line = io.readline(file)
	until (not line)
	io.close(file)
	
	for _, t in ipairs(leftcolumn) do 
		if not temp[t] then table.insert(vars[page].notused, t) end
	end
	for _, t in ipairs(rightcolumn) do 
		if not temp[t] then table.insert(vars[page].notused, t) end
	end
	for _, t in ipairs(notused) do 
		if not temp[t] then table.insert(vars[page].notused, t) end
	end
  end
  collectgarbage()
end

local function saveOrder()
		local filename 
		local i, v
		local cs = {}
		
		for i, v in pairs(vars[page].cd) do
			cs[i] = {}
			cs[i].sep = v.sep
			cs[i].dist = v.dist
		end
		
		local obj = json.encode({leftcolumn = vars[page].leftcolumn, rightcolumn = vars[page].rightcolumn, notused = vars[page].notused, cs = cs})
		if vars.template[page] then filename = "Apps/"..vars.appName.."/template_c"..page..".jsn"
			else filename = "Apps/"..vars.appName.."/"..vars.model.."_c"..page..".jsn"
		end
		local file = io.open(filename, "w+")
		
		if file then
			io.write(file,obj)
			io.close(file)
		end
		vars[page].leftdrawcol, vars[page].leftstart = calcDistance(vars[page].leftcolumn)
		vars[page].rightdrawcol, vars[page].rightstart = calcDistance(vars[page].rightcolumn)
		calcDistance(vars[page].notused)
		save_txt()
		collectgarbage()
end

local function loadOrder()
	local t, i, v
	local file = nil
	local exist ={}
	local fname
	local ftxtda = false

	if not vars.template[page] then file = io.readall("Apps/"..vars.appName.."/"..vars.model.."_c"..page..".jsn", "r") end
	if not file then		
		if io.rename("Apps/"..vars.appName.."/"..vars.model.."_O.txt","Apps/"..vars.appName.."/"..vars.model.."_c"..page..".txt") then
			file = nil
		else
			file = io.readall("Apps/"..vars.appName.."/".."Template_c"..page..".jsn", "r")
		end
	end
	if file then
		local obj = json.decode(file)
		if obj then
			vars[page].leftcolumn = obj.leftcolumn
			for i, v in ipairs(vars[page].leftcolumn) do exist[v] = true end
			vars[page].rightcolumn = obj.rightcolumn
			for i, v in ipairs(vars[page].rightcolumn) do exist[v] = true end
			vars[page].notused = obj.notused
			for i, v in ipairs(vars[page].notused) do exist[v] = true end
			if next(obj.cs) ~= nil then
				for i, v in pairs(obj.cs) do
					vars[page].cd[i].sep = math.floor(v.sep)
					vars[page].cd[i].dist = math.floor(v.dist)
				end
			end
			for _, t in ipairs(leftcolumn) do 
				if not exist[t] then table.insert(vars[page].notused, t) end
			end
			for _, t in ipairs(rightcolumn) do 
				if not exist[t] then table.insert(vars[page].notused, t) end
			end
			for _, t in ipairs(notused) do 
				if not exist[t] then table.insert(vars[page].notused, t) end
			end
			
		end
	else
		load_txt()
	end
	if not vars[page].leftcolumn then
		vars[page].leftcolumn = leftcolumn
		vars[page].rightcolumn = rightcolumn
		vars[page].notused = notused
	end
	collectgarbage()
end

local function moveLine(back)
	local startleft = 5
	local rowsleft = #vars[page].leftcolumn
	local startright = startleft + rowsleft + 2
	local rowsright = #vars[page].rightcolumn
	local startnotused = startright + rowsright + 2
	local rowsnotused = #vars[page].notused
	local row = form.getFocusedRow()
	if back then
		if row < startleft then
			form.setFocusedRow(row - 1)
		elseif row == startleft then
			table.insert(vars[page].notused, vars[page].leftcolumn[1])
			table.remove(vars[page].leftcolumn, 1)
			form.setFocusedRow(startnotused + rowsnotused - 1)
		elseif row < startleft + rowsleft then
			vars[page].leftcolumn[row - startleft],vars[page].leftcolumn[row - startleft + 1]  = vars[page].leftcolumn[row - startleft + 1], vars[page].leftcolumn[row - startleft]
			form.setFocusedRow(row - 1)
		elseif row < startright then
			form.setFocusedRow(row -1)
		elseif row == startright then
			table.insert(vars[page].leftcolumn, vars[page].rightcolumn[1])
			table.remove(vars[page].rightcolumn, 1)
			form.setFocusedRow(startleft + rowsleft)
		elseif row < startright + rowsright then
			vars[page].rightcolumn[row - startright],vars[page].rightcolumn[row - startright + 1]  = vars[page].rightcolumn[row - startright + 1], vars[page].rightcolumn[row - startright]
			form.setFocusedRow(row - 1)
		elseif row < startnotused then
			form.setFocusedRow(row - 1)
		elseif row < startnotused + rowsnotused then
			table.insert(vars[page].rightcolumn, vars[page].notused[row - startnotused + 1])
			table.remove(vars[page].notused, row - startnotused + 1)
			form.setFocusedRow(startright + rowsright)
		else
			form.setFocusedRow(row -1)
		end
	else
		if row < startleft then
			form.setFocusedRow(row + 1)
		elseif row < startleft + rowsleft - 1 then
			vars[page].leftcolumn[row - startleft + 2],vars[page].leftcolumn[row - startleft + 1]  = vars[page].leftcolumn[row - startleft + 1], vars[page].leftcolumn[row - startleft + 2]
			form.setFocusedRow(row + 1)
		elseif row == startleft + rowsleft - 1 then
			table.insert(vars[page].rightcolumn,1, vars[page].leftcolumn[rowsleft])
			table.remove(vars[page].leftcolumn, rowsleft)
			form.setFocusedRow(startright - 1)
		elseif row < startright then
			form.setFocusedRow(row + 1)
		elseif row < startright + rowsright - 1 then
			vars[page].rightcolumn[row - startright + 2],vars[page].rightcolumn[row - startright + 1]  = vars[page].rightcolumn[row - startright + 1], vars[page].rightcolumn[row - startright + 2]
			form.setFocusedRow(row + 1)
		elseif row == startright + rowsright -1 then
			table.insert(vars[page].notused,1, vars[page].rightcolumn[rowsright])
			table.remove(vars[page].rightcolumn, rowsright)
			form.setFocusedRow(startnotused - 1)
		elseif row < startnotused then
			form.setFocusedRow(row + 1)
		elseif row < startnotused + rowsnotused then
			table.insert(vars[page].leftcolumn, 1, vars[page].notused[row - startnotused + 1])
			table.remove(vars[page].notused, row - startnotused + 1)
			form.setFocusedRow(startleft)
		else
			form.setFocusedRow(row + 1)
		end
	end
	saveOrder()
	collectgarbage()
end

local function init(varstemp, pagetemp)
	vars = varstemp
	page = pagetemp
	vars[page] = {}
	vars[page].cd = {}
	vars.template = {}
	vars.template[page] = system.pLoad("template"..page, 1) == 1 and true or false
	
	leftcolumn = {"TotalCount", "FlightTime", "EngineTime", "Rx1Values", "RPM", "Altitude", "Vario", "Status"}
	rightcolumn = {"Volt_per_Cell", "UsedCapacity", "Current", "Pump_voltage", "I_BEC", "Temp", "Throttle", "PWM", "C1_and_I1", "C2_and_I2", "U1_and_Temp", "U2_and_OI", "Status2"}
	notused = {"Speed", "Rx2Values", "RxBValues"}
	
	-- first value means the thickness of the seperator
	-- second value means the distance between the boxes, -10 means the distance is calculated
	vars[page].cd.TotalCount = {sep = 0, dist = -9, y = 9, sensors = {}} 		-- TotalTime
	vars[page].cd.FlightTime = {sep = 0, dist = -9, y = 17, sensors = {}}  	-- FlightTime
	vars[page].cd.EngineTime = {sep = 2, dist = -9, y = 12, sensors = {}}  	-- EngineTime
	vars[page].cd.Rx1Values = {sep = 2, dist = -9, y = 29, sensors = {}}	-- Rx1 values
    vars[page].cd.Rx2Values = {sep = 2, dist = -9, y = 29, sensors = {}}	-- Rx2 values
    vars[page].cd.RxBValues = {sep = 2, dist = -9, y = 29, sensors = {}}	-- RxB values  
	vars[page].cd.RPM = {sep = 2, dist = -9, y = 37, sensors = {"rotor_rpm_sens"}}    		-- rpm
	vars[page].cd.Altitude = {sep = 1, dist = -9, y = 17, sensors = {"altitude_sens"}}   		-- altitude
	vars[page].cd.Speed = {sep = 1, dist = -9, y = 17, sensors = {"speed_sens"}}   		-- speed
	vars[page].cd.Vario = {sep = 2, dist = -9, y = 18, sensors = {"vario_sens"}}   		-- vario
	vars[page].cd.Status = {sep = 1, dist = -9, y = 12, sensors = {"status_sens"}}    	-- Status1
	vars[page].cd.Status2 = {sep = 1, dist = -9, y = 12, sensors = {"status2_sens"}}    	-- Status1
	vars[page].cd.Volt_per_Cell = {sep = 2, dist = -9, y = 27, sensors = {"battery_voltage_sens"}} 			-- battery voltage
	vars[page].cd.UsedCapacity = {sep = 2, dist = -9, y = 35, sensors = {"used_capacity_sens"}} 	-- used capacity
	vars[page].cd.Current = {sep = 2, dist = -9, y = 17, sensors = {"motor_current_sens"}}   		-- Current
	vars[page].cd.Pump_voltage = {sep = 1, dist = -9, y = 18, sensors = {"pump_voltage_sens"}}    -- Pump voltage
	vars[page].cd.I_BEC = {sep = 1, dist = -9, y = 17, sensors = {"bec_current_sens"}}     		-- IBEC
	vars[page].cd.Temp = {sep = 1 , dist = -9, y = 17, sensors = {"fet_temp_sens"}}      		-- Temperature
	vars[page].cd.Throttle = {sep = 1, dist = -9, y = 17, sensors = {"throttle_sens"}}    	-- Throttle
	vars[page].cd.PWM = {sep = 1, dist = -9, y = 17, sensors = {"pwm_percent_sens"}}      	-- PWM
	vars[page].cd.C1_and_I1 = {sep = 1, dist = -9, y = 16, sensors = {"UsedCap1_sens", "I1_sens"}}      	-- CI1
	vars[page].cd.C2_and_I2 = {sep = 1, dist = -9, y = 16, sensors = {"UsedCap2_sens", "I2_sens"}}      	-- CI2
	vars[page].cd.U1_and_Temp = {sep = 1, dist = -9, y = 16, sensors = {"U1_sens", "Temp_sens" }}    -- U1 and Temp
	vars[page].cd.U2_and_OI = {sep = 1, dist = -9, y = 12, sensors = {"U2_sens", "OverI_sens"}}      -- U2 and OverI
	
	loadOrder()
	vars[page].leftdrawcol, vars[page].leftstart, vars[page].ycalcLeft = calcDistance(vars[page].leftcolumn)
	vars[page].rightdrawcol, vars[page].rightstart, vars[page].ycalcRight = calcDistance(vars[page].rightcolumn)
	calcDistance(vars[page].notused)
	

	collectgarbage()
	return vars
end

local function setup(varstemp, pagetemp)
	local i, j
	local value
	local template = {}
	
	init(varstemp, pagetemp)
	
  	form.setTitle(vars.trans.Layout.." "..vars.trans.Page.." "..page)
	
	form.addSpacer(320,5)
	
	form.addRow(2)
	form.addLabel({label = "Template:", width = 270})
	template[page] = form.addCheckbox(vars.template[page], 
				function(value)
					vars.template[page] = not value
					system.pSave("template"..page, not value and 1 or 0)
					form.setValue(template[page], not value)	
				end)

	form.addSpacer(320,10)
	form.addRow(2)
	form.addLabel({label = (vars.trans.Leftrow.." ("..vars[page].ycalcLeft..")"), font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

			
	for i,j in ipairs(vars[page].leftcolumn) do	
		if vars[page].cd[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page].cd[j].y..")",font = FONT_NORMAL, width = 210})
			form.addIntbox(vars[page].cd[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page].cd[j].sep = value
								saveOrder()
							end, {font = fontLabel, width = 50})
			form.addIntbox(vars[page].cd[j].dist, -9, 160, -9, 0, 1,
							function (value)
								vars[page].cd[j].dist = value
								saveOrder()
							end, {font = fontLabel, width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
		end
	end
	
	--form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = "----------------------------------------------------------"})
	form.addRow(2)
	form.addLabel({label = (vars.trans.Rightrow.." ("..vars[page].ycalcRight..")"), font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

	for i,j in ipairs(vars[page].rightcolumn) do
		if vars[page].cd[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page].cd[j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars[page].cd[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page].cd[j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars[page].cd[j].dist, -9, 160, -9, 0, 1,
							function (value)
								vars[page].cd[j].dist = value
								saveOrder()
							end, {width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
		end
	end
	
	--form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = "----------------------------------------------------------", enabled = false})
	form.addRow(2)
	form.addLabel({label = vars.trans.notused, font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})
	
	for i,j in ipairs(vars[page].notused) do
		if vars[page].cd[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page].cd[j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars[page].cd[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page].cd[j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars[page].cd[j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars[page].cd[j].dist = value
								saveOrder()
							end, {width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
		end
	end
	
	form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = vars.trans.explDist, font = FONT_MINI, enabled = false})
	form.addRow(1)
	form.addLabel({label = vars.trans.explSep, font = FONT_MINI, enabled = false})   
	collectgarbage()

	return (vars)
end

local function saveAkkus()
	local i, j
	table.sort(vars.Akkus, function (i,j) return i.ID < j.ID end)
	vars.AkkusID ={}
	for i,j in ipairs(vars.Akkus) do
		vars.AkkusID[math.floor(j.ID)]= i
	end
	local obj = json.encode(vars.Akkus)
	local file = io.open("Apps/"..vars.appName.."/Akkus.jsn", "w+")
	if file then
		io.write(file,obj)
		io.close(file)
	end
	collectgarbage()
end

local function initBat(varstemp)
	local i
	local j = 1
	vars = varstemp
	vars.Akkus = {}
	vars.AkkusID = {}
	local file = io.readall("Apps/"..vars.appName.."/Akkus.jsn")
	if file then
		local obj = json.decode(file)
		if obj then
			vars.Akkus = obj
			for i = 1, #vars.Akkus do
				if vars.Akkus[i].ID ~= -1.0 then
					if i ~= j then
						vars.Akkus[j] = vars.Akkus[i]
						vars.Akkus[i] = nil
					end
					j = j + 1
				else
					vars.Akkus[i] = nil
				end
			end
			saveAkkus()
		end
	end
	collectgarbage()
	return vars
end



local function setupBat(varstemp)
	local i, j
	local IDmax
	local strValue
	initBat(varstemp)
	
	form.setTitle(vars.trans.Layout.." Akku")
	form.setTitle("ID       Name         S      mAh     C")
	form.addRow(1)
	form.addLabel({label =vars.trans.headerAkku, font = FONT_MINI, enabled=false})
	
	--form.addLabel({label=vars.trans.capacitymAh, width=210})
	--form.addLabel({label=vars.trans.cellcnt, width=210})
	if vars.addAkku == 1 then
		vars.addAkku = 0
		IDmax = 0
		for i in ipairs(vars.Akkus)  do
			if vars.Akkus[i].ID > IDmax then IDmax = vars.Akkus[i].ID end
		end
		IDmax = IDmax + 1
		i = #vars.Akkus + 1
		vars.Akkus[i] = {} 
		vars.Akkus[i].ID = IDmax
		vars.Akkus[i].batC = 0
		vars.Akkus[i].Name = ""
		vars.Akkus[i].Capacity = 0
		vars.Akkus[i].iCells = 1
		vars.Akkus[i].Cycl = 0
		vars.Akkus[i].Ah = 0
		vars.Akkus[i].lastVoltage = 0
		vars.Akkus[i].usedCapacity = 0
		saveAkkus()
	end
	
	
	-- if #vars.Akkus > 0 then 
		-- form.addSpacer(320,5)
		-- --form.addRow(1)
		-- --form.addLabel({label = "----------------------------------------------------------", enabled = false})
	-- end
	
	for i, j in ipairs(vars.Akkus) do
		form.addSpacer(320,5)	
		form.addRow(5)
		form.addIntbox(j.ID, -1, 999, -1, 0, 1,
								function (value)
									j.ID = value		
									saveAkkus()
								end, {width = 52})
		form.addTextbox(j.Name, 7,
								function (value)
									j.Name = value
									saveAkkus()
								end, {width = 105})	
								
		form.addIntbox(j.iCells, 1, 14, 1, 0, 1,
								function (value)
									j.iCells = value
									saveAkkus()
								end, {width = 50} )

		form.addIntbox(j.Capacity, 0, 32767, 0, 0, 10,
								function (value)
									j.Capacity = value
									saveAkkus()
								end, {width = 60} )
		form.addIntbox(j.batC, 0, 90, 0, 0, 5,
								function (value)
									j.batC = value
									saveAkkus()
								end, {width = 50})

								
		form.addRow(3)			
	
		form.addIntbox(j.Cycl, 0, 9999, 0, 0, 1,
								function (value)
									j.Cycl = value
									saveAkkus()
								end, {width = 105, label = vars.trans.cycles})	
		form.addIntbox(math.floor(j.usedCapacity), 0, 9999, 0, 0, 10,
										function (value)
											j.usedCapacity = value
											saveAkkus()
										end, {label=" mAh", width = 102})					
		form.addIntbox(math.floor(j.Ah), 0, 9999, 0, 0, 1,
								function (value)
									j.Ah = value
									saveAkkus()
								end, {label=" Ah", width = 115})
				
	end
	form.addSpacer(320,5)
	form.addRow(1)
	form.addLabel({label =vars.trans.delete_Akku, font = FONT_MINI, alignRight=true, enabled=false})
	
	collectgarbage()
	return (vars)
end





return {

	setup = setup,
	init = init,
	moveLine = moveLine,
	setupBat = setupBat,
	initBat = initBat
  
}
