
local initial_voltage_measured = false
local initial_pump_voltage_measured = false
local initial_capacity_percent_used = 0
local initial_cell_voltage
local anCapaGo, anVoltGo
local battery_voltage, battery_voltage_average, motor_current, rotor_rpm, used_capacity = 0.0, -1.0, -1.0, -1, -1
local bec_current, pwm_percent, fet_temp, throttle = -1, -1, -100, -1
local remaining_capacity_percent, remaining_fuel_percent = 100, 100
local minpwm, maxpwm = 0, 0
local minrpm, maxrpm, mincur, maxcur= 999, 0, 99.9, 0
local minvtg, maxvtg, mintmp, maxtmp = 99.9, 0, 99, 0
local minThrottle, maxThrottle, minIBEC, maxIBEC = 99.9, 0, 99.9, 0
local status, pump_voltage = "", -1
local minpump_voltage, maxpump_voltage = 0, 0
local height, vario = -1000.0, -100.0
local minheight, maxheight, minvario, maxvario = 999.9, -999.9, 99.9, -99.9
local flightTime, newTime, lastTime, engineTime, lastEngineTime = 0, 0, 0, 0, 0
local minrxv, maxrxv, minrxa, maxrxa = 9.9, 0.0, 9.9, 0.0
local next_capacity_announcement, next_voltage_announcement, tickTime = 0, 0, 0
local next_capacity_alarm, next_voltage_alarm = 0, 0
local last_averaging_time = 0
local voltage_alarm_dec_thresh
local voltages_list = {}
local rx_voltage, minrx_voltage, rx_percent, minrx_percent = 0.00, 9.9, 0.0, 101.0
local rx_a1, minrx_a1, rx_a2, minrx_a2 = 0, 99, 0, 99
local gyro_channel_value = 17
local initialRx = false
local colorRed = 0
local counttheFlight, counted = false, false
local counttheTime = false
local countedTime = 0
local lastFlightTime = 0
local iKapAlarm, imaxAlarm = 0, 5

local today
local vars = {}

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

local function init (stpvars)
	
	vars = stpvars
	today = system.getDateTime()
	voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 10
    loadFlights()
	lastTime = system.getTimeCounter()
	lastEngineTime = lastTime
	
end	


local function FaktorAbstand(thick)  -- wenn Dicke der Trennlinie 0 dann nur der einfache Abstand
  if thick == 0 then return 1
  else return 2
  end
end

-- maximal bzw. minimalWerte setzen
local function setminmax()
	minrx_a1 = 99
	minrx_a2 = 99
	minrx_voltage = 9.9
	minrx_percent = 101.0
	minrpm, maxrpm, mincur, maxcur = 999, 0, 99.9, 0
	minvtg, maxvtg, mintmp, maxtmp = 99.9, 0, 99, 0
	minrxv, maxrxv, minrxa, maxrxa = 9.9, 0.0, 9.9, 0.0
	colorRed = 0
	--initial_voltage_measured = false
	initialRx = false
	rx_voltage = 0
	collectgarbage()
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
    lcd.setColor(0,0,0)
    
    -- Text in battery
    lcd.drawText(160-(lcd.getTextWidth(FONT_BIG, string.format("%s",vars.capacity)) / 2),50, string.format("%s", vars.capacity),FONT_BIG)
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
    lcd.setColor(0,0,0)
    
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
    lcd.setColor(0,0,0)
    
    
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

