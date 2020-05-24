local initial_voltage_measured = false
local initial_pump_voltage_measured = false
local initial_capacity_percent_used = 0
local initial_cell_voltage
local anCapaGo, anVoltGo
local battery_voltage, battery_voltage_average, used_capacity = 0.0, -1.0, -1
local remaining_capacity_percent, remaining_fuel_percent = 100, 100
local minvtg, maxvtg = 99.9, 0
local status = "" 
local flightTime, newTime, lastTime, engineTime, lastEngineTime = 0, 0, 0, 0, 0
local next_capacity_announcement, next_voltage_announcement, tickTime = 0, 0, 0
local next_capacity_alarm, next_voltage_alarm = 0, 0
local last_averaging_time = 0
local voltage_alarm_dec_thresh
local voltages_list = {}
local Rx = {}
local RxTypen = {"rx1", "rx2", "rxB"}
local gyro_channel_value = 17
local counttheFlight, counted = false, false
local counttheTime = false  
local countedTime = 0
local lastFlightTime = 0
local iKapAlarm, iVoltageAlarm, imaxAlarm = 0, 0, 5
local today
local capacity
local yliDist, yliStart = 0, 0   
local yreDist, yreStart = 0, 0
local maxliDraw, maxreDraw = 0, 0
local xStart
local yStart
local iSep   -- Anzahl der Seperatoren mit variablen Abstand
local iDraw
local maxDraw  -- maximale Anzahl der Felder
local xli, xre = 2, 193 -- x Abstand der Anzeigeboxen vom linken Rand
local lengthSep = 160 - (xre - 160) - xli
local vars = {}
local MinMaxlbl = {}
local drawVal = {}
local drawfunc = {}
local leftcolumn = {"TotalCount", "FlightTime", "EngineTime", "Rx1Values", "RPM", "Altitude", "Vario", "Status"}
local rightcolumn = {"Volt_per_Cell", "UsedCapacity", "Current", "Pump_voltage", "I_BEC", "Temp", "Throttle", "PWM", "C1_and_I1", "C2_and_I2", "U1_and_Temp", "U2_and_OI"}
local notused = {"Rx2Values", "RxBValues"}

local function colstd()
	lcd.setColor(0,0,0)
end

local function colmin()
	lcd.setColor(0,140,0)
end
local function colmax()
	lcd.setColor(0,0,255)
end
local function colalarm()
	lcd.setColor(200,0,0)
end


-- maximal bzw. minimalWerte setzen
local function setminmax()
	local i
	local sens
	local RxTyp
	
	for i,RxTyp in ipairs(RxTypen) do 
		Rx[RxTyp] = {}
		Rx[RxTyp].initial = false
		Rx[RxTyp].voltage = 0
		Rx[RxTyp].percent = 0
		Rx[RxTyp].a1 = 0
		Rx[RxTyp].a2 = 0
		Rx[RxTyp].mina1 = 99
		Rx[RxTyp].mina2 = 99
		Rx[RxTyp].minvoltage = 9.9
		Rx[RxTyp].minpercent = 101.0
	end
	
	for i, sens in ipairs(MinMaxlbl) do
		drawVal[sens] = {}
		drawVal[sens].val = -1000.0
		drawVal[sens].min = 999.9
		drawVal[sens].max = -999.9
		drawVal[sens].measured = true
	end
	drawVal.pump_voltage_sens.measured = false
	drawVal.U1_sens.measured = false
	drawVal.U2_sens.measured = false
	drawVal.UsedCap1_sens = {}
	drawVal.UsedCap1_sens.val = -1000	
	drawVal.UsedCap2_sens = {}
	drawVal.UsedCap2_sens.val = -1000
	drawVal.UsedCap1_sens = {}
	drawVal.UsedCap1_sens.val = -1000	
	drawVal.OverI_sens = {}
	drawVal.OverI_sens.val = -1000
	
	initial_voltage_measured = false
	iKapAlarm = 0
	iVoltageAlarm = 0
	minvtg, maxvtg = 99.9, 0
	collectgarbage()
end


local function saveFlights()
  local file = io.open("Apps/"..vars.appName.."/"..vars.model..".txt", "w+")
  if file then
    io.write(file, vars.totalCount.."\n")
    io.write(file, vars.totalFlighttime.."\n")
    io.close(file)
  end
  collectgarbage()
end

local function loadFlights()
  local file = io.open("Apps/"..vars.appName.."/"..vars.model..".txt", "r")
  if file then
    vars.totalCount = io.readline(file, true)
    vars.totalFlighttime = io.readline(file, true)
    io.close(file)
  else
    vars.totalCount = 0
    vars.totalFlighttime = 0
  end
  collectgarbage()
end

local function loadOrder()
  local line
  local i, t
  local column = "left"
  local value
  local file
  local temp = {}
  
  if not vars.template then file = io.open("Apps/"..vars.appName.."/"..vars.model.."_O.txt", "r") end
  if not file then file = io.open("Apps/"..vars.appName.."/".."Template_O.txt", "r") end
  if file then
	vars.leftcolumn = {}
	vars.rightcolumn = {}
	vars.notused = {}
	line = io.readline(file)
	repeat
		if column == "left" then
			if line ~= "---" then
				table.insert(vars.leftcolumn, line)
				temp[line] = true
				i = 0
				for value in string.gmatch(io.readline(file), "%S+") do 
					i = i + 1
					if vars.param[line] then
						if value then vars.param[line][i] = tonumber(value) end
					else
						table.remove(vars.leftcolumn)
					end
				end
			else 
				column = "right"
			end	
		elseif column == "right" then 
			if line ~= "---" then
				table.insert(vars.rightcolumn, line)
				temp[line] = true
				i = 0
				for value in string.gmatch(io.readline(file), "%S+") do 
					i = i + 1
					if vars.param[line] then
						if value then vars.param[line][i] = tonumber(value) end
					else
						table.remove(vars.rightcolumn)
					end
				end
			else 
				column = "notused"
			end	
		else
			table.insert(vars.notused, line)
			temp[line] = true
			i = 0
			for value in string.gmatch(io.readline(file), "%S+") do 
				i = i + 1
				if vars.param[line] then
					if value then vars.param[line][i] = tonumber(value) end
				else
					table.remove(vars.notused)
				end
			end
		end
		line = io.readline(file)
	until (not line)
	io.close(file)
	
	for _, t in ipairs(leftcolumn) do 
		if not temp[t] then table.insert(vars.notused, t) end
	end
	for _, t in ipairs(rightcolumn) do 
		if not temp[t] then table.insert(vars.notused, t) end
	end
	for _, t in ipairs(notused) do 
		if not temp[t] then table.insert(vars.notused, t) end
	end
	
  else
    vars.leftcolumn = leftcolumn
    vars.rightcolumn = rightcolumn
	vars.notused = notused
  end
  collectgarbage()
end

