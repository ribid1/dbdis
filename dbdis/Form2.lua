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
	
	for i,j in ipairs(column) do
		paired = false
		if #vars[page][j].sensors > 0 then 
			for k,l in ipairs(vars[page][j].sensors) do
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
		if j == "Status" and Global_TurbineState then paired = true end

		if paired then
			vars[page][j].visible = true
			table.insert(drawcolumn, j)
		else
			vars[page][j].visible = false
		end
	end
	
	for i,j in ipairs(drawcolumn) do
		totalhight = totalhight + vars[page][j].y
		vars[page][j].sepdraw = vars[page][j].sep
		vars[page][j].distdraw = vars[page][j].dist
		if vars[page][j].sep == -1 then 
			totalhight = totalhight + yborder
		end
		if i < #drawcolumn then
			if vars[page][j].sep > 0 then -- Box mit Trennzeichen
				if vars[page][drawcolumn[i + 1]].sep == -1 then   -- nachfolgend hat eine Box
					vars[page][j].sepdraw = 0
					if vars[page][j].dist > -9 then  -- Distanz angegeben
						totalhight = totalhight + vars[page][j].dist
					else --Distanz wird berechnet
						icalc = icalc + 1
					end
				else  -- nachfolgend hat keine Box
					totalhight = totalhight + vars[page][j].sep
					if vars[page][j].dist > -9 then  -- Distanz angegeben
						totalhight = totalhight + vars[page][j].dist * 2
					else --Distanz wird berechnet
						icalc = icalc + 2
					end
				end
			else -- Box ohne Trennzeichen
				if vars[page][j].dist > -9 then    -- Distanz angegeben
					totalhight = totalhight + vars[page][j].dist
				else --Distanz wird berechnet
					icalc = icalc + 1
				end
			end
		else
			vars[page][j].sepdraw = 0
		end
	end
	
	ycalc = math.floor((160 - totalhight) / (icalc + 2))
	
	for i,j in ipairs(drawcolumn) do
		if vars[page][j].dist == -9 then 
			vars[page][j].distdraw = ycalc
		end
	end
	
	--print(ycalc)
	return drawcolumn, math.floor((160 - totalhight - icalc * ycalc) / 2), ycalc
	
end

local function saveOrder()
		local filename 
		if vars[page].template then filename = "Apps/"..vars.appName.."/template_O"..page..".txt"
			else filename = "Apps/"..vars.appName.."/"..vars.model.."_O"..page..".txt"
		end
		local file = io.open(filename, "w+")
		local i, line
		if file then
			for i, line in ipairs(vars[page].leftcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page][line].sep,"   ", vars[page][line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars[page].rightcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page][line].sep,"   ", vars[page][line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars[page].notused) do 
				io.write(file, line, "\n") 
				io.write(file, vars[page][line].sep,"   ", vars[page][line].dist, "\n")  
			end
			io.close(file)
		end
		vars[page].leftdrawcol, vars[page].leftstart = calcDistance(vars[page].leftcolumn)
		vars[page].rightdrawcol, vars[page].rightstart = calcDistance(vars[page].rightcolumn)
		calcDistance(vars[page].notused)
		collectgarbage()
end

local function loadOrder()
  local line
  local i, t
  local column = "left"
  local value
  local file
  local temp = {}
  
  if not vars[page].template then file = io.open("Apps/"..vars.appName.."/"..vars.model.."_O"..page..".txt", "r") end
  if not file then file = io.open("Apps/"..vars.appName.."/".."Template_O"..page..".txt", "r") end
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
					if vars[page][line] then
						if value then 
							if i == 1 then 
								vars[page][line].sep = tonumber(value) 
							elseif i == 2 then 
								vars[page][line].dist = tonumber(value) 
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
					if vars[page][line] then
						if value then 
							if i == 1 then 
								vars[page][line].sep = tonumber(value) 
							elseif i == 2 then 
								vars[page][line].dist = tonumber(value) 
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
				if vars[page][line] then
					if value then 
						if i == 1 then 
							vars[page][line].sep = tonumber(value) 
						elseif i == 2 then 
							vars[page][line].dist = tonumber(value) 
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
	
  else
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
end