-- Draw voltage per cell
local function drawVpC(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)    -- Flightpack Voltage
	local yDraw = 25  -- Höhe der Anzeige ohne Seperator
  local y = yStart -3
	if battery_voltage_average > -1 then
		
		-- draw fixed Text
		lcd.drawText(x + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.mainbat) / 2),y,vars.trans.mainbat,FONT_MINI)  --x=57,y=1
		lcd.drawText(x, y + 18, "min:", FONT_MINI)
		--lcd.drawText(x + 51, y + 18, "V", FONT_MINI)
		lcd.drawText(x + 63, y + 18, "akt:", FONT_MINI)
		--lcd.drawText(x + 111, y + 18, "V", FONT_MINI)
		

		-- draw Values, average is average of last 1000 values
		local deci = "%.2f"
    local minvperc = 0
    local battery_voltage_average_perc = battery_voltage_average / vars.cell_count
		if minvtg == 99.9 then minvperc = 0
    else minvperc = minvtg/vars.cell_count
    end
		if minvperc >= 10.0 then deci = "%.1f" end
		lcd.drawText(x + 60 - lcd.getTextWidth(FONT_BIG, string.format(deci, minvperc)),y + 10, string.format(deci, minvperc), FONT_BIG)
		deci = "%.2f"
		if battery_voltage_average_perc >= 10.0 then deci = "%.1f" end
		lcd.drawText(x + 119 - lcd.getTextWidth(FONT_BIG, string.format(deci, battery_voltage_average_perc)),y + 10, string.format(deci, battery_voltage_average_perc), FONT_BIG)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end