local function init (stpvars)
	MinMaxlbl = {"motor_current_sens", "bec_current_sens", "pwm_percent_sens", "fet_temp_sens", "throttle_sens", "I1_sens", "I2_sens", "Temp_sens", "rotor_rpm_sens",
		"altitude_sens", "vario_sens", "U1_sens", "U2_sens", "pump_voltage_sens"}
 	setminmax()
	vars = stpvars
	today = system.getDateTime()
	voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 100
	loadFlights()
	
	lastTime = system.getTimeCounter()
	lastEngineTime = lastTime
	vars.param = {}
	-- first value means the thickness of the seperator
	-- second value means the distance between the boxes, -10 means the distance is calculated
	vars.param.TotalCount = {0,-9} 		-- TotalTime
	vars.param.FlightTime = {0,-9}  	-- FlightTime
	vars.param.EngineTime = {2,-9}  	-- EngineTime
	vars.param.Rx1Values = {2,-9}	-- Rx1 values
    vars.param.Rx2Values = {2,-9}	-- Rx2 values
    vars.param.RxBValues = {2,-9}	-- RxB values  
	vars.param.RPM = {2,-9}    		-- rpm
	vars.param.Altitude = {1,-9}   		-- altitude
	vars.param.Vario = {2,-9}   		-- vario
	vars.param.Status = {1,-9}    	-- Status
	vars.param.Volt_per_Cell = {2,-9} 			-- battery voltage
	vars.param.UsedCapacity = {2,-9} 	-- used capacity
	vars.param.Current = {2,-9}   		-- Current
	vars.param.Pump_voltage = {1,-9}    -- Pump voltage
	vars.param.I_BEC = {1,-9}     		-- IBEC
	vars.param.Temp = {1 ,-9}      		-- Temperature
	vars.param.Throttle = {1,-9}    	-- Throttle
	vars.param.PWM = {1,-9}      	-- PWM
	vars.param.C1_and_I1 = {1,-9}      	-- CI1
	vars.param.C2_and_I2 = {1,-9}      	-- CI2
	vars.param.U1_and_Temp = {1,-9}    -- U1 and Temp
	vars.param.U2_and_OI = {1,-9}      -- U2 and OverI
	loadOrder()
end	

local function FaktorAbstand(thick)  -- wenn Dicke der Trennlinie 0 dann nur der einfache Abstand
  if thick == 0 then return 1
  else return 2
  end
end

-- maps cell voltages to remainig capacity
local percentList	=	{{3,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},
						{3.679,10},{3.683,11},{3.689,12},{3.692,13},{3.705,14},{3.71,15},{3.713,16},{3.715,17},{3.72,18},
						{3.731,19},{3.735,20},{3.744,21},{3.753,22},{3.756,23},{3.758,24},{3.762,25},{3.767,26},{3.774,27},
						{3.78,28},{3.783,29},{3.786,30},{3.789,31},{3.794,32},{3.797,33},{3.8,34},{3.802,35},{3.805,36},
						{3.808,37},{3.811,38},{3.815,39},{3.818,40},{3.822,41},{3.825,42},{3.829,43},{3.833,44},{3.836,45},
						{3.84,46},{3.843,47},{3.847,48},{3.85,49},{3.854,50},{3.857,51},{3.86,52},{3.863,53},{3.866,54},
						{3.87,55},{3.874,56},{3.879,57},{3.888,58},{3.893,59},{3.897,60},{3.902,61},{3.906,62},{3.911,63},
						{3.918,64},{3.923,65},{3.928,66},{3.939,67},{3.943,68},{3.949,69},{3.955,70},{3.961,71},{3.968,72},
						{3.974,73},{3.981,74},{3.987,75},{3.994,76},{4.001,77},{4.007,78},{4.014,79},{4.021,80},{4.029,81},
						{4.036,82},{4.044,83},{4.052,84},{4.062,85},{4.074,86},{4.085,87},{4.095,88},{4.105,89},{4.111,90},
						{4.116,91},{4.12,92},{4.125,93},{4.129,94},{4.135,95},{4.145,96},{4.176,97},{4.179,98},{4.193,99},
						{4.2,100}}
           
           
-- Flight time
-- Der Flug wird erst gezählt und die Flugzeit zur Gesamtflugzeit addiert sobald der Timer zum ersten mal gestoppt wird und die minimale Flugzeit erreicht wurde.
-- Wird der Flug fortgesetzt wird beim nächsten Stop des Timers die Zeit zur Gesamtzeit hinzugefügt.
-- Wird wärend der Timer läuft der Reset betätigt wird der Timer auf 0 gesetzt. Wurde der Flug bereits gezählt, sprich der Timer vorher schon einmal gestoppt, dann beginnt ein neuer Flug
-- Wird der Reset betätigt ohne dass der Flug bereits gezählt wurde, dann wird der ganze Flug verworfen, und der Timer beginnt von vorne.

local function FlightTime()

	local timeSw_val = system.getInputsVal(vars.timeSw)
	local engineSw_val = system.getInputsVal(vars.engineSw)
	local resetSw_val = system.getInputsVal(vars.resSw)
	
	newTime = system.getTimeCounter()
	

	-- to be in sync with a system timer, do not use CLR key 
	if (resetSw_val == 1) then
		if counttheFlight == true then counted = false end
		lastFlightTime = 0
		flightTime = 0
		engineTime = 0
		lastTime = newTime
		lastEngineTime = newTime - engineTime
		counttheFlight = false
		counttheTime = false
    setminmax()
	end
	
	if vars.timeSw ~= nil and timeSw_val ~= 0.0 then 
		if timeSw_val == 1 then
			flightTime = newTime - lastTime
			counttheTime = false
			if (vars.timeToCount > 0 and counted == false) then 
				vars.todayCount = vars.todayCount + 1
				counted = true
			end
		else	
			lastTime = newTime - flightTime -- properly start of first interval
			if (vars.timeToCount > 0 and flightTime > vars.timeToCount * 1000 and counttheFlight == false) then  -- Count of the flights
				vars.totalCount = vars.totalCount + 1
				saveFlights()
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", math.floor(system.getTime() / 86400))
				counttheFlight = true
			end
						
			if counttheFlight == true and counttheTime == false then
				counttheTime = true
				countedTime = flightTime - lastFlightTime
				lastFlightTime = lastFlightTime + countedTime
				vars.totalFlighttime = vars.totalFlighttime + (countedTime / 1000)   -- Gesamtflugzeit aller Flüge aufaddieren
				saveFlights()
			end
		end
	else
		flightTime = -1	--keine Anzeigebox
		lastTime = newTime
	end
  
	if vars.engineSw ~= nil and engineSw_val ~= 0.0 then	
		if engineSw_val == 1 then
			engineTime = newTime - lastEngineTime
		else
			lastEngineTime = newTime - engineTime -- properly start of first interval
		end
	else
		engineTime = -1  --keine Anzeigebox
		lastEngineTime = newTime
	end
		   
	collectgarbage()
end
  
-- Count percentage from cell voltage
local function get_capacity_percent_used()
	local result=0
	local i
	if(initial_cell_voltage > 4.2 or initial_cell_voltage < 3.00)then
		if(initial_cell_voltage > 4.2)then
			result=0
		end
		if(initial_cell_voltage < 3.00)then
			result=100
		end
		else
		for i,v in ipairs(percentList) do
			if ( v[1] >= initial_cell_voltage ) then
				result =  100 - v[2]
				break
			end
		end
	end
	collectgarbage()
	return result
