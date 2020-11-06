local anCapaGo, anVoltGo
local battery_voltage, battery_voltage_average, used_capacity = 0.0, 0.0, -1.0   -- battery_voltage_average von -1.0 auf 0.0 geändert
local remaining_capacity_percent, remaining_fuel_percent = 100, 100
local status1, status2 = "No Status" , "No Status"
local next_capacity_announcement, next_value_announcement, next_voltage_announcement, tickTime = 0, 0, 0, 0
local next_capacity_alarm, next_voltage_alarm = 0, 0
local last_averaging_time = 0
local voltage_alarm_dec_thresh
local voltages_list = {}
local RxTypen = {"rx1", "rx2", "rxB"}
local gyro_channel_value = 17
local iKapAlarm, iVoltageAlarm, imaxAlarm = 0, 0, 5
local capacity = 1
local cell_count = 1
local xStart
local yStart
local xli, xre = 2, 192 -- x Abstand der Anzeigeboxen vom linken Rand
local lengthSep = 160 - (xre - 160) - xli
local vars = {}
local MinMaxlbl = {}
local drawfunc = {}
local anCapaGo
local anCapaValGo
local yborder = 6
local drawVal = {}
local Rx = {}
local RfID = -1
local calcaApp = false
local lastUsedCapacity = 0
local minvperc = 0
local AkkuFull = 4.06  --bei einer Spannung über diesen Wert wird der Akku als voll erkannt
local AkkuUsed = 4.02  --bei einer Spannung unter diesem Wert wird der Akku als bereits etwas entladen erkannt


-- global:
dbdis_capacity = nil

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
 
 ---------------------------------------------------Draw functions----------------------------------------
-- Draw Battery and percentage display
local function drawBattery()
	if used_capacity > -1 then
		local temp
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
		local drawcapacity = capacity
		if vars.AkkusID[drawVal.batID_sens] then
			if drawcapacity == 1 then drawcapacity = 0 end
			lcd.drawText(160-(lcd.getTextWidth(FONT_BIG, string.format("%.f",drawcapacity)) / 2),40, string.format("%.f", drawcapacity),FONT_BIG)
			lcd.drawText(148, 60, "mAh", FONT_MINI)

			temp = string.format("%.f",cell_count).."S"
			if drawVal.batC_sens > 0 then temp = temp.." / "..string.format("%.f",drawVal.batC_sens).."C" end
			if gyro_channel_value == 17 then 
				lcd.drawText(160-(lcd.getTextWidth(FONT_NORMAL, temp) / 2),142, temp,FONT_NORMAL)
			else
				lcd.setColor(0,0,200)
				lcd.drawText(160-(lcd.getTextWidth(FONT_MINI,temp) / 2),127,temp,FONT_MINI)
				colstd()
			end
			
			-- ID, Name
			lcd.drawText(160-(lcd.getTextWidth(FONT_NORMAL, string.format("%.f",drawVal.batID_sens)) / 2),79, string.format("%.f", drawVal.batID_sens),FONT_NORMAL)
			lcd.drawText(160-(lcd.getTextWidth(FONT_MINI, string.format("%s",vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Name)) / 2),104, string.format("%s", vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Name),FONT_MINI)
		end
		
		if RfID > 0 then
			lcd.drawCircle(160,89,12)
			lcd.drawCircle(160,89,13)
		end
		
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
	
	-- Draw Gyro
	if gyro_channel_value ~= 17 then 
		local gyro_percent = gyro_channel_value * 60.606 + 63.6363

		if (gyro_percent < 40) then gyro_percent = 40 end
		if (gyro_percent > 120) then gyro_percent = 120 end

		-- draw fixed Text
		lcd.drawText(136,146,"GY",FONT_MINI)
		-- draw Max Values
		lcd.drawText(184 - lcd.getTextWidth(FONT_BIG, string.format("%.0f", gyro_percent)), 141, string.format("%.0f", gyro_percent), FONT_BIG)
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
		local i
		local strTank_volume = tostring(vars.tank_volume)

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

		 -- Text in Tank

		for i = 1, #strTank_volume do
			lcd.drawText(146,30 + i * 15, string.sub(strTank_volume, i,i),FONT_NORMAL)
		end
		lcd.drawText(141, 45 + #strTank_volume * 15, "ml", FONT_NORMAL)



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

-- Draw Total time box
function drawfunc.TotalCount() --Total flight Time
	local std, min, sec, y
	if vars.timeToCount > 0 then
		y = yStart - 2
		-- draw fixed Text
		lcd.drawText(xStart, y, vars.trans.ftime, FONT_MINI)
		
		-- draw Values
		lcd.drawText(xStart + 37,y, string.format("%.0f", vars.totalCount), FONT_MINI) -- Anzahl Flüge gesamt
		
		std = math.floor(vars.totalFlighttime / 3600)
		min = (vars.totalFlighttime % 3600) / 60
		sec = vars.totalFlighttime % 60
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_MINI, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_MINI) -- total Flight time	
	end
end