-- Draw Rotor speed box
local function drawrpmbox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Rotor Speed RPM
	local yDraw = 36  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 9
	if rotor_rpm > -1 then
		
		lcd.drawText(x + 112, y + 12, "-1", FONT_MINI)
		--lcd.drawLine (x + 100, y + 21, x + 119, y + 21)
		lcd.drawText(x + 100, y + 21, "min", FONT_MINI)
		lcd.drawText(x + 00, y + 35, "Max:", FONT_MINI)

		-- draw Values
		lcd.drawText(x + 97 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",rotor_rpm)),y,string.format("%.0f",rotor_rpm),FONT_MAXI)
		lcd.drawText(x + 95 - lcd.getTextWidth(FONT_MINI,string.format("%.0f",maxrpm)),y + 35, string.format("%.0f", maxrpm), FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end

-- Draw current box
local function drawCurrent(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc) -- current
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
	if motor_current > -1 then
		-- draw fixed Text
		lcd.drawText(x, y, "I", FONT_BIG)
		lcd.drawText(x + 7, y + 8, "Motor:", FONT_MINI)
		lcd.drawText(x + 86, y + 8, "A", FONT_MINI)
		lcd.drawText(x + 96, y, "max:", FONT_MINI)
			
		-- draw current 
		local deci = "%.1f"
		if motor_current >= 100 then deci = "%.0f" end
		lcd.drawText(x + 85 - lcd.getTextWidth(FONT_BIG, string.format(deci,motor_current)),y, string.format(deci,motor_current),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",maxcur)) / 2,y + 10, string.format("%.0fA",maxcur),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
      lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end

-- Draw Receiver values
local function drawRxValues(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Rx Values
	local yDraw = 28  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 2
	local linedist = 10
	local x1, x2 = 75, 108
	local draw_minrx_a1 = minrx_a1
	local draw_minrx_a2 = minrx_a2
	local draw_minrx_percent = minrx_percent
	local draw_minrx_voltage = minrx_voltage
	
	-- draw fixed Text
	lcd.drawText(x + 14, y , "min:", FONT_MINI) 
	lcd.drawText(x, y + linedist, "URx:", FONT_MINI) 
	lcd.drawText(x + 17, y + linedist *2, "akt:", FONT_MINI) 
	
	lcd.drawText(x + 61, y + 3, "V", FONT_MINI)
	lcd.drawText(x + 61, y + 20, "V", FONT_MINI)
	lcd.drawText(x + x1, y, "Q:", FONT_MINI) 
	lcd.drawText(x + x1, y + linedist, "A1:", FONT_MINI)
	lcd.drawText(x + x1, y + linedist*2, "A2:", FONT_MINI)
	
	-- draw RX Values
	if draw_minrx_a1 == 99 then draw_minrx_a1 = 0 end
	if draw_minrx_a2 == 99 then draw_minrx_a2 = 0 end
	if draw_minrx_percent == 101.0 then draw_minrx_percent = 0 end
	if draw_minrx_voltage == 9.9 then draw_minrx_voltage = 0 end
	
	-- Spannung:	
	if draw_minrx_voltage < 4.6 then lcd.setColor(colorRed,0,0) end
	lcd.drawText(x + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",draw_minrx_voltage)),y - 2, string.format("%.1f",draw_minrx_voltage),FONT_BOLD)
	lcd.setColor(0,0,0)
  if rx_voltage < 4.6 then lcd.setColor(colorRed,0,0) end
	lcd.drawText(x + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",rx_voltage)), y + 15, string.format("%.1f",rx_voltage),FONT_BOLD)
	lcd.setColor(0,0,0)
  
	-- Empfangsqualität:
	if draw_minrx_percent < 100 then lcd.setColor(colorRed,0,0) end
	lcd.drawText(x + x2 - lcd.getTextWidth(FONT_MINI, string.format("%.0f/",draw_minrx_percent)),y, string.format("%.0f/",draw_minrx_percent),FONT_MINI) --rx_percent
	lcd.setColor(0,0,0)
	lcd.drawText(x + x2, y, string.format("%.0f",rx_percent),FONT_MINI)
	if draw_minrx_a1 < 10 then lcd.setColor(colorRed,0,0) end
	lcd.drawText(x + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minrx_a1)),y + linedist, string.format("%d/",draw_minrx_a1),FONT_MINI)--x=98-
	lcd.setColor(0,0,0)
	lcd.drawText(x + x2, y + linedist, string.format("%d",rx_a1),FONT_MINI)
	if draw_minrx_a2 < 10 then lcd.setColor(colorRed,0,0) end
	lcd.drawText(x + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minrx_a2)),y + linedist*2, string.format("%d/",draw_minrx_a2),FONT_MINI)
	lcd.setColor(0,0,0)
	lcd.drawText(x + x2, y + linedist*2, string.format("%d",rx_a2),FONT_MINI)
	iDraw = iDraw + 1
	if iDraw < maxDraw then
		lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
		if calc == true then iSep = iSep + 2 end
		return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
	end		
	return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
end

-- Draw Total time box
local function drawTotalCount(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc) --Total flight Time
  local std, min, sec, y
	if vars.timeToCount > 0 then
		local yDraw = 7  -- Höhe der Anzeige ohne Seperator
		y = yStart - 3
		-- draw fixed Text
		lcd.drawText(x, y, vars.trans.ftime, FONT_MINI)
		
		-- draw Values
		lcd.drawText(x + 34,y, string.format("%.0f", vars.totalCount), FONT_MINI) -- Anzahl Flüge gesamt
		
		std = math.floor(vars.totalFlighttime / 3600)
		min = math.floor(vars.totalFlighttime / 60) - (std * 60)
		sec = vars.totalFlighttime - std * 3600 - min * 60
		lcd.drawText(x + 122 - lcd.getTextWidth(FONT_MINI, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_MINI) -- total Flight time
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist * FaktorAbstand(thick) / 2, lengthSep, thick)
			if calc == true then iSep = iSep + FaktorAbstand(thick) end
			return yStart + yDraw + yDist * FaktorAbstand(thick) + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end
end

-- Draw Flight time box
local function drawFlightTime(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Flight flight Time
	if flightTime > -1 then
		local yDraw = 13  -- Höhe der Anzeige ohne Seperator
		local y = yStart - 4
		local std, min, sec = 0, 0, 0

		-- draw Values
		lcd.drawText(x + 25 - lcd.getTextWidth(FONT_BIG, string.format("%.0f.", vars.todayCount)),y, string.format("%.0f.", vars.todayCount), FONT_BIG) -- flights today
		std = math.floor(flightTime / 3600000)
		min = math.floor(flightTime / 60000) - (std * 60000)
		sec = (flightTime % 60000) / 1000	
		if std ~= 0 then
			lcd.drawText(x + 125 - lcd.getTextWidth(FONT_BIG, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_BIG) -- Flight time
		else
			lcd.drawText(x + 125 - lcd.getTextWidth(FONT_BIG, string.format("%02d' %02d\"",min, sec)), y, string.format("%02d' %02d\"",min, sec), FONT_BIG) -- Flight time
		end
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist * FaktorAbstand(thick) / 2, lengthSep, thick)
			if calc == true then iSep = iSep + FaktorAbstand(thick) end
			return yStart + yDraw + yDist * FaktorAbstand(thick) + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end
end

-- Draw engine time box
local function drawEngineTime(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- engine Time
	if engineTime > -1 then
		local yDraw = 11  -- Höhe der Anzeige ohne Seperator
		local y = yStart - 4
		local std, min, sec = 0, 0, 0
		-- draw fixed Text
		lcd.drawText(x, y + 3, vars.trans.engineTime, FONT_MINI)

		-- draw Values
		std = math.floor(engineTime / 3600000)
		min = math.floor(engineTime / 60000) - (std * 60000)
		sec = (engineTime % 60000) / 1000	
		if std ~= 0 then
			lcd.drawText(x + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_NORMAL) -- engine time
		else
			lcd.drawText(x + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%02d' %02d\"", min, sec)), y, string.format("%02d' %02d\"", min, sec), FONT_NORMAL) -- engine time
		end
		--lcd.drawText(255, 32, string.format("%02d.%02d.%02d", day.day, day.mon, day.year), FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist * FaktorAbstand(thick) / 2, lengthSep, thick)
			if calc == true then iSep = iSep + FaktorAbstand(thick) end
			return yStart + yDraw + yDist * FaktorAbstand(thick) + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDist * FaktorAbstand(thick) / 4, lengthSep, thick)
			if calc == true then iSep = iSep + FaktorAbstand(thick) end
			return yStart + yDist * FaktorAbstand(thick) + thick, iDraw, iSep
		end		
		return yStart, iDraw, iSep
	end
end

--- Used Capacity
local function drawUsedCapacity(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc )	-- Used Capacity
	local yDraw = 33  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 4
	if used_capacity > -1 then
		local total_used_capacity = math.ceil( used_capacity + (initial_capacity_percent_used * vars.capacity) / 100 )

		-- draw fixed Text
		lcd.drawText(x + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.usedCapa) / 2),y,vars.trans.usedCapa,FONT_MINI)
		lcd.drawText(x + 96, y + 20, "mAh", FONT_MINI)

		-- draw Values
		lcd.drawText(x + 94 - lcd.getTextWidth(FONT_MAXI, string.format("%.0f",total_used_capacity)),y + 5, string.format("%.0f",
					total_used_capacity), FONT_MAXI)
		--lcd.drawText(258,97, string.format("%s mAh", capacity),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end

-- Draw Temperature
local function drawTempbox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Temperature
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
	if fet_temp > -100 then
		
		-- draw fixed Text
		lcd.drawText(x, y + 5, vars.trans.temp, FONT_MINI)
		lcd.drawText(x + 80, y + 8,"°C",FONT_MINI)
		lcd.drawText(x + 96, y, "max:", FONT_MINI)

		-- draw Values  
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",fet_temp)),y, string.format("%.0f",fet_temp),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f°C",maxtmp)) / 2,y + 10, string.format("%.0f°C",maxtmp),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end		
end