end

-- Averaging function for smothing display of voltage 
local function average(value)
    
	local sum_voltages = 0
	local i, voltage

	if ( #voltages_list == 5 ) then
		table.remove(voltages_list, 1)
	end    

	voltages_list[#voltages_list + 1] = value

	for i,voltage in ipairs(voltages_list) do
		sum_voltages = sum_voltages + voltage
	end

	collectgarbage()
	return sum_voltages / #voltages_list
end    
  
-- Draw Battery and percentage display
local function drawBattery()
	if used_capacity > -1 then
    local topbat = 40   -- original = 48
    local highbat = 100  -- original = 80
    local widebat = 50
    -- Battery
    lcd.drawFilledRectangle(148, topbat-7, 24, 7)	-- top of Battery
    lcd.drawRectangle(160-widebat/2-2, topbat-2, widebat+4, highbat+4)
    lcd.drawRectangle(160-widebat/2-1, topbat-1, widebat+2, highbat+2)
      
    -- Level of Battery
    local chgH = math.floor(remaining_capacity_percent * highbat / 100)
    local chgY = highbat + topbat - chgH
    local chgHalarm = math.floor(vars.capacity_alarm_thresh * highbat / 100)
    if chgH < chgHalarm then chgHalarm = chgH end
    local chgYalarm = highbat + topbat - chgHalarm
      
    lcd.setColor(0,220,0)
    lcd.drawFilledRectangle(160-widebat/2, chgY, widebat, chgH) --grün
    lcd.setColor(250,0,0)
    lcd.drawFilledRectangle(160-widebat/2, chgYalarm, widebat, chgHalarm) --rot
    colstd()
    
    -- Text in battery
    lcd.drawText(160-(lcd.getTextWidth(FONT_BIG, string.format("%s",capacity)) / 2),50, string.format("%s", capacity),FONT_BIG)
    lcd.drawText(145, 70, "mAh", FONT_NORMAL)
    local yCell = 120
    if gyro_channel_value == 17 then yCell = 141 end
    lcd.drawText(160-(lcd.getTextWidth(FONT_NORMAL, string.format("%s S",vars.cell_count)) / 2),yCell, string.format("%s S", vars.cell_count),FONT_NORMAL)
    
    
    -- Percentage Display
    if( remaining_capacity_percent > vars.capacity_alarm_thresh ) then	
      lcd.drawRectangle(160-widebat/2-2, 2, widebat+4, 26, 5)
      lcd.drawRectangle(160-widebat/2-1, 3, widebat+2, 24, 4)
      lcd.drawText(160 - (lcd.getTextWidth(FONT_BIG, string.format("%.0f%%",remaining_capacity_percent)) / 2),4, string.format("%.0f%%",
                remaining_capacity_percent),FONT_BIG)
    else
      if( system.getTime() % 2 == 0 ) then -- blink every second
        lcd.drawRectangle(160-widebat/2-2, 2, widebat+4, 26, 5)
        lcd.drawRectangle(160-widebat/2-1, 3, widebat+2, 24, 4)
        lcd.drawText(160 - (lcd.getTextWidth(FONT_BIG, string.format("%.0f%%",remaining_capacity_percent)) / 2),4, string.format("%.0f%%",
                  remaining_capacity_percent),FONT_BIG)
      end
    end
  end

	collectgarbage()
end

-- Draw tank and percentage display
local function drawTank()
  if remaining_fuel_percent >= 0 then 
    local topbat = 38   -- original = 48
    local highbat = 118  -- original = 80
    local widebat = 26
    local midbat = 150
    local ox = 120
    local oy = 60
    local left = 168
    
     -- gas station symbol
    -- lcd.drawRectangle(51+ox,31+oy,5,9)  
    -- lcd.drawLine(52+ox,34+oy,54+ox,34+oy)
    -- lcd.drawLine(50+ox,39+oy,56+ox,39+oy)
    -- lcd.drawLine(57+ox,31+oy,59+ox,33+oy)
    -- lcd.drawLine(59+ox,33+oy,59+ox,37+oy)
    -- lcd.drawPoint(58+ox,38+oy)  
    -- lcd.drawLine(57+ox,38+oy,57+ox,35+oy)  
    -- lcd.drawPoint(56+ox,35+oy)  
    
    lcd.setColor(0,220,0)
    lcd.drawText(52+ox,-17+oy, "F", FONT_BOLD)  
    lcd.setColor(250,0,0)
    lcd.drawText(52+ox,72+oy, "E", FONT_BOLD) 
    colstd()
    
    -- Tank
    lcd.drawFilledRectangle(midbat-widebat/2-2, topbat, 2, highbat+2)
    lcd.drawFilledRectangle(midbat + widebat/2, topbat, 2, highbat+2)
    lcd.drawFilledRectangle(midbat-widebat/2,topbat+highbat, widebat, 2)
    
    lcd.drawFilledRectangle(left, topbat, 17, 2)
    lcd.drawFilledRectangle(left, topbat + highbat, 17, 2)
    lcd.drawFilledRectangle(left, topbat + highbat/2, 14, 2)
    lcd.drawFilledRectangle(left, topbat + highbat/4, 12, 1)
    lcd.drawFilledRectangle(left, topbat + 3*highbat/4, 12, 1)
    
      
    -- Level of fuel
    local chgH = math.floor(remaining_fuel_percent * highbat / 100)
    local chgY = highbat + topbat - chgH
    local chgHalarm = math.floor(vars.capacity_alarm_thresh * highbat / 100)
    if chgH < chgHalarm then chgHalarm = chgH end
    local chgYalarm = highbat + topbat - chgHalarm
      
    lcd.setColor(0,220,0)
    lcd.drawFilledRectangle(midbat-widebat/2, chgY, widebat, chgH) --grün
    lcd.setColor(250,0,0)
    lcd.drawFilledRectangle(midbat-widebat/2, chgYalarm, widebat, chgHalarm) --rot
    colstd()
    
    
    -- Percentage Display
    if( remaining_capacity_percent > vars.capacity_alarm_thresh ) then	
      lcd.drawRectangle(160-25-2, 4, 50+4, 28, 5)
      lcd.drawRectangle(160-25-1, 5, 50+2, 26, 4)
      lcd.drawText(160 - (lcd.getTextWidth(FONT_BIG, string.format("%.0f%%",remaining_fuel_percent)) / 2),6, string.format("%.0f%%",
                remaining_fuel_percent),FONT_BIG)
    else
      if( system.getTime() % 2 == 0 ) then -- blink every second
        lcd.drawRectangle(160-25-2, 4, 50+4, 28, 5)
        lcd.drawRectangle(160-25-1, 5, 50+2, 26, 4)
        lcd.drawText(160 - (lcd.getTextWidth(FONT_BIG, string.format("%.0f%%",remaining_fuel_percent)) / 2),6, string.format("%.0f%%",
                  remaining_fuel_percent),FONT_BIG)
      end
    end
  end

	collectgarbage()
end

-- Draw Gyro
local function drawMibotbox()
	  
	--[[
	Gyro Gain    
	Mini-Vstabi range is: +40 ... +120
	this range correponds to a
	Gyro Channel Value (times 100) range: -39 ... +93
	Scale and offset
	- renorm to zero ( gyro_channel * 100 + 39 )
	- scale ( 120 - 40 ) / ( 93 + 39 ) = 0.60606060...
	- offset +40
	- gyro_percent = (gyro_channel * 100 + 39) * 0.6060 + 40
	- gyro_percent = gyro_channel * 60.606 + 63.6363   
	--]]
  
  if gyro_channel_value ~= 17 then 
    local gyro_percent = gyro_channel_value * 60.606 + 63.6363

    if (gyro_percent < 40) then gyro_percent = 40 end
    if (gyro_percent > 120) then gyro_percent = 120 end

    -- draw fixed Text
    lcd.drawText(136,146,"GY",FONT_MINI)
    -- draw Max Values
    lcd.drawText(184 - lcd.getTextWidth(FONT_BIG, string.format("%.0f", gyro_percent)), 141, string.format("%.0f", gyro_percent), FONT_BIG)
	end
end	

-- Draw Total time box
function drawfunc.TotalCount() --Total flight Time
	local std, min, sec, y
	if vars.timeToCount > 0 then
		local yDraw = 7  -- Höhe der Anzeige ohne Seperator
		y = yStart - 3
		-- draw fixed Text
		lcd.drawText(xStart, y, vars.trans.ftime, FONT_MINI)
		
		-- draw Values
		lcd.drawText(xStart + 37,y, string.format("%.0f", vars.totalCount), FONT_MINI) -- Anzahl Flüge gesamt
		
		std = math.floor(vars.totalFlighttime / 3600)
		min = math.floor(vars.totalFlighttime / 60) - (std * 60)
		sec = vars.totalFlighttime - std * 3600 - min * 60
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_MINI, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_MINI) -- total Flight time
		return yDraw
	end
	return 0
end

-- Draw Flight time box
function drawfunc.FlightTime()	-- Flight flight Time
	if flightTime > -1 then
		local yDraw = 13  -- Höhe der Anzeige ohne Seperator
		local y = yStart - 4
		local std, min, sec = 0, 0, 0

		-- draw Values
		lcd.drawText(xStart + 25 - lcd.getTextWidth(FONT_BIG, string.format("%.0f.", vars.todayCount)),y, string.format("%.0f.", vars.todayCount), FONT_BIG) -- flights today
		std = math.floor(flightTime / 3600000)
		min = math.floor(flightTime / 60000) - (std * 60000)
		sec = (flightTime % 60000) / 1000	
		if std ~= 0 then
			lcd.drawText(xStart + 125 - lcd.getTextWidth(FONT_BIG, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_BIG) -- Flight time
		else
			lcd.drawText(xStart + 125 - lcd.getTextWidth(FONT_BIG, string.format("%02d' %02d\"",min, sec)), y, string.format("%02d' %02d\"",min, sec), FONT_BIG) -- Flight time
		end
		return yDraw
	end
	return 0
end

-- Draw engine time box
function drawfunc.EngineTime()	-- engine Time
	if engineTime > -1 then
		local yDraw = 11  -- Höhe der Anzeige ohne Seperator
		local y = yStart - 4
		local std, min, sec = 0, 0, 0
		-- draw fixed Text
		lcd.drawText(xStart, y + 3, vars.trans.engineTime, FONT_MINI)

		-- draw Values
		std = math.floor(engineTime / 3600000)
		min = math.floor(engineTime / 60000) - (std * 60000)
		sec = (engineTime % 60000) / 1000	
		if std ~= 0 then
			lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_NORMAL) -- engine time
		else
			lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%02d' %02d\"", min, sec)), y, string.format("%02d' %02d\"", min, sec), FONT_NORMAL) -- engine time
		end
		--lcd.drawText(255, 32, string.format("%02d.%02d.%02d", day.day, day.mon, day.year), FONT_MINI)
		return yDraw
	end
	return 0