local function init(varstemp, pagetemp)
	vars = varstemp
	page = pagetemp
	vars[page] = {}
	vars[page].template = system.pLoad("template"..page, 1) == 1 and true or false
	
	leftcolumn = {"TotalCount", "FlightTime", "EngineTime", "Rx1Values", "RPM", "Altitude", "Vario", "Status"}
	rightcolumn = {"Volt_per_Cell", "UsedCapacity", "Current", "Pump_voltage", "I_BEC", "Temp", "Throttle", "PWM", "C1_and_I1", "C2_and_I2", "U1_and_Temp", "U2_and_OI"}
	notused = {"Speed", "Rx2Values", "RxBValues"}
	
	-- first value means the thickness of the seperator
	-- second value means the distance between the boxes, -10 means the distance is calculated
	vars[page].TotalCount = {sep = 0, dist = -9, y = 9, sensors = {}} 		-- TotalTime
	vars[page].FlightTime = {sep = 0, dist = -9, y = 17, sensors = {}}  	-- FlightTime
	vars[page].EngineTime = {sep = 2, dist = -9, y = 12, sensors = {}}  	-- EngineTime
	vars[page].Rx1Values = {sep = 2, dist = -9, y = 29, sensors = {}}	-- Rx1 values
    vars[page].Rx2Values = {sep = 2, dist = -9, y = 29, sensors = {}}	-- Rx2 values
    vars[page].RxBValues = {sep = 2, dist = -9, y = 29, sensors = {}}	-- RxB values  
	vars[page].RPM = {sep = 2, dist = -9, y = 37, sensors = {"rotor_rpm_sens"}}    		-- rpm
	vars[page].Altitude = {sep = 1, dist = -9, y = 17, sensors = {"altitude_sens"}}   		-- altitude
	vars[page].Speed = {sep = 1, dist = -9, y = 17, sensors = {"speed_sens"}}   		-- speed
	vars[page].Vario = {sep = 2, dist = -9, y = 18, sensors = {"vario_sens"}}   		-- vario
	vars[page].Status = {sep = 1, dist = -9, y = 12, sensors = {"status_sens"}}    	-- Status
	vars[page].Volt_per_Cell = {sep = 2, dist = -9, y = 27, sensors = {"battery_voltage_sens"}} 			-- battery voltage
	vars[page].UsedCapacity = {sep = 2, dist = -9, y = 35, sensors = {"used_capacity_sens"}} 	-- used capacity
	vars[page].Current = {sep = 2, dist = -9, y = 17, sensors = {"motor_current_sens"}}   		-- Current
	vars[page].Pump_voltage = {sep = 1, dist = -9, y = 18, sensors = {"pump_voltage_sens"}}    -- Pump voltage
	vars[page].I_BEC = {sep = 1, dist = -9, y = 17, sensors = {"bec_current_sens"}}     		-- IBEC
	vars[page].Temp = {sep = 1 , dist = -9, y = 17, sensors = {"fet_temp_sens"}}      		-- Temperature
	vars[page].Throttle = {sep = 1, dist = -9, y = 17, sensors = {"throttle_sens"}}    	-- Throttle
	vars[page].PWM = {sep = 1, dist = -9, y = 17, sensors = {"pwm_percent_sens"}}      	-- PWM
	vars[page].C1_and_I1 = {sep = 1, dist = -9, y = 16, sensors = {"UsedCap1_sens", "I1_sens"}}      	-- CI1
	vars[page].C2_and_I2 = {sep = 1, dist = -9, y = 16, sensors = {"UsedCap2_sens", "I2_sens"}}      	-- CI2
	vars[page].U1_and_Temp = {sep = 1, dist = -9, y = 16, sensors = {"U1_sens", "Temp_sens" }}    -- U1 and Temp
	vars[page].U2_and_OI = {sep = 1, dist = -9, y = 12, sensors = {"U2_sens", "OverI_sens"}}      -- U2 and OverI
	
	loadOrder()
	
	vars[page].leftdrawcol, vars[page].leftstart, vars[page].ycalcLeft = calcDistance(vars[page].leftcolumn)
	vars[page].rightdrawcol, vars[page].rightstart, vars[page].ycalcRight = calcDistance(vars[page].rightcolumn)
	calcDistance(vars[page].notused)
	
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
	template[page] = form.addCheckbox(vars[page].template, 
				function(value)
					vars[page].template = not value
					system.pSave("template"..page, not value and 1 or 0)
					form.setValue(template[page], not value)	
				end)

	form.addSpacer(320,10)
	form.addRow(2)
	form.addLabel({label = (vars.trans.Leftrow.." ("..vars[page].ycalcLeft..")"), font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

			
	for i,j in ipairs(vars[page].leftcolumn) do	
		if vars[page][j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page][j].y..")",font = FONT_NORMAL, width = 210})
			form.addIntbox(vars[page][j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page][j].sep = value
								saveOrder()
							end, {font = fontLabel, width = 50})
			form.addIntbox(vars[page][j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars[page][j].dist = value
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
		if vars[page][j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page][j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars[page][j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page][j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars[page][j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars[page][j].dist = value
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
		if vars[page][j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars[page][j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars[page][j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars[page][j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars[page][j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars[page][j].dist = value
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

return {

	setup = setup,
	init = init,
	moveLine = moveLine
  
}