-- Draw Flight time box
function drawfunc.FlightTime()	-- Flight flight Time
	local y = yStart - 3
	local std, min, sec = 0, 0, 0

	-- draw Values
	lcd.drawText(xStart + 25 - lcd.getTextWidth(FONT_BIG, string.format("%.0f.", vars.todayCount)),y, string.format("%.0f.", vars.todayCount), FONT_BIG) -- flights today
	std = math.floor(vars.flightTime / 3600000)
	min = (vars.flightTime % 3600000) / 60000
	sec = (vars.flightTime % 60000) / 1000	
	if std ~= 0 then
		lcd.drawText(xStart + 125 - lcd.getTextWidth(FONT_BIG, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_BIG) -- Flight time
	else
		lcd.drawText(xStart + 125 - lcd.getTextWidth(FONT_BIG, string.format("%02d' %02d\"",min, sec)), y, string.format("%02d' %02d\"",min, sec), FONT_BIG) -- Flight time
	end
end

-- Draw engine time box
function drawfunc.EngineTime()	-- engine Time
	local y = yStart - 4
	local std, min, sec = 0, 0, 0
	-- draw fixed Text
	lcd.drawText(xStart, y + 3, vars.trans.engineTime, FONT_MINI)

	-- draw Values
	std = math.floor(vars.engineTime / 3600000)
	min = (vars.engineTime % 3600000) / 60000
	sec = (vars.engineTime % 60000) / 1000	
	if std ~= 0 then
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_NORMAL) -- engine time
	else
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%02d' %02d\"", min, sec)), y, string.format("%02d' %02d\"", min, sec), FONT_NORMAL) -- engine time
	end
end

-- Draw Receiver values
function drawRxValues(RxTyp)	-- Rx Values
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

	draw_minRx_a1 = vars.Rx[RxTyp].mina1
	draw_minRx_a2 = vars.Rx[RxTyp].mina2
	draw_minRx_percent = vars.Rx[RxTyp].minpercent
	draw_minRx_voltage = vars.Rx[RxTyp].minvoltage
	
    
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
	local y = yStart - 2
	-- draw fixed Text
	lcd.drawText(xStart + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.mainbat) / 2),y,vars.trans.mainbat,FONT_MINI)  --xStart=57,y=1
	lcd.drawText(xStart, y + 18, "min:", FONT_MINI)
	--lcd.drawText(xStart + 51, y + 18, "V", FONT_MINI)
	lcd.drawText(xStart + 63, y + 18, "akt:", FONT_MINI)
	--lcd.drawText(xStart + 111, y + 18, "V", FONT_MINI)
	
	-- draw Values, average is average of last 1000 values
	local deci = "%.2f"
	minvperc = 0
	local battery_voltage_average_perc = battery_voltage_average / cell_count
	if vars.minvtg == 99.9 then minvperc = 0
	else minvperc = vars.minvtg/cell_count
	end
	if minvperc >= 10.0 then deci = "%.1f" end
	if vars.initial_voltage_measured and minvperc <= voltage_alarm_dec_thresh then colalarm() else colmin() end
	lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BIG, string.format(deci, minvperc)),y + 10, string.format(deci, minvperc), FONT_BIG)
	colstd()
	deci = "%.2f"
	if battery_voltage_average_perc >= 10.0 then deci = "%.1f" end
	if vars.initial_voltage_measured and battery_voltage_average_perc <= voltage_alarm_dec_thresh then colalarm() end
	lcd.drawText(xStart + 119 - lcd.getTextWidth(FONT_BIG, string.format(deci, battery_voltage_average_perc)),y + 10, string.format(deci, battery_voltage_average_perc), FONT_BIG)
	colstd()
end
--- Used Capacity
function drawfunc.UsedCapacity()	-- Used Capacity
	local y = yStart - 2
	local total_used_capacity = math.ceil( used_capacity + (vars.oldAkku * lastUsedCapacity) + (vars.initial_capacity_percent_used * math.abs(vars.oldAkku -1) * capacity) / 100 )

	-- draw fixed Text
	lcd.drawText(xStart + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.usedCapa) / 2),y,vars.trans.usedCapa,FONT_MINI)
	lcd.drawText(xStart + 96, y + 20, "mAh", FONT_MINI)

	-- draw Values
	lcd.drawText(xStart + 94 - lcd.getTextWidth(FONT_MAXI, string.format("%.0f",total_used_capacity)),y + 5, string.format("%.0f", total_used_capacity), FONT_MAXI)
end

-- Draw Status
function drawfunc.Status()	-- Status
	lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, status1)/2,yStart - 4, status1,FONT_BOLD)	
end

-- Draw Status2
function drawfunc.Status2()	-- Status
	lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, status2)/2,yStart - 4, status2,FONT_BOLD)	
end

-- Draw Pump voltage
function drawfunc.Pump_voltage()	-- Pump voltage
	local y = yStart - 3
	local drawminpump_voltage = vars.drawVal.pump_voltage_sens.max
		
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, "U Pump:", FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"V",FONT_MINI)
	lcd.drawText(xStart + 98, y, "min:", FONT_MINI)

	-- draw Values  
	if drawminpump_voltage == -999.9 then drawminpump_voltage = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",drawVal.pump_voltage_sens)),y, string.format("%.1f",drawVal.pump_voltage_sens),FONT_BIG)
	colmin()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.1fV",drawminpump_voltage)) / 2,y + 10, string.format("%.1fV",drawminpump_voltage),FONT_MINI)
	colstd()		
end