end

-- Draw Receiver values
function drawRxValues(RxTyp)	-- Rx Values
	local yDraw = 28  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 2
	local linedist = 10
	local x1, x2 = 75, 108
	local draw_minRx_a1 = 0
	local draw_minRx_a2 = 0
	local draw_minRx_percent = 0
	local draw_minRx_voltage = 0
	local RxName
  
    if  RxTyp == "rx1" then
      RxName = "Rx1"
    elseif RxTyp == "rx2" then
      RxName = "Rx2"
    else
      RxName = "RxB"
    end
	
	draw_minRx_a1 = Rx[RxTyp].mina1
	draw_minRx_a2 = Rx[RxTyp].mina2
	draw_minRx_percent = Rx[RxTyp].minpercent
	draw_minRx_voltage = Rx[RxTyp].minvoltage
	
    
    -- draw fixed Text
    lcd.drawText(xStart + 14, y , "min:", FONT_MINI) 
    lcd.drawText(xStart, y + linedist + 1, RxName, FONT_MINI) 
    lcd.drawText(xStart + 17, y + linedist *2, "akt:", FONT_MINI) 
    
    lcd.drawText(xStart + 61, y + 3, "V", FONT_MINI)
    lcd.drawText(xStart + 61, y + 20, "V", FONT_MINI)
    lcd.drawText(xStart + x1, y, "Q:", FONT_MINI) 
    lcd.drawText(xStart + x1, y + linedist, "A1:", FONT_MINI)
    lcd.drawText(xStart + x1, y + linedist*2, "A2:", FONT_MINI)
    
    -- draw RX Values
    if draw_minRx_a1 == 99 then draw_minRx_a1 = 0 end
    if draw_minRx_a2 == 99 then draw_minRx_a2 = 0 end
    if draw_minRx_percent == 101.0 then draw_minRx_percent = 0 end
    if draw_minRx_voltage == 9.9 then draw_minRx_voltage = 0 end
    
    -- Spannung:	
    if draw_minRx_voltage < 4.6 then colalarm() else colmin() end
    lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",draw_minRx_voltage)),y - 2, string.format("%.1f",draw_minRx_voltage),FONT_BOLD)
    colstd()
    if Rx[RxTyp].voltage < 4.6 then colalarm() end
    lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",Rx[RxTyp].voltage)), y + 15, string.format("%.1f",Rx[RxTyp].voltage),FONT_BOLD)
    colstd()
    
    -- Empfangsqualität:
    if draw_minRx_percent < 100 then colalarm() else colmin() end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%.0f/",draw_minRx_percent)),y, string.format("%.0f/",draw_minRx_percent),FONT_MINI) --Rx_percent
    colstd()
    lcd.drawText(xStart + x2, y, string.format("%.0f",Rx[RxTyp].percent),FONT_MINI)
    if draw_minRx_a1 < 9 then colalarm() else colmin() end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minRx_a1)),y + linedist, string.format("%d/",draw_minRx_a1),FONT_MINI)--xStart=98-
    colstd()
    lcd.drawText(xStart + x2, y + linedist, string.format("%d",Rx[RxTyp].a1),FONT_MINI)
    if draw_minRx_a2 < 9 then colalarm() else colmin() end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minRx_a2)),y + linedist * 2, string.format("%d/",draw_minRx_a2),FONT_MINI)
    colstd()
    lcd.drawText(xStart + x2, y + linedist*2, string.format("%d",Rx[RxTyp].a2),FONT_MINI)
	return yDraw