-- Draw Status
local function drawStatusbox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Status
	local yDraw = 12  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 4
	if status ~= "" then
		
		-- draw Values  
		lcd.drawText(x + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, status)/2,y, status,FONT_BOLD)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end		
end

-- Draw Pump voltage
local function drawPump_voltagebox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Pump voltage
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
	if pump_voltage > -1 then
		
		-- draw fixed Text
		lcd.drawText(x, y + 5, "U Pump:", FONT_MINI)
		lcd.drawText(x + 80, y + 8,"V",FONT_MINI)
		lcd.drawText(x + 96, y, "min:", FONT_MINI)

		-- draw Values  
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",pump_voltage)),y, string.format("%.1f",pump_voltage),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.1fV",minpump_voltage)) / 2,y + 10, string.format("%.1fV",minpump_voltage),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end		
end

-- Draw PWM
local function drawPWMbox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- PWM
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
    if pwm_percent > -1 then
		
		-- draw fixed Text
		lcd.drawText(x, y + 5, "PWM:", FONT_MINI)
		lcd.drawText(x + 80, y + 8,"%",FONT_MINI)
		lcd.drawText(x + 96, y, "max:", FONT_MINI)

		-- draw Values  
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",pwm_percent)),y, string.format("%.0f",pwm_percent),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",maxpwm)) / 2,y + 10, string.format("%.0f%%",maxpwm),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end		
end