-- Draw Rotor speed box
function drawfunc.RPM()	-- Rotor Speed RPM
	local y = yStart - 9
	local drawmaxrpm = vars.drawVal.rotor_rpm_sens.max
	lcd.drawText(xStart + 112, y + 12, "-1", FONT_MINI)
	lcd.drawText(xStart + 100, y + 21, "min", FONT_MINI)
	lcd.drawText(xStart + 00, y + 35, "Max:", FONT_MINI)

	-- draw Values
	if drawmaxrpm == -999.9 then drawmaxrpm = 0 end
	lcd.drawText(xStart + 97 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",drawVal.rotor_rpm_sens)),y,string.format("%.0f",drawVal.rotor_rpm_sens),FONT_MAXI)
	colmax()
	lcd.drawText(xStart + 95 - lcd.getTextWidth(FONT_MINI,string.format("%.0f",drawmaxrpm)),y + 35, string.format("%.0f", drawmaxrpm), FONT_MINI)
	colstd()	
end

-- Draw current box
function drawfunc.Current() -- current
	local y = yStart - 4
	local drawmaxcur = vars.drawVal.motor_current_sens.max
	-- draw fixed Text
	lcd.drawText(xStart, y, "I", FONT_BIG)
	lcd.drawText(xStart + 7, y + 8, "Motor:", FONT_MINI)
	lcd.drawText(xStart + 86, y + 8, "A", FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)
		
	-- draw current 
	if drawmaxcur == -999.9 then drawmaxcur = 0 end
	local deci = "%.1f"
	if drawVal.motor_current_sens >= 100 then deci = "%.0f" end
	lcd.drawText(xStart + 85 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.motor_current_sens)),y, string.format(deci,drawVal.motor_current_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",drawmaxcur)) / 2,y + 10, string.format("%.0fA",drawmaxcur),FONT_MINI)
	colstd()
end

-- Draw Temperature
function drawfunc.Temp()	-- Temperature
	local y = yStart - 4
	local drawmaxtmp = vars.drawVal.fet_temp_sens.max
		
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, vars.trans.Temp, FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"°C",FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- draw Values  
	if drawmaxtmp == -999.9 then drawmaxtmp = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.fet_temp_sens)),y, string.format("%.0f",drawVal.fet_temp_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f°C",drawmaxtmp)) / 2,y + 10, string.format("%.0f°C",drawmaxtmp),FONT_MINI)
	colstd()
		
end

-- Draw PWM
function drawfunc.PWM()	-- PWM
	local y = yStart - 4
	local drawmaxpwm = vars.drawVal.pwm_percent_sens.max
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, "PWM:", FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- draw Values  
	if drawmaxpwm == -999.9 then drawmaxpwm = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.pwm_percent_sens)),y, string.format("%.0f",drawVal.pwm_percent_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",drawmaxpwm)) / 2,y + 10, string.format("%.0f%%",drawmaxpwm),FONT_MINI)
	colstd()
end

-- Draw Throttle
function drawfunc.Throttle()	-- Throttle
	local y = yStart - 4
	local drawmaxThrottle = vars.drawVal.throttle_sens.max
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, "Throttle:", FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- draw Values  
	if drawmaxThrottle == -999.9 then drawmaxThrottle = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.throttle_sens)),y, string.format("%.0f",drawVal.throttle_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",drawmaxThrottle)) / 2,y + 10, string.format("%.0f%%",drawmaxThrottle),FONT_MINI)
	colstd()
end

-- Draw Ibec
function drawfunc.I_BEC()	-- Ibec
	local y = yStart - 4
	local drawmaxIBEC = vars.drawVal.bec_current_sens.max
		
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, "IBEC:", FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"A",FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- draw Values 
	if drawmaxIBEC == -999.9 then drawmaxIBEC = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",drawVal.bec_current_sens)),y, string.format("%.0f",drawVal.bec_current_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",drawmaxIBEC)) / 2,y + 10, string.format("%.0fA",drawmaxIBEC),FONT_MINI)
	colstd()
end

--Draw Altitude
function drawfunc.Altitude() -- altitude
	local y = yStart - 4
	local drawmaxaltitude = vars.drawVal.altitude_sens.max
	-- draw fixed Text
	lcd.drawText(xStart, y + 6, vars.trans.altitude_sens, FONT_MINI)
	lcd.drawText(xStart + 79, y + 9, "m", FONT_MINI)
	lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
		
	-- draw altitude
	local deci = "%.1f"
	if drawVal.altitude_sens >= 100 or drawVal.altitude_sens <= -100 then deci = "%.0f" end
	if drawmaxaltitude == -999.9 then drawmaxaltitude = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.altitude_sens)),y + 1, string.format(deci,drawVal.altitude_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",drawmaxaltitude)) / 2,y + 10, string.format("%.0f",drawmaxaltitude),FONT_MINI)
	colstd()
end

--Draw Speed
function drawfunc.Speed() -- speed
	local y = yStart - 4
	local drawmaxspeed = vars.drawVal.speed_sens.max
	-- draw fixed Text
	lcd.drawText(xStart, y + 6, vars.trans.speed_sens, FONT_MINI)
	lcd.drawText(xStart + 79, y, "km", FONT_MINI)
	lcd.drawText(xStart + 79, y + 1, "____", FONT_MINI)
	lcd.drawText(xStart + 84, y + 11, "h", FONT_MINI)
	lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
		
	-- draw speed
	local deci = "%.1f"
	if drawVal.speed_sens >= 10 or drawVal.speed_sens <= -10 then deci = "%.0f" end
	if drawmaxspeed == -999.9 then drawmaxspeed = 0 end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.speed_sens)),y + 1, string.format(deci,drawVal.speed_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",drawmaxspeed)) / 2,y + 10, string.format("%.0f",drawmaxspeed),FONT_MINI)
	colstd()
end

-- Draw Vario
function drawfunc.Vario() -- vario
	local y = yStart - 3
	local drawmaxvario = vars.drawVal.vario_sens.max
	local drawminvario = vars.drawVal.vario_sens.min
	
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
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,drawVal.vario_sens)),y + 1, string.format(deci,drawVal.vario_sens),FONT_BIG)
	colmax()
	lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawmaxvario)),y + 1, string.format("%.1f",drawmaxvario),FONT_MINI)
	colmin()
	lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",drawminvario)),y + 10, string.format("%.1f",drawminvario),FONT_MINI)
	colstd()
end