end

function drawfunc.Rx1Values()	-- Rx1 Values
	return drawRxValues("rx1")
end

function drawfunc.Rx2Values()	-- Rx2 Values
	return drawRxValues("rx2")
end

function drawfunc.RxBValues()	-- RxB Values
	return drawRxValues("rxB")
end

-- Draw voltage per cell
function drawfunc.Volt_per_Cell()    -- Flightpack Voltage
	local yDraw = 25  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 3
	if battery_voltage_average > -1 then
		
		-- draw fixed Text
		lcd.drawText(xStart + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.mainbat) / 2),y,vars.trans.mainbat,FONT_MINI)  --xStart=57,y=1
		lcd.drawText(xStart, y + 18, "min:", FONT_MINI)
		--lcd.drawText(xStart + 51, y + 18, "V", FONT_MINI)
		lcd.drawText(xStart + 63, y + 18, "akt:", FONT_MINI)
		--lcd.drawText(xStart + 111, y + 18, "V", FONT_MINI)
		
		-- draw Values, average is average of last 1000 values
		local deci = "%.2f"
		local minvperc = 0
		local battery_voltage_average_perc = battery_voltage_average / vars.cell_count
		if minvtg == 99.9 then minvperc = 0
    else minvperc = minvtg/vars.cell_count
    end
		if minvperc >= 10.0 then deci = "%.1f" end
		if initial_voltage_measured and minvperc <= voltage_alarm_dec_thresh then colalarm() else colmin() end
		lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BIG, string.format(deci, minvperc)),y + 10, string.format(deci, minvperc), FONT_BIG)
		colstd()
		deci = "%.2f"
		if battery_voltage_average_perc >= 10.0 then deci = "%.1f" end
		if initial_voltage_measured and battery_voltage_average_perc <= voltage_alarm_dec_thresh then colalarm() end
		lcd.drawText(xStart + 119 - lcd.getTextWidth(FONT_BIG, string.format(deci, battery_voltage_average_perc)),y + 10, string.format(deci, battery_voltage_average_perc), FONT_BIG)
		colstd()
		return yDraw
	end
	return 0
end
--- Used Capacity
function drawfunc.UsedCapacity()	-- Used Capacity
	local yDraw = 33  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 4
	if used_capacity > -1 then
		local total_used_capacity = math.ceil( used_capacity + (initial_capacity_percent_used * capacity) / 100 )

		-- draw fixed Text
		lcd.drawText(xStart + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.usedCapa) / 2),y,vars.trans.usedCapa,FONT_MINI)
		lcd.drawText(xStart + 96, y + 20, "mAh", FONT_MINI)

		-- draw Values
		lcd.drawText(xStart + 94 - lcd.getTextWidth(FONT_MAXI, string.format("%.0f",total_used_capacity)),y + 5, string.format("%.0f",
					total_used_capacity), FONT_MAXI)
		--lcd.drawText(258,97, string.format("%s mAh", capacity),FONT_MINI)
		return yDraw
	end
	return 0
end

-- Draw Status
function drawfunc.Status()	-- Status
	local yDraw = 12  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 4	
	if status ~= "" then
		
		-- draw Values  
		lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, status)/2,y, status,FONT_BOLD)
		return yDraw
	end
	return 0	
end

-- Draw Pump voltage
function drawfunc.Pump_voltage()	-- Pump voltage
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawminpump_voltage = drawVal.pump_voltage_sens.max
	if drawVal.pump_voltage_sens.val > -1000 then
		
		-- draw fixed Text
		lcd.drawText(xStart, y + 5, "U Pump:", FONT_MINI)
		lcd.drawText(xStart + 80, y + 8,"V",FONT_MINI)
		lcd.drawText(xStart + 98, y, "min:", FONT_MINI)

		-- draw Values  
		if drawminpump_voltage == -999.9 then drawminpump_voltage = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",drawVal.pump_voltage_sens.val)),y, string.format("%.1f",drawVal.pump_voltage_sens.val),FONT_BIG)
		colmin()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.1fV",drawminpump_voltage)) / 2,y + 10, string.format("%.1fV",drawminpump_voltage),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0		
end