-- Draw Throttle
local function drawThrottlebox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Throttle
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
	if throttle > -1 then
		
		-- draw fixed Text
		lcd.drawText(x, y + 5, "Throttle:", FONT_MINI)
		lcd.drawText(x + 80, y + 8,"%",FONT_MINI)
		lcd.drawText(x + 96, y, "max:", FONT_MINI)

		-- draw Values  
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",throttle)),y, string.format("%.0f",throttle),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",maxThrottle)) / 2,y + 10, string.format("%.0f%%",maxThrottle),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end		
end

-- Draw Ibec
local function drawIBECbox(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc)	-- Ibec
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
  local y = yStart - 5
	if bec_current > -1 then
		
		-- draw fixed Text
		lcd.drawText(x, y + 5, "IBEC:", FONT_MINI)
		lcd.drawText(x + 80, y + 8,"A",FONT_MINI)
		lcd.drawText(x + 96, y, "max:", FONT_MINI)

		-- draw Values  
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",bec_current)),y, string.format("%.0f",bec_current),FONT_BIG)
		lcd.drawText(x + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",maxIBEC)) / 2,y + 10, string.format("%.0fA",maxIBEC),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end

local function drawHeight(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc) -- height
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxheight = maxheight
	if height > -1000 then
		-- draw fixed Text
		lcd.drawText(x, y + 6, vars.trans.height, FONT_MINI)
		lcd.drawText(x + 79, y + 9, "m", FONT_MINI)
		lcd.drawText(x + 98, y, "max:", FONT_MINI)
			
		-- draw height
		local deci = "%.1f"
		if height >= 100 or height <= -100 then deci = "%.0f" end
		if drawmaxheight == -1000 then drawmaxheight = 0 end
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,height)),y + 1, string.format(deci,height),FONT_BIG)
		lcd.drawText(x + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",drawmaxheight)) / 2,y + 10, string.format("%.0f",drawmaxheight),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
			lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end

local function drawVario(iDraw, maxDraw, iSep, thick, lengthSep, x, yStart, yDist, calc) -- vario
	local yDraw = 15  -- Höhe der Anzeige ohne Seperator
	local y = yStart - 5
	local drawmaxvario = maxvario
	local drawminvario = minvario
	
	if vario > -1 then
		-- draw fixed Text
		lcd.drawText(x, y + 6, vars.trans.vario, FONT_MINI)
		lcd.drawText(x + 80, y, "m", FONT_MINI)
		lcd.drawText(x + 79, y + 1, "___", FONT_MINI)
		lcd.drawText(x + 82, y + 9, "s", FONT_MINI)
				
		-- draw vario 
		local deci = "%.1f"
		--if vario >= 10 or vario <= 10 then deci = "%.0f" end
		if drawmaxvario == -99.9 then drawmaxvario = 0 end
		if drawminvario == 99.9 then drawminvario = 0 end
		lcd.drawText(x + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,vario)),y + 1, string.format(deci,vario),FONT_BIG)
		lcd.drawText(x + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawmaxvario)),y + 1, string.format("%.1f",drawmaxvario),FONT_MINI)
		lcd.drawText(x + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawminvario)),y + 10, string.format("%.1f",drawminvario),FONT_MINI)
		iDraw = iDraw + 1
		if iDraw < maxDraw then
      lcd.drawFilledRectangle(x, yStart + yDraw + yDist, lengthSep, thick)
			if calc == true then iSep = iSep + 2 end
			return yStart + yDraw + yDist * 2 + thick, iDraw, iSep
		end		
		return yStart + yDraw, iDraw, iSep   -- letztes Feld, kein Seperator
	else
		return yStart, iDraw, iSep
	end	