-- Draw C1,I1 box
function drawfunc.C1_and_I1() -- C1, I1
	local y = yStart - 2
	local drawmax = vars.drawVal.I1_sens.max
	local deci
	if drawVal.UsedCap1_sens > -1000 then
		-- draw C1
		lcd.drawText(xStart, y, "C", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "1:", FONT_MINI)
		lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
		deci = "%.0f"
		lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.UsedCap1_sens)),y, string.format(deci,drawVal.UsedCap1_sens),FONT_NORMAL)
	end
	if drawVal.I1_sens > -1000 then
		-- draw I1
		lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
		lcd.drawText(xStart + 84, y + 5, "1:", FONT_MINI)
		if drawmax == -999.9 then drawmax = 0 end
		deci = "%.1fA"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.I1_sens)),y - 1, string.format(deci,drawVal.I1_sens),FONT_MINI)
		colmax()
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",drawmax)),y + 7, string.format("%.1fA",drawmax),FONT_MINI)
		colstd()
	end
end

-- Draw C2,I2 box
function drawfunc.C2_and_I2() -- C2, I2
	local y = yStart - 2
	local drawmax = vars.drawVal.I2_sens.max
	local deci
	if drawVal.UsedCap2_sens > -1000 then
		-- draw C1
		lcd.drawText(xStart, y, "C", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "2:", FONT_MINI)
		lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
		deci = "%.0f"
		lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.UsedCap2_sens)),y, string.format(deci,drawVal.UsedCap2_sens),FONT_NORMAL)
	end
	if drawVal.I2_sens > -1000 then
		-- draw I1
		lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
		lcd.drawText(xStart + 84, y + 5, "2:", FONT_MINI)
		if drawmax == -999.9 then drawmax = 0 end
		deci = "%.1fA"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.I2_sens)),y - 1, string.format(deci,drawVal.I2_sens),FONT_MINI)
		colmax()
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",drawmax)),y + 7, string.format("%.1fA",drawmax),FONT_MINI)
		colstd()
	end
end

-- Draw U1, Temp box
function drawfunc.U1_and_Temp() -- U1, Temp
	local y = yStart - 1
	local drawmin = vars.drawVal.U1_sens.min
	local drawmax = vars.drawVal.Temp_sens.max
	local deci
	if drawVal.U1_sens > -1000 then
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
		lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.U1_sens)),y, string.format(deci,drawVal.U1_sens),FONT_NORMAL)
	end
	if drawVal.Temp_sens > -1000 then
		-- draw Temp
		lcd.drawText(xStart + 83, y, "T:", FONT_NORMAL)
		if drawmax == -999.9 then drawmax = 0 end
		deci = "%.0f°C"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawVal.Temp_sens)),y - 1, string.format(deci,drawVal.Temp_sens),FONT_MINI)
		colmax()
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,drawmax)),y + 7, string.format(deci,drawmax),FONT_MINI)
		colstd()
	end
end

-- Draw U2, OverI
function drawfunc.U2_and_OI() -- U2, OverI
	local y = yStart - 4
	local drawmin = vars.drawVal.U2_sens.min
	local deci
	if drawVal.U2_sens > -1000 then
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
		lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.U2_sens)),y, string.format(deci,drawVal.U2_sens),FONT_NORMAL)
	end
	if drawVal.OverI_sens > -1000 then
		-- draw Temp
		lcd.drawText(xStart + 90, y, "OI:", FONT_NORMAL)
		deci = "%.0f"
		if drawVal.OverI_sens > 0 then colalarm() end
		lcd.drawText(xStart + 120 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,drawVal.OverI_sens)),y, string.format(deci,drawVal.OverI_sens),FONT_NORMAL)
		colstd()
	end
end

local function showDisplay(page)
	local i,j	
	colstd()
 		
	--left:	
	yStart = vars[page].leftstart
	xStart = xli
	for i,j in ipairs(vars[page].leftdrawcol) do 
		if vars[page].cd[j].sep == -1 then
			yStart = yStart + yborder / 2
			drawfunc[j]()
			lcd.drawRectangle(0, yStart - yborder / 2, 130, vars[page].cd[j].y + yborder, 4)
			yStart = yStart + vars[page].cd[j].y + yborder / 2 + vars[page].cd[j].distdraw
		else
			drawfunc[j]()
			yStart = yStart + vars[page].cd[j].y + vars[page].cd[j].distdraw
			if vars[page].cd[j].sepdraw > 0 then 
				lcd.drawFilledRectangle(xli, yStart , lengthSep, vars[page].cd[j].sep)
				yStart = yStart + vars[page].cd[j].sep + vars[page].cd[j].distdraw
			end
		end
	end
	
--------------	
	--right
	yStart = vars[page].rightstart
	xStart = xre
	for i,j in ipairs(vars[page].rightdrawcol) do 
		if vars[page].cd[j].sep == -1 then
			yStart = yStart + yborder / 2
			drawfunc[j]()
			lcd.drawRectangle(190, yStart - yborder / 2, 128, vars[page].cd[j].y + yborder, 4)
			yStart = yStart + vars[page].cd[j].y + yborder / 2 + vars[page].cd[j].distdraw
		else
			drawfunc[j]()
			yStart = yStart + vars[page].cd[j].y + vars[page].cd[j].distdraw
			if vars[page].cd[j].sepdraw > 0 then 
				lcd.drawFilledRectangle(xre, yStart , lengthSep, vars[page].cd[j].sep)
				yStart = yStart + vars[page].cd[j].sep + vars[page].cd[j].distdraw
			end
		end
	end


	-- middle
	drawBattery()
	drawTank()

	collectgarbage()
end

------------------------------------------------------------End of Draw functions

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