-- Draw Rotor speed box
function drawfunc.RPM()	-- Rotor Speed RPM
	local yDraw = 36  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 9
	local drawmaxrpm = drawVal.rotor_rpm_sens.max
	if drawVal.rotor_rpm_sens.val > -1000 then
		
		lcd.drawText(xStart + 112, y + 12, "-1", FONT_MINI)
		lcd.drawText(xStart + 100, y + 21, "min", FONT_MINI)
		lcd.drawText(xStart + 00, y + 35, "Max:", FONT_MINI)

		-- draw Values
		if drawmaxrpm == -999.9 then drawmaxrpm = 0 end
		lcd.drawText(xStart + 97 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",drawVal.rotor_rpm_sens.val)),y,string.format("%.0f",drawVal.rotor_rpm_sens.val),FONT_MAXI)
		colmax()
		lcd.drawText(xStart + 95 - lcd.getTextWidth(FONT_MINI,string.format("%.0f",drawmaxrpm)),y + 35, string.format("%.0f", drawmaxrpm), FONT_MINI)
		colstd()
		return yDraw
	end
	return 0	
end

-- Draw current box
function drawfunc.Current() -- current
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxcur = drawVal.motor_current_sens.max
	if drawVal.motor_current_sens.val > -1000 then
		-- draw fixed Text
		lcd.drawText(xStart, y, "I", FONT_BIG)
		lcd.drawText(xStart + 7, y + 8, "Motor:", FONT_MINI)
		lcd.drawText(xStart + 86, y + 8, "A", FONT_MINI)
		lcd.drawText(xStart + 96, y, "max:", FONT_MINI)
			
		-- draw current 
		if drawmaxcur == -999.9 then drawmaxcur = 0 end
		local deci = "%.1f"
		if drawVal.motor_current_sens.val >= 100 then deci = "%.0f" end
		lcd.drawText(xStart + 85 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.motor_current_sens.val)),y, string.format(deci,drawVal.motor_current_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",drawmaxcur)) / 2,y + 10, string.format("%.0fA",drawmaxcur),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0	
end

-- Draw Temperature
function drawfunc.Temp()	-- Temperature
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxtmp = drawVal.fet_temp_sens.max
	if drawVal.fet_temp_sens.val > -1000 then
		
		-- draw fixed Text
		lcd.drawText(xStart, y + 5, vars.trans.Temp, FONT_MINI)
		lcd.drawText(xStart + 80, y + 8,"°C",FONT_MINI)
		lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

		-- draw Values  
		if drawmaxtmp == -999.9 then drawmaxtmp = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.fet_temp_sens.val)),y, string.format("%.0f",drawVal.fet_temp_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f°C",drawmaxtmp)) / 2,y + 10, string.format("%.0f°C",drawmaxtmp),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0		
end

-- Draw PWM
function drawfunc.PWM()	-- PWM
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxpwm = drawVal.pwm_percent_sens.max
    if drawVal.pwm_percent_sens.val > -1000 then
		
		-- draw fixed Text
		lcd.drawText(xStart, y + 5, "PWM:", FONT_MINI)
		lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
		lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

		-- draw Values  
		if drawmaxpwm == -999.9 then drawmaxpwm = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.pwm_percent_sens.val)),y, string.format("%.0f",drawVal.pwm_percent_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",drawmaxpwm)) / 2,y + 10, string.format("%.0f%%",drawmaxpwm),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0		
end

-- Draw Throttle
function drawfunc.Throttle()	-- Throttle
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxThrottle = drawVal.throttle_sens.max
	if drawVal.throttle_sens.val > -1000 then
		
		-- draw fixed Text
		lcd.drawText(xStart, y + 5, "Throttle:", FONT_MINI)
		lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
		lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

		-- draw Values  
		if drawmaxThrottle == -999.9 then drawmaxThrottle = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.throttle_sens.val)),y, string.format("%.0f",drawVal.throttle_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",drawmaxThrottle)) / 2,y + 10, string.format("%.0f%%",drawmaxThrottle),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0		
end

-- Draw Ibec
function drawfunc.I_BEC()	-- Ibec
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxIBEC = drawVal.bec_current_sens.max
	if drawVal.bec_current_sens.val > -1000 then
		
		-- draw fixed Text
		lcd.drawText(xStart, y + 5, "IBEC:", FONT_MINI)
		lcd.drawText(xStart + 80, y + 8,"A",FONT_MINI)
		lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

		-- draw Values 
		if drawmaxIBEC == -999.9 then drawmaxIBEC = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.bec_current_sens.val)),y, string.format("%.0f",drawVal.bec_current_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",drawmaxIBEC)) / 2,y + 10, string.format("%.0fA",drawmaxIBEC),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0	
end

--Draw Altitude
function drawfunc.Altitude() -- altitude
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxaltitude = drawVal.altitude_sens.max
	if drawVal.altitude_sens.val > -1000 then
		-- draw fixed Text
		lcd.drawText(xStart, y + 6, vars.trans.altitude_sens, FONT_MINI)
		lcd.drawText(xStart + 79, y + 9, "m", FONT_MINI)
		lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
			
		-- draw altitude
		local deci = "%.1f"
		if drawVal.altitude_sens.val >= 100 or drawVal.altitude_sens.val <= -100 then deci = "%.0f" end
		if drawmaxaltitude == -999.9 then drawmaxaltitude = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.altitude_sens.val)),y + 1, string.format(deci,drawVal.altitude_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",drawmaxaltitude)) / 2,y + 10, string.format("%.0f",drawmaxaltitude),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0	
end

-- Draw Vario
function drawfunc.Vario() -- vario
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxvario = drawVal.vario_sens.max
	local drawminvario = drawVal.vario_sens.min
	
	if drawVal.vario_sens.val > -1000 then
		-- draw fixed Text
		lcd.drawText(xStart, y + 6, vars.trans.vario_sens, FONT_MINI)
		lcd.drawText(xStart + 80, y, "m", FONT_MINI)
		lcd.drawText(xStart + 79, y + 1, "___", FONT_MINI)
		lcd.drawText(xStart + 82, y + 9, "s", FONT_MINI)
				
		-- draw vario 
		local deci = "%.1f"
		--if vario >= 10 or vario <= 10 then deci = "%.0f" end
		if drawmaxvario == -999.9 then drawmaxvario = 0 end
		if drawminvario == 999.9 then drawminvario = 0 end
		lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.vario_sens.val)),y + 1, string.format(deci,drawVal.vario_sens.val),FONT_BIG)
		colmax()
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawmaxvario)),y + 1, string.format("%.1f",drawmaxvario),FONT_MINI)
		colmin()
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawminvario)),y + 10, string.format("%.1f",drawminvario),FONT_MINI)
		colstd()
		return yDraw
	end
	return 0	
end

-- Draw C1,I1 box
function drawfunc.C1_and_I1() -- C1, I1
	local yDraw = 14  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 3
	local drawmax = drawVal.I1_sens.max
	local deci
	if drawVal.UsedCap1_sens.val > -1000 or drawVal.I1_sens.val > -1000 then
		if drawVal.UsedCap1_sens.val > -1000 then
			-- draw C1
			lcd.drawText(xStart, y, "C", FONT_NORMAL)
			lcd.drawText(xStart + 9, y + 5 , "1:", FONT_MINI)
			lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
			deci = "%.0f"
			lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.UsedCap1_sens.val)),y, string.format(deci,drawVal.UsedCap1_sens.val),FONT_NORMAL)
		end
		if drawVal.I1_sens.val > -1000 then
			-- draw I1
			lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
			lcd.drawText(xStart + 84, y + 5, "1:", FONT_MINI)
			if drawmax == -999.9 then drawmax = 0 end
			deci = "%.1fA"
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.I1_sens.val)),y - 1, string.format(deci,drawVal.I1_sens.val),FONT_MINI)
			colmax()
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",drawmax)),y + 7, string.format("%.1fA",drawmax),FONT_MINI)
			colstd()
		end
		return yDraw
	end
	return 0	
end

-- Draw C2,I2 box
function drawfunc.C2_and_I2() -- C2, I2
	local yDraw = 14  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 3
	local drawmax = drawVal.I2_sens.max
	local deci
	if drawVal.UsedCap2_sens.val > -1000 or drawVal.I2_sens.val > -1000 then
		if drawVal.UsedCap2_sens.val > -1000 then
			-- draw C1
			lcd.drawText(xStart, y, "C", FONT_NORMAL)
			lcd.drawText(xStart + 9, y + 5 , "2:", FONT_MINI)
			lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
			deci = "%.0f"
			lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.UsedCap2_sens.val)),y, string.format(deci,drawVal.UsedCap2_sens.val),FONT_NORMAL)
		end
		if drawVal.I2_sens.val > -1000 then
			-- draw I1
			lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
			lcd.drawText(xStart + 84, y + 5, "2:", FONT_MINI)
			if drawmax == -999.9 then drawmax = 0 end
			deci = "%.1fA"
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.I2_sens.val)),y - 1, string.format(deci,drawVal.I2_sens.val),FONT_MINI)
			colmax()
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",drawmax)),y + 7, string.format("%.1fA",drawmax),FONT_MINI)
			colstd()
		end
		return yDraw
	end
	return 0	
end