end


local function loop()
	local sensor
    local txtelemetry
	local anCapaGo = system.getInputsVal(vars.anCapaSw)
	local anVoltGo = system.getInputsVal(vars.anVoltSw)
	local tickTime = system.getTime()
  
	FlightTime()
	
	
	if vars.gyChannel ~= 17 then gyro_channel_value = system.getInputs(vars.gyro_output)
	else gyro_channel_value = 17
	end
	
	
	-- Rx values:
	txtelemetry = system.getTxTelemetry()
	rx_voltage = txtelemetry.rx1Voltage
	rx_percent = txtelemetry.rx1Percent 
	rx_a1 = txtelemetry.RSSI[1]
	rx_a2 = txtelemetry.RSSI[2]
	
	if initialRx == false then 
		if rx_percent > 99.0 then initialRx = true end
	end
	if initialRx == true then
		if rx_voltage > 0.0 and rx_voltage < minrx_voltage then minrx_voltage = rx_voltage end
		if rx_percent > 0.0 and rx_percent < minrx_percent then minrx_percent = rx_percent end
		if rx_a1 > 0 and rx_a1 < minrx_a1 then minrx_a1 = rx_a1 end
		if rx_a2 > 0 and rx_a2 < minrx_a2 then minrx_a2 = rx_a2 end
		colorRed = 220
		if rx_percent < 1 then setminmax() end
	end
  
  	
	-- Read Sensor Parameter Voltage 
	sensor = system.getSensorValueByID(vars.sensorId, vars.battery_voltage_param)

	if(sensor and sensor.valid ) then
		battery_voltage = sensor.value
	-- guess used capacity from voltage if we started with partially discharged battery 
		if (initial_voltage_measured == false) then
			if ( battery_voltage > 3 ) then
				initial_voltage_measured = true
				initial_cell_voltage = battery_voltage / vars.cell_count
				initial_capacity_percent_used = get_capacity_percent_used()
			end    
		end        
		
		-- calculate Min/Max Sensor 1
		if ( battery_voltage < minvtg and battery_voltage > 6 ) then minvtg = battery_voltage end
		if battery_voltage > maxvtg then maxvtg = battery_voltage end
		
		if newTime >= (last_averaging_time + 1000) then          -- one second period, newTime set from FlightTime()
			battery_voltage_average = average(battery_voltage)   -- average voltages over n samples
			last_averaging_time = newTime
		end
	else
		battery_voltage = 0
		initial_voltage_measured = true
		if vars.battery_voltage_param ~= 0 then 
      battery_voltage_average = 0
      initial_voltage_measured = false
    end
	end
	
	-- Read Sensor Parameter Pump voltage
	sensor = system.getSensorValueByID(vars.sensorId, vars.pump_voltage_param)
	if(sensor and sensor.valid) then
		pump_voltage = sensor.value
		-- calculate Min/Max Sensor 2
		if (initial_pump_voltage_measured == false) then
			if ( pump_voltage > 1 ) then 
				initial_pump_voltage_measured = true
				minpump_voltage = 9.9
			end
		else
			if pump_voltage < minpump_voltage then minpump_voltage = pump_voltage end
			if pump_voltage > maxpump_voltage then maxpump_voltage = pump_voltage end
		end
	else
		if vars.pump_voltage_param ~= 0 then pump_voltage = 0 end
	end
	
	-- Read Status Parameter 
	sensor = system.getSensorValueByID(vars.sensorId, vars.status_param)
	if(sensor and sensor.valid) then
		if Global_TurbineState ~= "" then  status = Global_TurbineState
			else status = sensor.value
		end
	else
		if vars.status_param ~= 0 then status = "kein Status" end
	end
	
	-- Read remaining fuel percent
	sensor = system.getSensorValueByID(vars.sensorId, vars.remaining_fuel_percent_param)
	if(sensor and sensor.valid) then
		remaining_fuel_percent = sensor.value
	else
		if vars.remaining_fuel_percent_param ~= 0 then 
			remaining_fuel_percent = 0 
		else
			if Calca_dispGas then remaining_fuel_percent = Calca_dispGas
							 else remaining_fuel_percent = -1 
			end
		end
	end
	
	
        
	-- Read Sensor Parameter Current 
	sensor = system.getSensorValueByID(vars.sensorId, vars.motor_current_param)
	if(sensor and sensor.valid) then
		motor_current = sensor.value
		-- calculate Min/Max Sensor 2
		if motor_current < mincur then mincur = motor_current end
		if motor_current > maxcur then maxcur = motor_current end
		
	else
		if vars.motor_current_param ~= 0 then motor_current = 0 end
	end

	-- Read Sensor Parameter Rotor RPM
	sensor = system.getSensorValueByID(vars.sensorId, vars.rotor_rpm_param)
	if(sensor and sensor.valid) then
		rotor_rpm = sensor.value
		-- calculate Min/Max Sensor 3
		if rotor_rpm < minrpm then minrpm = rotor_rpm end
		if rotor_rpm > maxrpm then maxrpm = rotor_rpm end
	else
		if vars.rotor_rpm_param ~= 0 then rotor_rpm = 0 end
	end
	

	-- Read Sensor Parameter Used Capacity
	sensor = system.getSensorValueByID(vars.sensorId, vars.used_capacity_param)

	if(sensor and sensor.valid) then -- and (battery_voltage > 1.0)) then
		used_capacity = sensor.value

		if ( initial_voltage_measured == true ) then
			remaining_capacity_percent = math.floor( ( ( (vars.capacity - used_capacity) * 100) / vars.capacity ) - initial_capacity_percent_used)
			if remaining_capacity_percent < 0 then remaining_capacity_percent = 0 end
		end
            
		if ( remaining_capacity_percent <= vars.capacity_alarm_thresh and vars.capacity_alarm_voice ~= "..." and next_capacity_alarm < tickTime and iKapAlarm < imaxAlarm ) then
			system.messageBox(vars.trans.capaWarn,2)
			system.playFile(vars.capacity_alarm_voice,AUDIO_QUEUE)
			iKapAlarm = iKapAlarm + 1
      next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 second
		end
        
		if ( battery_voltage_average <= voltage_alarm_dec_thresh and vars.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime ) then
			system.messageBox(vars.trans.voltWarn,2)
			system.playFile(vars.voltage_alarm_voice,AUDIO_QUEUE)
      next_voltage_alarm = tickTime + 5 -- battery voltage alarm every 4 second 
		end    
             
		if(anCapaGo == 1 and tickTime >= next_capacity_announcement) then
			system.playNumber(remaining_capacity_percent, 0, "%", "Capacity")
			next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
		end

		if(anVoltGo == 1 and tickTime >= next_voltage_announcement) then
			system.playNumber(battery_voltage, 1, "V", "U Battery")
			next_voltage_announcement = tickTime + 10 -- say battery voltage every 10 seconds
		end
                 
		-- Set max/min percentage to 99/0 for drawing
		if( remaining_capacity_percent > 100 ) then remaining_capacity_percent = 100 end
		if( remaining_capacity_percent < 0 ) then remaining_capacity_percent = 0 end
	else
		if vars.used_capacity_param ~= 0 then
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


	-- Read Sensor Parameter 6 BEC Current
	sensor = system.getSensorValueByID(vars.sensorId, vars.bec_current_param)
	if(sensor and sensor.valid) then
		bec_current = sensor.value 
		if bec_current < minIBEC then minIBEC = bec_current end
		if bec_current > maxIBEC then maxIBEC = bec_current end
	else
		if vars.bec_current_param ~= 0 then bec_current = 0 end
	end

	-- Read Sensor Parameter Governor PWM
	sensor = system.getSensorValueByID(vars.sensorId, vars.pwm_percent_param)
	if(sensor and sensor.valid) then
		pwm_percent = sensor.value
		if pwm_percent < minpwm then minpwm = pwm_percent end
		if pwm_percent > maxpwm then maxpwm = pwm_percent end
	else
		if vars.pwm_percent_param ~= 0 then pwm_percent = 0 end
	end

	-- Read Sensor Parameter FET Temperature
	sensor = system.getSensorValueByID(vars.sensorId, vars.fet_temp_param)
	if(sensor and sensor.valid) then
		fet_temp = sensor.value 
		if fet_temp < mintmp then mintmp = fet_temp end
		if fet_temp > maxtmp then maxtmp = fet_temp end
	else
		if vars.fet_temp_param ~= 0 then fet_temp = 0 end
	end
	
	-- Read Sensor Parameter Throttle
	sensor = system.getSensorValueByID(vars.sensorId, vars.throttle_param)
	if(sensor and sensor.valid) then
		throttle = sensor.value 
		if throttle < minThrottle then minThrottle = fet_temp end
		if throttle > maxThrottle then maxThrottle = fet_temp end
	else
		if vars.throttle_param ~= 0 then throttle = 0 end
	end
	
	-- Read Sensor Parameter Height 
	sensor = system.getSensorValueByID(vars.sensorId, vars.height_param)
	if(sensor and sensor.valid) then
		height = sensor.value
		-- calculate Min/Max Sensor 2
		if height < minheight then minheight = height end
		if height > maxheight then maxheight = height end
		
	else
		if vars.height_param ~= 0 then height = 0 end
	end
	
	-- Read Sensor Parameter vario
	sensor = system.getSensorValueByID(vars.sensorId, vars.vario_param)
	if(sensor and sensor.valid) then
		vario = sensor.value
		-- calculate Min/Max Sensor 2
		if vario < minvario then minvario = vario end
		if vario > maxvario then maxvario = vario end
		
	else
		if vars.vario_param ~= 0 then vario = 0 end
	end
	
	print(system.getCPU())
end --loop


return {
	drawSeperator = drawSeperator,
	drawBattery = drawBattery,
	drawrpmbox = drawrpmbox,
	drawCurrent = drawCurrent,
	drawTotalCount = drawTotalCount,
	drawFlightTime = drawFlightTime,
	drawEngineTime = drawEngineTime,
	drawUsedCapacity = drawUsedCapacity,
	drawTempbox = drawTempbox,
	drawMibotbox = drawMibotbox,
	drawRxValues = drawRxValues,
	drawVpC = drawVpC,
	drawTempbox = drawTempbox,
	drawPWMbox = drawPWMbox,
	drawThrottlebox = drawThrottlebox,
	drawIBECbox = drawIBECbox,
	drawPump_voltagebox = drawPump_voltagebox,
	drawStatusbox = drawStatusbox,
	drawTank = drawTank,
	drawHeight = drawHeight,
	drawVario = drawVario,
	loop = loop,
	init = init,	
	saveFlights = saveFlights,
	loadFlights = loadFlights
}