local function setvars(varstemp)
	MinMaxlbl = {"motor_current_sens", "bec_current_sens", "pwm_percent_sens", "fet_temp_sens", "throttle_sens", "I1_sens", "I2_sens", "Temp_sens", "rotor_rpm_sens",
		"altitude_sens", "speed_sens", "vario_sens", "U1_sens", "U2_sens", "pump_voltage_sens"}
	vars = varstemp
	for i,RxTyp in ipairs(RxTypen) do
		Rx[RxTyp] = {}
		Rx[RxTyp].voltage = 0
		Rx[RxTyp].percent = 0
		Rx[RxTyp].a1 = 0
		Rx[RxTyp].a2 = 0
	end
	for i, sens in ipairs(MinMaxlbl) do
		drawVal[sens] = -1000.0
	end
	for i, sens in ipairs({"batC_sens", "batCap_sens", "batCells_sens"}) do
		drawVal[sens] = -2 
	end
	drawVal.batID_sens = -2
	drawVal.UsedCap1_sens = -1000
	drawVal.UsedCap2_sens = -1000
	drawVal.OverI_sens = -1000
	voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 100
	iKapAlarm = 0
	iVoltageAlarm = 0
	collectgarbage()
end
-- maximal bzw. minimalWerte setzen
local function setminmax()
	local i
	local sens
	local RxTyp
	
	
	for i,RxTyp in ipairs(RxTypen) do
		vars.Rx[RxTyp] = {}
		vars.Rx[RxTyp].initial = false
		vars.Rx[RxTyp].mina1 = 99
		vars.Rx[RxTyp].mina2 = 99
		vars.Rx[RxTyp].minvoltage = 9.9
		vars.Rx[RxTyp].minpercent = 101.0
	end
	
	for i, sens in ipairs(MinMaxlbl) do
		vars.drawVal[sens] = {}
		vars.drawVal[sens].min = 999.9
		vars.drawVal[sens].max = -999.9
		vars.drawVal[sens].measured = true
	end
		
	vars.drawVal.pump_voltage_sens.measured = false
	vars.drawVal.U1_sens.measured = false
	vars.drawVal.U2_sens.measured = false
	vars.initial_voltage_measured = false
	vars.minvtg, vars.maxvtg = 99.9, 0
	vars.flightTime = 0
	vars.engineTime = 0
	vars.counttheFlight = false
    vars.counttheTime = false  
	vars.countedTime = 0
	vars.lastFlightTime = 0
	vars.initial_cell_voltage = 0
	calcaApp = false
	RfID = -1
	lastUsedCapacity = 0

	
	collectgarbage()
end

local function init (varstemp)
	varstemp.drawVal = {}
	varstemp.Rx = {}
	varstemp.drawVal.UsedCap1_sens = {}	
	varstemp.drawVal.UsedCap2_sens = {}
	varstemp.drawVal.OverI_sens = {}
	varstemp.initial_capacity_percent_used = 0
	varstemp.oldAkku = 0
 	setvars(varstemp)
	setminmax()
	
		
	voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 100
	loadFlights()
	
	vars.lastTime = system.getTimeCounter()
	vars.lastEngineTime = vars.lastTime
	
	collectgarbage()
	return (vars)
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

local function writeLog()

	-- save Akkus
	local mahCapaLog = 0
    local battDspCount = 0
	
	if vars.AkkusID[drawVal.batID_sens] then 	
		--if (battery_voltage_average / cell_count) < (vars.initial_cell_voltage - 0.1) or used_capacity > (capacity / 10) then -- Akku wurde gebraucht
		if (battery_voltage_average / cell_count) < AkkuUsed then -- Akku wurde gebraucht
			if vars.initial_cell_voltage > AkkuFull  or calcaApp then -- Akku frisch geladen gewesen
				vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Cycl = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Cycl + 1
				vars.Akkus[vars.AkkusID[drawVal.batID_sens]].usedCapacity = 0.0
			end
			vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Ah = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Ah + (used_capacity / 1000)
			vars.Akkus[vars.AkkusID[drawVal.batID_sens]].lastVoltage = battery_voltage_average / cell_count
			vars.Akkus[vars.AkkusID[drawVal.batID_sens]].usedCapacity = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].usedCapacity + used_capacity			
			saveAkkus()
			mahCapaLog = string.format("%.0f",used_capacity)
		end
		battDspCount = string.format("%.0f",vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Cycl)
	end
		
	-- write logfile
	local dtflighttime = string.format("% 4d:%02d:%02d", math.floor(vars.flightTime / 3600000), (vars.flightTime % 3600000) / 60000, (vars.flightTime % 60000) / 1000)
	local dtengineTime = string.format("% 4d:%02d:%02d", math.floor(vars.engineTime / 3600000), (vars.engineTime % 3600000) / 60000, (vars.engineTime % 60000) / 1000)
	local dttotalFlighttime = string.format("% 3d:%02d:%02d", math.floor(vars.totalFlighttime / 3600), (vars.totalFlighttime % 3600) / 60, vars.totalFlighttime % 60)
    local dt = system.getDateTime()
    local dtDate = string.format("%d.%02d.%02d", dt.year, dt.mon, dt.day)
	local dtTime = string.format("%d:%02d", dt.hour, dt.min)
	local usedFuel = math.floor((100 - remaining_fuel_percent) * vars.tank_volume / 100)
	
    local logLine = string.format("%s;%s;%15s;% 3d;%s;%s;%s;% 3d;% 6d;% 9d;%  .2f;% 5d", dtDate, dtTime, vars.model, vars.totalCount, dttotalFlighttime, dtflighttime, dtengineTime, drawVal.batID_sens, battDspCount, mahCapaLog, minvperc, usedFuel)
	local fn = vars.appName.."_Log.txt"          --"Apps/"..vars.appName.."/Log_01.txt"
	local header = true
	local fwriteLog = io.open(fn,"r")
	if fwriteLog then 
		header = false 
		io.close(fwriteLog)
	end  
    fwriteLog = io.open(fn,"a")
    if(fwriteLog) then
		if header then io.write(fwriteLog,vars.trans.header) end
        io.write(fwriteLog, logLine,"\n")
        io.close(fwriteLog)
    end
	
    system.messageBox(vars.trans.logWrite, 5)
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