-- Draw U1, Temp box
function drawfunc.U1_and_Temp() -- U1, Temp
	local yDraw = 14  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 3
	local drawmin = drawVal.U1_sens.min
	local drawmax = drawVal.Temp_sens.max
	local deci
	if drawVal.U1_sens.val > -1000 or drawVal.Temp_sens.val > -1000 then
		if drawVal.U1_sens.val > -1000 then
			-- draw U1
			lcd.drawText(xStart, y, "U", FONT_NORMAL)
			lcd.drawText(xStart + 9, y + 5 , "1:", FONT_MINI)
			lcd.drawText(xStart + 75, y + 5, "V", FONT_MINI)
			deci = "%.1f"
			colmin()
			lcd.drawText(xStart + 41, y + 5, "V", FONT_MINI)
			if drawmin == 999.9 then drawmin = 0 end
			lcd.drawText(xStart + 41 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawmin)),y, string.format(deci,drawmin),FONT_NORMAL)
			colstd()
			lcd.drawText(xStart + 49, y, "/", FONT_NORMAL)
			lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.U1_sens.val)),y, string.format(deci,drawVal.U1_sens.val),FONT_NORMAL)
		end
		if drawVal.Temp_sens.val > -1000 then
			-- draw Temp
			lcd.drawText(xStart + 83, y, "T:", FONT_NORMAL)
			if drawmax == -999.9 then drawmax = 0 end
			deci = "%.0f°C"
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.Temp_sens.val)),y - 1, string.format(deci,drawVal.Temp_sens.val),FONT_MINI)
			colmax()
			lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawmax)),y + 7, string.format(deci,drawmax),FONT_MINI)
			colstd()
		end
		return yDraw
	end
	return 0	
end

-- Draw U2, OverI
function drawfunc.U2_and_OI() -- U2, OverI
	local yDraw = 10  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmin = drawVal.U2_sens.min
	local deci
	if drawVal.U2_sens.val > -1000 or drawVal.OverI_sens.val > -1000 then
		if drawVal.U2_sens.val > -1000 then
			-- draw U1
			lcd.drawText(xStart, y, "U", FONT_NORMAL)
			lcd.drawText(xStart + 9, y + 5 , "2:", FONT_MINI)
			lcd.drawText(xStart + 75, y + 5, "V", FONT_MINI)
			deci = "%.1f"
			colmin()
			lcd.drawText(xStart + 41, y + 5, "V", FONT_MINI)
			if drawmin == 999.9 then drawmin = 0 end
			lcd.drawText(xStart + 41 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawmin)),y, string.format(deci,drawmin),FONT_NORMAL)
			colstd()
			lcd.drawText(xStart + 49, y, "/", FONT_NORMAL)
			lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.U2_sens.val)),y, string.format(deci,drawVal.U2_sens.val),FONT_NORMAL)
		end
		if drawVal.OverI_sens.val > -1000 then
			-- draw Temp
			lcd.drawText(xStart + 90, y, "OI:", FONT_NORMAL)
			deci = "%.0f"
			if drawVal.OverI_sens.val > 0 then colalarm() end
			lcd.drawText(xStart + 120 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.OverI_sens.val)),y, string.format(deci,drawVal.OverI_sens.val),FONT_NORMAL)
			colstd()
		end
		return yDraw
	end
	return 0	
end

local function showDisplay()
	local i,j
	local yBox
		
	colstd()
 		
	--left:	
	iSep = 0   -- Anzahl der Seperatoren mit variablen Abstand
	iDraw = 0
	xStart = xli
	yStart = yliStart
	for i,j in ipairs(vars.leftcolumn) do
		yBox = drawfunc[j]()
		if yBox > 0 then 
			iDraw = iDraw + 1
			if iDraw < maxliDraw then
				if vars.param[j][2] == -9 then
					iSep = iSep + FaktorAbstand(vars.param[j][1])
					lcd.drawFilledRectangle(xli, yStart + yBox + yliDist * FaktorAbstand(vars.param[j][1]) / 2, lengthSep, vars.param[j][1])
					yStart = yStart + yBox + yliDist * FaktorAbstand(vars.param[j][1]) + vars.param[j][1]
				else
					lcd.drawFilledRectangle(xli, yStart + yBox + vars.param[j][2] * FaktorAbstand(vars.param[j][1]) / 2, lengthSep, vars.param[j][1])
					yStart = yStart + yBox + vars.param[j][2] * FaktorAbstand(vars.param[j][1]) + vars.param[j][1]
				end	
			else		
				yStart = yStart + yBox   -- letztes Feld, kein Seperator
			end	
		end
	end
	 	 
	maxliDraw = iDraw
	yliDist = math.floor((160 - yStart + yliStart + iSep * yliDist) / (iSep + 2))
	yliStart = math.floor((160 - (yStart - yliStart)) / 2)
	
--------------	
	--right
	iSep = 0
	iDraw = 0
	xStart = xre
	yStart = yreStart
	
	for i,j in ipairs(vars.rightcolumn) do
		yBox = drawfunc[j]()
		if yBox > 0 then
			iDraw = iDraw + 1 
			if iDraw < maxreDraw then
				if vars.param[j][2] == -9 then
					iSep = iSep + FaktorAbstand(vars.param[j][1])
					lcd.drawFilledRectangle(xre, yStart + yBox + yreDist * FaktorAbstand(vars.param[j][1]) / 2, lengthSep, vars.param[j][1])
					yStart = yStart + yBox + yreDist * FaktorAbstand(vars.param[j][1]) + vars.param[j][1]
				else
					lcd.drawFilledRectangle(xre, yStart + yBox + vars.param[j][2] * FaktorAbstand(vars.param[j][1]) / 2, lengthSep, vars.param[j][1])
					yStart = yStart + yBox + vars.param[j][2] * FaktorAbstand(vars.param[j][1]) + vars.param[j][1]
				end				
			else		
				yStart = yStart + yBox   -- letztes Feld, kein Seperator
			end	
		end		
	end
	
	maxreDraw = iDraw
	yreDist = math.floor((160 - yStart + yreStart + iSep * yreDist) / (iSep + 2))
	yreStart = math.floor((160 - (yStart - yreStart)) / 2)

	-- middle
	drawBattery()
	drawTank()
	drawMibotbox()

	collectgarbage()
end