-- Count percentage from cell voltage
local function get_capacity_percent_used()
	local result=0
	local i
	if(vars.initial_cell_voltage > 4.2 or vars.initial_cell_voltage < 3.00)then
		if(vars.initial_cell_voltage > 4.2)then
			result=0
		end
		if(vars.initial_cell_voltage < 3.00)then
			result=100
		end
		else
		for i,v in ipairs(percentList) do
			if ( v[1] >= vars.initial_cell_voltage ) then
				result =  100 - v[2]
				break
			end
		end
	end

	collectgarbage()
	return result
end
 
           
-- Flight time
-- Der Flug wird erst gezählt und die Flugzeit zur Gesamtflugzeit addiert sobald der Timer zum ersten mal gestoppt wird und die minimale Flugzeit erreicht wurde.
-- Wird der Flug fortgesetzt wird beim nächsten Stop des Timers die Zeit zur Gesamtzeit hinzugefügt.
-- Wird wärend der Timer läuft der Reset betätigt wird der Timer auf 0 gesetzt. Wurde der Flug bereits gezählt, sprich der Timer vorher schon einmal gestoppt, dann beginnt ein neuer Flug
-- Wird der Reset betätigt ohne dass der Flug bereits gezählt wurde, dann wird der ganze Flug verworfen, und der Timer beginnt von vorne.

local function FlightTime()

	local timeSw_val = system.getInputsVal(vars.timeSw)
	local engineSw_val = system.getInputsVal(vars.engineSw)
	local resetSw_val = system.getInputsVal(vars.resSw)
	

	-- to be in sync with a system timer, do not use CLR key 
	if (resetSw_val == 1) then
		if vars.counttheFlight then 
			vars.counted = false 
			if vars.Rx.rx1.initial then writeLog() end
		end
		setminmax()
		vars.lastTime = newTime
		vars.lastEngineTime = newTime - vars.engineTime
	end
	
	if vars.timeSw ~= nil and timeSw_val ~= 0.0 and vars.Rx.rx1.initial then 
		if timeSw_val == 1 then
			vars.flightTime = newTime - vars.lastTime
			vars.counttheTime = false
			if vars.timeToCount > 0 and not vars.counted then 
				vars.todayCount = vars.todayCount + 1
				vars.counted = true
			end
			if Rx.rx1.percent < 1 and vars.timeToCount > 0 and vars.flightTime > vars.timeToCount * 1000 then  --Empfänger aus während Stoppuhr läuft
				if not vars.counttheFlight then 
					vars.totalCount = vars.totalCount + 1 
				end
				vars.totalFlighttime = vars.totalFlighttime + ((vars.flightTime - vars.lastFlightTime) / 1000)
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", math.floor(system.getTime() / 86400))			
				saveFlights()
				writeLog()
				vars.counted = false
				vars.Rx.rx1.initial = false
			end
		else	-- Stoppuhr gestoppt
			vars.lastTime = newTime - vars.flightTime -- properly start of first interval
			if vars.timeToCount > 0 and vars.flightTime > vars.timeToCount * 1000 and not vars.counttheFlight then  -- Count of the flights
				vars.totalCount = vars.totalCount + 1
				saveFlights()
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", math.floor(system.getTime() / 86400))
				vars.counttheFlight = true
			end
						
			if vars.counttheFlight and not vars.counttheTime then  --Flugzeiten
				vars.counttheTime = true
				vars.countedTime = vars.flightTime - vars.lastFlightTime
				vars.lastFlightTime = vars.lastFlightTime + vars.countedTime
				vars.totalFlighttime = vars.totalFlighttime + (vars.countedTime / 1000)   -- Gesamtflugzeit aller Flüge aufaddieren
				saveFlights()
			end
		end
	else
		vars.lastTime = newTime
	end
  
	if vars.engineSw ~= nil and engineSw_val ~= 0.0 and vars.Rx.rx1.initial then	
		if engineSw_val == 1 then
			vars.engineTime = newTime - vars.lastEngineTime
		else
			vars.lastEngineTime = newTime - vars.engineTime -- properly start of first interval
		end
	else
		vars.lastEngineTime = newTime
	end
	
	
	if Rx.rx1.percent < 1 and vars.Rx.rx1.initial then -- Empfänger aus bei gestoppter Stoppuhr
		if vars.counttheFlight then 
			vars.counted = false 
			writeLog()
		end
		vars.Rx.rx1.initial = false
	end
	
	
		   
	collectgarbage()
end
  