local function loop()
	local sensor
	local txtelemetry
	local anCapaGo = system.getInputsVal(vars.anCapaSw)
	local anVoltGo = system.getInputsVal(vars.anVoltSw)
	local tickTime = system.getTime()
	local i
	local sens
    
	FlightTime()
		
	if vars.gyChannel ~= 17 then gyro_channel_value = system.getInputs(vars.gyro_output)
	else gyro_channel_value = 17
	end
	
	if system.getInputsVal(vars.akkuSw) == 1 and vars.capacity2 > 0 then capacity = vars.capacity2
	else capacity = vars.capacity1
	end
		
	-- Rx values:
	txtelemetry = system.getTxTelemetry()
	for i,RxTyp in ipairs(RxTypen) do
		Rx[RxTyp].percent = txtelemetry[RxTyp.."Percent"] 
		if Rx[RxTyp].initial == false then 
			if Rx[RxTyp].percent > 99.0 then Rx[RxTyp].initial = true end
		end
		if Rx[RxTyp].initial == true then
			Rx[RxTyp].voltage = txtelemetry[RxTyp.."Voltage"]
			Rx[RxTyp].a1 = txtelemetry.RSSI[i*2-1]
			Rx[RxTyp].a2 = txtelemetry.RSSI[i*2]
			if Rx[RxTyp].voltage > 0.0 and Rx[RxTyp].voltage < Rx[RxTyp].minvoltage then Rx[RxTyp].minvoltage = Rx[RxTyp].voltage end
			if Rx[RxTyp].percent > 0.0 and Rx[RxTyp].percent < Rx[RxTyp].minpercent then Rx[RxTyp].minpercent = Rx[RxTyp].percent end
			if Rx[RxTyp].a1 > 0 and Rx[RxTyp].a1 < Rx[RxTyp].mina1 then Rx[RxTyp].mina1 = Rx[RxTyp].a1 end
			if Rx[RxTyp].a2 > 0 and Rx[RxTyp].a2 < Rx[RxTyp].mina2 then Rx[RxTyp].mina2 = Rx[RxTyp].a2 end
			--if Rx[RxTyp].percent < 1 then setminmax() end
		end
	end 
	
	-- Read Sensor Parameter Voltage 
	sensor = system.getSensorValueByID(vars.battery_voltage_sens[1], vars.battery_voltage_sens[2])
	if(sensor and sensor.valid ) then
		battery_voltage = sensor.value
	-- guess used capacity from voltage if we started with partially discharged battery 
		if (initial_voltage_measured == false) then
			if ( battery_voltage / vars.cell_count) > 1.1  then
				initial_voltage_measured = true
				initial_cell_voltage = battery_voltage / vars.cell_count
				initial_capacity_percent_used = get_capacity_percent_used()
			end    
		end        
		
		-- calculate Min/Max Sensor 1
		if ( battery_voltage < minvtg and (battery_voltage / vars.cell_count) > 1.1 ) then minvtg = battery_voltage end
		if battery_voltage > maxvtg then maxvtg = battery_voltage end
		
		if newTime >= (last_averaging_time + 1000) then          -- one second period, newTime set from FlightTime()
			battery_voltage_average = average(battery_voltage)   -- average voltages over n samples
			last_averaging_time = newTime
		end
		
		if ((battery_voltage_average / vars.cell_count) <= voltage_alarm_dec_thresh and vars.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime and iVoltageAlarm < imaxAlarm ) then
			system.messageBox(vars.trans.voltWarn,2)
			system.playFile(vars.voltage_alarm_voice,AUDIO_QUEUE)
			iVoltageAlarm = iVoltageAlarm + 1
			next_voltage_alarm = tickTime + 5 -- battery voltage alarm every 4 second 
		end  
		
		if(anVoltGo == 1 and tickTime >= next_voltage_announcement) then
			system.playNumber(battery_voltage, 1, "V", "U Battery")
			next_voltage_announcement = tickTime + 10 -- say battery voltage every 10 seconds
		end
	else
		battery_voltage = 0
		initial_voltage_measured = true
		if vars.battery_voltage_sens[2] ~= 0 then 
			battery_voltage_average = 0
			initial_voltage_measured = false
		end
	end
	
	-- Read Status Parameter 
	sensor = system.getSensorValueByID(vars.status_sens[1], vars.status_sens[2])
	if(sensor and sensor.valid) then
		if Global_TurbineState ~= "" then  status = Global_TurbineState
			else status = sensor.value
		end
	else
		if vars.status_sens[2] ~= 0 then status = "No Status" end
	end
	
	-- Read remaining fuel percent
	sensor = system.getSensorValueByID(vars.remaining_fuel_percent_sens[1], vars.remaining_fuel_percent_sens[2])
	if(sensor and sensor.valid) then
		remaining_fuel_percent = sensor.value
	else
		if vars.remaining_fuel_percent_sens[2] ~= 0 then 
			remaining_fuel_percent = 0 
		else
			if Calca_dispGas then remaining_fuel_percent = Calca_dispGas
							 else remaining_fuel_percent = -1 
			end
		end
	end
	                    
	-- Read Sensor Parameter Used Capacity
	sensor = system.getSensorValueByID(vars.used_capacity_sens[1], vars.used_capacity_sens[2])
	if(sensor and sensor.valid) then 
		used_capacity = sensor.value

		if ( initial_voltage_measured == true ) then
			remaining_capacity_percent = math.floor( ( ( (capacity - used_capacity) * 100) / capacity ) - initial_capacity_percent_used)
			if remaining_capacity_percent < 0 then remaining_capacity_percent = 0 end
		end
                 
		-- Set max/min percentage to 99/0 for drawing
		if( remaining_capacity_percent > 100 ) then remaining_capacity_percent = 100 end
		if( remaining_capacity_percent < 0 ) then remaining_capacity_percent = 0 end
	else
		if vars.used_capacity_sens[2] ~= 0 then
			if used_capacity == -1 then used_capacity = 0 end 
		else
			if Calca_dispFuel then 
				vars.capacity = Calca_capacity
				used_capacity = Calca_capacity * (1 - Calca_dispFuel / 100)
				remaining_capacity_percent = Calca_dispFuel
			else used_capacity = -1 
			end
		end
	end	
	
	if ((remaining_capacity_percent > 0 and remaining_capacity_percent <= vars.capacity_alarm_thresh) or (remaining_fuel_percent > 0 and remaining_fuel_percent <= vars.capacity_alarm_thresh))
		and vars.capacity_alarm_voice ~= "..." and next_capacity_alarm < tickTime and iKapAlarm < imaxAlarm then
			system.messageBox(vars.trans.capaWarn,2)
			system.playFile(vars.capacity_alarm_voice,AUDIO_QUEUE)
			iKapAlarm = iKapAlarm + 1
			next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
	end
	
	if anCapaGo == 1 and tickTime >= next_capacity_announcement then
		if remaining_fuel_percent > 0  then
			system.playNumber(remaining_fuel_percent, 0, "%", "Capacity")
			next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
		elseif remaining_capacity_percent > 0 then
			system.playNumber(remaining_capacity_percent, 0, "%", "Capacity")
			next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
		end		
	end
	

	for i, sens in ipairs(MinMaxlbl) do
		sensor = system.getSensorValueByID(vars[sens][1], vars[sens][2])
		if (sensor and sensor.valid) then
			drawVal[sens].val = sensor.value
			if drawVal[sens].measured == false then
				if  drawVal[sens].val > 1 then 
					drawVal[sens].measured = true
					drawVal[sens].min = 999.9
				end
			else
				-- calculate Min/Max Sensor
				if drawVal[sens].val < drawVal[sens].min then drawVal[sens].min = drawVal[sens].val end
				if drawVal[sens].val > drawVal[sens].max then drawVal[sens].max = drawVal[sens].val end
			end
		else
			if vars[sens][2] ~= 0 then drawVal[sens].val = 0 end
		end
	end
	
	for i, sens in ipairs({"UsedCap1_sens", "UsedCap2_sens", "OverI_sens"}) do
		sensor = system.getSensorValueByID(vars[sens][1], vars[sens][2])
		if (sensor and sensor.valid) then
			drawVal[sens].val = sensor.value
		else
			if vars[sens][2] ~= 0 then drawVal[sens].val = 0 end
		end
	end
	
	--print(system.getCPU())
end --loop

return {
	showDisplay = showDisplay,
	loop = loop,
	init = init
}