local function loop()
	local sensor
	local txtelemetry
	local anVoltGo = system.getInputsVal(vars.anVoltSw)
	local tickTime = system.getTime()
	local i
	local sens
	local temp
	local AkkuNeu = false
	
	newTime = system.getTimeCounter()
	
	-- Rx values:
	txtelemetry = system.getTxTelemetry()
	for i,RxTyp in ipairs(RxTypen) do
		Rx[RxTyp].percent = txtelemetry[RxTyp.."Percent"] 
		
		--if vars.engineSw then Rx.rx1.percent = system.getInputsVal(vars.engineSw) * 100 end ----------------- zum Testen!!!!!!!!!!!!!!!!!!!

		if not vars.Rx[RxTyp].initial then 
			if Rx[RxTyp].percent > 99.0 then 
				setminmax()
				vars.lastFlightTime = 0
				vars.flightTime = 0
				vars.engineTime = 0
				vars.lastTime = newTime
				vars.lastEngineTime = newTime - vars.engineTime
				vars.counttheFlight = false
				vars.counttheTime = false
				vars.Rx[RxTyp].initial = true
			end
		end
		
		if vars.Rx[RxTyp].initial then
			Rx[RxTyp].voltage = txtelemetry[RxTyp.."Voltage"]
			Rx[RxTyp].a1 = txtelemetry.RSSI[i*2-1]
			Rx[RxTyp].a2 = txtelemetry.RSSI[i*2]
			if Rx[RxTyp].voltage > 0.0 and Rx[RxTyp].voltage < vars.Rx[RxTyp].minvoltage then vars.Rx[RxTyp].minvoltage = Rx[RxTyp].voltage end
			if Rx[RxTyp].percent > 0.0 and Rx[RxTyp].percent < vars.Rx[RxTyp].minpercent then vars.Rx[RxTyp].minpercent = Rx[RxTyp].percent end
			if Rx[RxTyp].a1 > 0 and Rx[RxTyp].a1 < vars.Rx[RxTyp].mina1 then vars.Rx[RxTyp].mina1 = Rx[RxTyp].a1 end
			if Rx[RxTyp].a2 > 0 and Rx[RxTyp].a2 < vars.Rx[RxTyp].mina2 then vars.Rx[RxTyp].mina2 = Rx[RxTyp].a2 end
		end
	end 
	
	temp = system.getInputsVal(vars.anCapaSw)
	if anCapaGo ~= temp then
		anCapaGo = temp
		next_capacity_announcement = tickTime
	end
	
	temp = system.getInputsVal(vars.anCapaValSw)
	if anCapaValGo ~= temp then
		anCapaValGo = temp
		next_value_announcement = tickTime
	end
			
    
	FlightTime()
		
	if vars.gyChannel ~= 17 then gyro_channel_value = system.getInputs(vars.gyro_output)
	else gyro_channel_value = 17
	end
	

	-- Akku ID von Rfid
	sensor = system.getSensorValueByID(vars.batID_sens[1], vars.batID_sens[2])
	if sensor and sensor.valid then
		temp = sensor.value
		if temp ~= RfID and temp > 0 then
			RfID = temp
			drawVal.batID_sens = temp
			
			if vars.AkkusID[drawVal.batID_sens] then 
				capacity = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].Capacity
				cell_count = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].iCells
				cell_count = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].batC
				lastUsedCapacity = vars.Akkus[vars.AkkusID[drawVal.batID_sens]].usedCapacity
				
			else
				i = #vars.Akkus + 1
				vars.Akkus[i] = {}
				vars.Akkus[i].ID = drawVal.batID_sens
				vars.Akkus[i].Name = ""
				vars.Akkus[i].Cycl = 0
				vars.Akkus[i].Ah = 0
				vars.Akkus[i].lastVoltage = 0
				vars.Akkus[i].usedCapacity = 0
				vars.Akkus[i].batC = 0
				lastUsedCapacity = 0
				capacity = 0
				cell_count = 0
				AkkuNeu = true	
			end
			
			-- C-Rate von Rfid
			sensor = system.getSensorValueByID(vars.batC_sens[1], vars.batC_sens[2])
			if (sensor and sensor.valid) then 
				drawVal.batC_sens = sensor.value 
			else
				drawVal.batC_sens = -1
			end
				
			-- Kapazität von Rfid
			sensor = system.getSensorValueByID(vars.batCap_sens[1], vars.batCap_sens[2])
			if (sensor and sensor.valid) then
				if sensor.value > 0 then capacity = sensor.value end
			end	
			
			-- Zellenzahl von Rfid
			sensor = system.getSensorValueByID(vars.batCells_sens[1], vars.batCells_sens[2])
			if (sensor and sensor.valid) then
				if sensor.value > 0 then cell_count = sensor.value end
			end
			
			if AkkuNeu then 
				vars.Akkus[i].iCells = cell_count
				vars.Akkus[i].Capacity = capacity
				vars.Akkus[i].batC = drawVal.batC_sens
				saveAkkus()
				AkkuNeu = false
			end
			vars.initial_voltage_measured = false
		end
	end	
	if RfID == -1 then
		drawVal.batID_sens = -2
		if system.getInputsVal(vars.akkuSw) == 1 and vars.AkkusID[vars.Akku2ID] then 
			capacity = vars.Akkus[vars.AkkusID[vars.Akku2ID]].Capacity
			cell_count = vars.Akkus[vars.AkkusID[vars.Akku2ID]].iCells
			drawVal.batC_sens = vars.Akkus[vars.AkkusID[vars.Akku2ID]].batC
			lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.Akku2ID]].usedCapacity
			drawVal.batID_sens = vars.Akku2ID
		elseif vars.AkkusID[vars.Akku1ID] then 
			capacity = vars.Akkus[vars.AkkusID[vars.Akku1ID]].Capacity
			cell_count = vars.Akkus[vars.AkkusID[vars.Akku1ID]].iCells
			drawVal.batC_sens = vars.Akkus[vars.AkkusID[vars.Akku1ID]].batC
			lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.Akku1ID]].usedCapacity
			drawVal.batID_sens = vars.Akku1ID
		end
	end
	if capacity > 0 then  dbdis_capacity = capacity end
			
	
	-- Read Sensor Parameter Voltage 
	sensor = system.getSensorValueByID(vars.battery_voltage_sens[1], vars.battery_voltage_sens[2])
	if(sensor and sensor.valid ) then
		battery_voltage = sensor.value
	-- guess used capacity from voltage if we started with partially discharged battery 
		if (vars.initial_voltage_measured == false) then
			if ( battery_voltage / cell_count) > 1.1  then
				vars.initial_voltage_measured = true
				vars.initial_cell_voltage = battery_voltage / cell_count
				vars.initial_capacity_percent_used = get_capacity_percent_used()
				if vars.initial_cell_voltage <= AkkuFull and lastUsedCapacity > 0 then 
					vars.oldAkku = 1 
				else
					vars.oldAkku = 0
				end
			end    
		end        
		
		-- calculate Min/Max Sensor 1
		if ( battery_voltage < vars.minvtg and (battery_voltage / cell_count) > 1.1 ) then vars.minvtg = battery_voltage end
		if battery_voltage > vars.maxvtg then vars.maxvtg = battery_voltage end
		
		if newTime >= (last_averaging_time + 1000) then          -- one second period, newTime set from FlightTime()
			battery_voltage_average = average(battery_voltage)   -- average voltages over n samples
			last_averaging_time = newTime
		end
		
		if ((battery_voltage_average / cell_count) <= voltage_alarm_dec_thresh and vars.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime and iVoltageAlarm < imaxAlarm ) then
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
		vars.initial_voltage_measured = true
		if vars.battery_voltage_sens[2] ~= 0 then 
			battery_voltage_average = 0
			vars.initial_voltage_measured = false
		end
	end
	
	
	
	-- Read remaining fuel percent
	sensor = system.getSensorValueByID(vars.remaining_fuel_percent_sens[1], vars.remaining_fuel_percent_sens[2])
	if(sensor and sensor.valid) then
		remaining_fuel_percent = sensor.value
	else
		if vars.remaining_fuel_percent_sens[2] ~= 0 then 
			remaining_fuel_percent = 0 
		else
			if Calca_dispGas then 
				remaining_fuel_percent = Calca_dispGas
				vars.tank_volume = Calca_selTank
				vars.capacity_alarm_thresh = Calca_sgBingo
			else remaining_fuel_percent = -1 
			end
		end
	end
	                    
	-- Read Sensor Parameter Used Capacity
	sensor = system.getSensorValueByID(vars.used_capacity_sens[1], vars.used_capacity_sens[2])
	if(sensor and sensor.valid) then 
		used_capacity = sensor.value

		if ( vars.initial_voltage_measured == true ) then
			remaining_capacity_percent = math.floor((((capacity - used_capacity - (vars.oldAkku * lastUsedCapacity)) * 100) / capacity ) - (vars.initial_capacity_percent_used * math.abs(vars.oldAkku -1)))
			if remaining_capacity_percent < 0 then remaining_capacity_percent = 0 end
		end
                 
		-- Set max/min percentage to 99/0 for drawing
		if( remaining_capacity_percent > 100 ) then remaining_capacity_percent = 100 end
		if( remaining_capacity_percent < 0 ) then remaining_capacity_percent = 0 end
	else
		if vars.used_capacity_sens[2] ~= 0 then
			if used_capacity == -1 then used_capacity = 0 end 
		else
			if vars.used_capacity_sens[2] == 0 and Calca_dispFuel then 
					if capacity <= 1 then capacity = Calca_capacity end
					used_capacity = capacity * (1 - Calca_dispFuel / 100 )
					remaining_capacity_percent = Calca_dispFuel
					vars.capacity_alarm_thresh = Calca_sBingo 
					calcaApp = true
			else 
				used_capacity = -1 
				calcaApp = false
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
			system.playNumber(remaining_fuel_percent, 0, "%")
			next_capacity_announcement = tickTime + 10 -- say fuel percentage every 10 seconds
		elseif remaining_capacity_percent > 0 then
			system.playNumber(remaining_capacity_percent, 0, "%")
			next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
		end	
	end
	
	if anCapaValGo == 1 and tickTime >= next_value_announcement then
		if remaining_fuel_percent > 0  then
			system.playNumber(remaining_fuel_percent * vars.tank_volume / 100, 0, "ml")
			next_value_announcement = tickTime + 10 -- say fuel value every 10 seconds
		elseif remaining_capacity_percent > 0 then
			system.playNumber(remaining_capacity_percent * capacity / 100, 0, "mAh")
			next_value_announcement = tickTime + 10 -- say battery value every 10 seconds
		end	
	end
	

	for i, sens in ipairs(MinMaxlbl) do
		sensor = system.getSensorValueByID(vars[sens][1], vars[sens][2])
		if (sensor and sensor.valid) then
			drawVal[sens] = sensor.value
			if vars.drawVal[sens].measured == false then
				if  drawVal[sens] > 1 then 
					vars.drawVal[sens].measured = true
					vars.drawVal[sens].min = 999.9
				end
			else
				-- calculate Min/Max Sensor
				if drawVal[sens] < vars.drawVal[sens].min then vars.drawVal[sens].min = drawVal[sens] end
				if drawVal[sens] > vars.drawVal[sens].max then vars.drawVal[sens].max = drawVal[sens] end
			end
		else
			if vars[sens][2] ~= 0 then drawVal[sens] = 0 end
		end
	end
	
	for i, sens in ipairs({"UsedCap1_sens", "UsedCap2_sens", "OverI_sens"}) do
		sensor = system.getSensorValueByID(vars[sens][1], vars[sens][2])
		if (sensor and sensor.valid) then
			drawVal[sens] = sensor.value
		else
			if vars[sens][2] ~= 0 then drawVal[sens] = 0 end
		end
	end

	
	-- Read Status1 Parameter 
	sensor = system.getSensorValueByID(vars.status_sens[1], vars.status_sens[2])
	if(sensor and sensor.valid) then
		if Global_TurbineState ~= "" then  status1 = Global_TurbineState
			else status1 = sensor.value
		end
	end
	
	-- Read Status2 Parameter 
	sensor = system.getSensorValueByID(vars.status2_sens[1], vars.status2_sens[2])
	if(sensor and sensor.valid) then
		if Global_TurbineState2 ~= "" then  status2 = Global_TurbineState2
			else status2 = sensor.value
		end
	end
	
	
	
	--print(system.getCPU())
end --loop

return {
	showDisplay = showDisplay,
	loop = loop,
	init = init,
	setvars = setvars
}
