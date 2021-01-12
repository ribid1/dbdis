local col1, col2, col3 = 0,0,0
local txtr,txtg,txtb
local maxr, maxg, maxb
local minr, ming, minb = 0,140,0
local alarmr, alarmg, alarmb = 200,0,0
local xStart
local yStart
local xMitte = 159
local xli = 1 -- x Abstand der Anzeigeboxen vom linken Rand
local lengthSep = 127
local lengthBox = 129
local xre = 190  -- xMitte - xli - lengthSep + xMitte
local yborder = 6
local ybd2 = 3
local imainAlarm, ipreAlarm = 0,0
local iVoltageAlarm = 0
local next_capacity_alarm, next_voltage_alarm = 0, 0
local next_capacity_announcement, next_value_announcement, next_voltage_announcement, tickTime = 0, 0, 0, 0
local newTime
local anCapaGo
local anCapaValGo
local anVoltGo
local timeSw_val
local resetSw_val
local engineSw_val
local engineOffSw_val
local sensor
local txtelemetry
local newbatID = 0
--local reset = false
local gyro_channel_value = 17
local calcaApp = false
local minvperc = 0
local last_averaging_time = 0
local vars = {}
local voltages_list = {}
local drawfunc = {}
local calcfunc = {}
local Minlbl = {}
local Maxlbl = {}
local MinMaxlbl = {}
local Valuelbl = {}
local RxTypen = {"rx1", "rx2", "rxB"}
local deci

-- 28 Sensoren + 2 Variable
Maxlbl = {["motor_current_sens"] = true, ["bec_current_sens"] = true, ["pwm_percent_sens"] = true, ["fet_temp_sens"] = true, ["throttle_sens"] = true, ["I1_sens"] = true, ["I2_sens"] = true, ["Temp_sens"] = true,["Temp2_sens"] = true, ["rotor_rpm_sens"] = true, ["altitude_sens"] = true, ["speed_sens"] = true, ["vibes_sens"] = true, ["pump_voltage_sens"] = true}	--14
Minlbl = {["U1_sens"] = true, ["U2_sens"] = true} --2
MinMaxlbl = {["vario_sens"] = true, ["ax_sens"] = true, ["ay_sens"] = true, ["az_sens"] = true} --4
Valuelbl = {["battery_voltage_sens"] = true, ["UsedCap1_sens"] = true, ["UsedCap2_sens"] = true, ["OverI_sens"] = true,["used_capacity_sens"] = true, ["remaining_fuel_percent_sens"] = true, ["checkedCells_sens"] = true, ["deltaVoltage_sens"] = true,["weakVoltage_sens"] = true, ["weakCell_sens"] = true} --10

local function loadColors()
	local bgr,bgg,bgb = lcd.getBgColor()
	if (bgr+bgg+bgb)/3 >128 then
		txtr,txtg,txtb = 0,0,0
		maxr, maxg, maxb = 0,0,255
	else
		txtr,txtg,txtb = 255,255,255
		maxr, maxg, maxb = 0,255,255
	end
	collectgarbage()	
end
loadColors()
 
 ---------------------------------------------------Draw functions----------------------------------------

local function drawPercent(value)
	local function drawPercentsub()
		local widebat = 50
		lcd.setColor(col1,col2,col3)
		lcd.drawRectangle(xMitte-widebat/2, 4, widebat, 22, 3)
		lcd.drawFilledRectangle(xMitte-widebat/2+1, 5, widebat-2, 20)
		lcd.setColor(txtr,txtg,txtb)
		lcd.drawRectangle(xMitte-widebat/2-2, 2, widebat+4, 26, 5)
		lcd.drawRectangle(xMitte-widebat/2-1, 3, widebat+2, 24, 4)
		lcd.drawText(xMitte - (lcd.getTextWidth(FONT_BIG, string.format("%.f%%",value)) / 2),4, string.format("%.f%%",
				value),FONT_BIG)
	end
	
	if value <= vars.config.capacity_alarm_thresh then
		if system.getTime() % 2 == 0 then
			col1=250 col2 = 0 col3=0--rot
			drawPercentsub()
		end
	elseif value <= vars.config.capacity_alarm_thresh2 then 
		if system.getTime() % 4 ~= 0 then
			col1=250 col2 = 250 col3=0 -- gelb
			drawPercentsub()
		end
	else
		col1=0 col2 = 220 col3=0 --grün
		drawPercentsub()
	end
end

-- Draw Battery and percentage display
local function drawBattery(xMidBat,widebat)
	if vars.senslbl.used_capacity_sens or calcaApp then --vars.Value.used_capacity_sens > -1 then
		if vars.capacity > 0 then
			vars.remaining_capacity_percent = (vars.capacity - vars.Value.used_capacity_sens + vars.resetusedcapacity - vars.lastUsedCapacity) * 100 / vars.capacity - vars.initial_capacity_percent_used     --math.floor  
		end
		if( vars.remaining_capacity_percent > 100 ) then vars.remaining_capacity_percent = 100 end
		if( vars.remaining_capacity_percent < 0 ) then vars.remaining_capacity_percent = 0 end
		local temp
		local topbat = 40   -- original = 48
		local highbat = 107  -- original = 80
		local widebat = 50
		local xMidBat = xMitte
		local xLeftBat = xMidBat-widebat/2

		
		-- Battery
		lcd.drawFilledRectangle(xLeftBat+widebat*0.2, topbat-7, widebat*0.6, 7)	-- top of Battery
		lcd.drawRectangle(xLeftBat-2, topbat-2, widebat+4, highbat+4)
		lcd.drawRectangle(xLeftBat-1, topbat-1, widebat+2, highbat+2)

		-- Level of Battery
		local chgH = vars.remaining_capacity_percent * highbat // 100
		local chgY = highbat + topbat - chgH
		local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
		local Halarm = chgHalarm
		local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
		chgHalarm = math.min(chgH,chgHalarm)
		chgHalarm2 = math.min(chgH,chgHalarm2)
		local chgYalarm = highbat + topbat - chgHalarm
		local chgYalarm2 = highbat + topbat - chgHalarm2
		
		  
		lcd.setColor(0,220,0)
		lcd.drawFilledRectangle(xLeftBat, chgY, widebat, chgH) --grün
		lcd.setColor(250,250,0)
		lcd.drawFilledRectangle(xLeftBat, chgYalarm2, widebat, chgHalarm2) --gelb
		lcd.setColor(250,0,0)
		lcd.drawFilledRectangle(xLeftBat, chgYalarm, widebat, chgHalarm) --rot
		lcd.setColor(txtr,txtg,txtb)
		
		-- Text in battery
		local drawcapacity = vars.capacity
		if vars.AkkusID[vars.batID] then
			if drawcapacity == 1 then drawcapacity = 0 end
			lcd.drawText(xMitte-(lcd.getTextWidth(FONT_BIG, string.format("%.f",drawcapacity)) / 2),40, string.format("%.f", drawcapacity),FONT_BIG)
			lcd.drawText(xMitte-12, 60, "mAh", FONT_MINI)
			--s and C-Rate
			temp = string.format("%.f",vars.cell_count).."S"
			if vars.batC > 0 then temp = temp.." / "..string.format("%.f",vars.batC).."C" end
			if gyro_channel_value == 17 then 
				lcd.drawText(xMitte-(lcd.getTextWidth(FONT_MINI, temp) / 2),xMitte-11, temp,FONT_MINI)
			else
				lcd.setColor(0,0,200)
				lcd.drawText(xMitte-(lcd.getTextWidth(FONT_MINI,temp) / 2),xMitte-25,temp,FONT_MINI)
				lcd.setColor(txtr,txtg,txtb)
			end
			
			-- ID, Name
			lcd.drawText(xMidBat-1-(lcd.getTextWidth(FONT_NORMAL, string.format("%.f",vars.batID)) / 2),81, string.format("%.f", vars.batID),FONT_NORMAL)
			lcd.setColor(0,0,200)
			lcd.drawText(xMitte-(lcd.getTextWidth(FONT_MINI, string.format("%s",vars.Akkus[vars.AkkusID[vars.batID]].Name)) / 2),136-Halarm, string.format("%s", vars.Akkus[vars.AkkusID[vars.batID]].Name),FONT_MINI)
			lcd.setColor(txtr,txtg,txtb)
		end
		
		if vars.RfID > 0 then
			lcd.drawCircle(xMidBat-1,91,11)
			lcd.drawCircle(xMidBat-1,91,12)
		end
			
		drawPercent(vars.remaining_capacity_percent)
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
		lcd.drawText(xMitte-20,149,"GY = ",FONT_MINI)
		-- draw Max Values
		lcd.drawText(xMitte+18 - lcd.getTextWidth(FONT_MINI, string.format("%.0f", gyro_percent)), 149, string.format("%.0f", gyro_percent), FONT_MINI)
	end

	collectgarbage()
end

-- Draw Battery and percentage display
local function draw2Battery(xMidBat,widebat,batID)
	if vars.senslbl.used_capacity_sens or calcaApp then --vars.Value.used_capacity_sens > -1 then
		if vars.capacity > 0 then
			vars.remaining_capacity_percent = (vars.capacity - vars.Value.used_capacity_sens + vars.resetusedcapacity - vars.lastUsedCapacity) * 100 / vars.capacity - vars.initial_capacity_percent_used     --math.floor  
		end
		if( vars.remaining_capacity_percent > 100 ) then vars.remaining_capacity_percent = 100 end
		if( vars.remaining_capacity_percent < 0 ) then vars.remaining_capacity_percent = 0 end
		local temp
		local topbat = 40   -- original = 48
		local highbat = 117  -- original = 80
		local xLeftBat = xMidBat-widebat/2
		
		-- Battery
		lcd.drawFilledRectangle(xLeftBat+widebat*0.2, topbat-7, widebat*0.6, 7)	-- top of Battery
		lcd.drawRectangle(xLeftBat-2, topbat-2, widebat+4, highbat+4)
		lcd.drawRectangle(xLeftBat-1, topbat-1, widebat+2, highbat+2)

		-- Level of Battery
		local chgH = vars.remaining_capacity_percent * highbat // 100
		local chgY = highbat + topbat - chgH
		local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
		local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
		if chgH < chgHalarm then chgHalarm = chgH end
		if chgH < chgHalarm2 then chgHalarm2 = chgH end
		local chgYalarm = highbat + topbat - chgHalarm
		local chgYalarm2 = highbat + topbat - chgHalarm2
		
		  
		lcd.setColor(0,220,0)
		lcd.drawFilledRectangle(xLeftBat, chgY, widebat, chgH) --grün
		lcd.setColor(250,250,0)
		lcd.drawFilledRectangle(xLeftBat, chgYalarm2, widebat, chgHalarm2) --gelb
		lcd.setColor(250,0,0)
		lcd.drawFilledRectangle(xLeftBat, chgYalarm, widebat, chgHalarm) --rot
		lcd.setColor(txtr,txtg,txtb)
		
		-- Text in battery
		local drawcapacity
		if vars.AkkusID[batID] then
			drawcapacity = vars.Akkus[vars.AkkusID[batID]].Capacity/1000
			lcd.drawText(xMidBat-(lcd.getTextWidth(FONT_BOLD, string.format("%.1f",drawcapacity)) / 2),42, string.format("%.1f", drawcapacity),FONT_BOLD)
			lcd.drawText(xMidBat-8, 60, "Ah", FONT_MINI)
			--s
			temp = string.format("%.f",vars.Akkus[vars.AkkusID[batID]].iCells).."S"
			lcd.drawText(xMidBat-(lcd.getTextWidth(FONT_MINI, temp) / 2),143, temp,FONT_MINI)
			-- ID, Name
			lcd.drawText(xMidBat-1-(lcd.getTextWidth(FONT_NORMAL, string.format("%.f",batID)) / 2),81, string.format("%.f", batID),FONT_NORMAL)
		end
		
		if vars.RfID > 0 then
			lcd.drawCircle(xMidBat-1,91,11)
			lcd.drawCircle(xMidBat-1,91,12)
		end
			
		local function drawPercentsub()
			lcd.setColor(col1,col2,col3)
			lcd.drawRectangle(xLeftBat, 4, widebat, 23, 3)
			lcd.drawFilledRectangle(xLeftBat+1, 5, widebat-2, 21)
			lcd.setColor(txtr,txtg,txtb)
			lcd.drawRectangle(xLeftBat-2, 2, widebat+4, 27, 5)
			lcd.drawRectangle(xLeftBat-1, 3, widebat+2, 25, 4)
			lcd.drawText(xMidBat-1 - (lcd.getTextWidth(FONT_BOLD, string.format("%.f",vars.remaining_capacity_percent)) / 2),2, string.format("%.f",
					vars.remaining_capacity_percent),FONT_BOLD)
			lcd.drawText(xMidBat-5, 16,"%",FONT_MINI)		
		end
	
		if vars.remaining_capacity_percent <= vars.config.capacity_alarm_thresh then
			if system.getTime() % 2 == 0 then
				col1=250 col2 = 0 col3=0--rot
				drawPercentsub()
			end
		elseif vars.remaining_capacity_percent <= vars.config.capacity_alarm_thresh2 then 
			if system.getTime() % 4 ~= 0 then
				col1=250 col2 = 250 col3=0 -- gelb
				drawPercentsub()
			end
		else
			col1=0 col2 = 220 col3=0 --grün
			drawPercentsub()
		end
	end 
	collectgarbage()
end

-- Draw tank and percentage display
local function drawTank()
	if vars.senslbl.remaining_fuel_percent_sens or Calca_dispGas then--vars.Value.remaining_fuel_percent_sens >= 0 then 
		local topbat = 34   -- original = 48
		local highbat = 122  -- original = 80
		local widebat = 26
		local midbat = xMitte-10
		local ox = xMitte-40
		local oy = 60
		local left = xMitte+8
		local i
		local strTank_volume = tostring(math.floor(vars.config.tank_volume))

		lcd.setColor(0,220,0)
		lcd.drawText(52+ox,-22+oy, "F", FONT_BOLD)  
		lcd.setColor(250,0,0)
		lcd.drawText(52+ox,72+oy, "E", FONT_BOLD) 
		lcd.setColor(txtr,txtg,txtb)

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
		local chgH = vars.Value.remaining_fuel_percent_sens * highbat // 100
		local chgY = highbat + topbat - chgH
		local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
		local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
		if chgH < chgHalarm then chgHalarm = chgH end
		if chgH < chgHalarm2 then chgHalarm2 = chgH end
		local chgYalarm = highbat + topbat - chgHalarm
		local chgYalarm2 = highbat + topbat - chgHalarm2
		  
		lcd.setColor(0,220,0)
		lcd.drawFilledRectangle(midbat-widebat/2, chgY, widebat, chgH) --grün
		lcd.setColor(250,250,0)
		lcd.drawFilledRectangle(midbat-widebat/2, chgYalarm2, widebat, chgHalarm2) --gelb
		lcd.setColor(250,0,0)
		lcd.drawFilledRectangle(midbat-widebat/2, chgYalarm, widebat, chgHalarm) --rot
		lcd.setColor(txtr,txtg,txtb)

		 -- Text in Tank

		for i = 1, #strTank_volume do
			lcd.drawText(xMitte-14,22 + i * 15, string.sub(strTank_volume, i,i),FONT_NORMAL)
		end
		lcd.drawText(xMitte-19, 38 + #strTank_volume * 15, "ml", FONT_NORMAL)

		
		drawPercent(vars.Value.remaining_fuel_percent_sens)
	end
  
 	collectgarbage()
end

-- Draw Total time box
function drawfunc.TotalCount() --Total flight Time
	local std, min, sec, y
	if vars.config.timeToCount > 0 then
		y = yStart - 2
		-- draw fixed Text
		lcd.drawText(xStart, y, vars.trans.ftime, FONT_MINI)
		
		-- draw Values
		lcd.drawText(xStart + 37,y, string.format("%.f", vars.totalCount), FONT_MINI) -- Anzahl Flüge gesamt
		
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
	std = vars.flightTime // 3600000
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
	std = vars.engineTime // 3600000
	min = (vars.engineTime % 3600000) / 60000
	sec = (vars.engineTime % 60000) / 1000	
	if std ~= 0 then
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_NORMAL) -- engine time
	else
		lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_NORMAL, string.format("%02d' %02d\"", min, sec)), y, string.format("%02d' %02d\"", min, sec), FONT_NORMAL) -- engine time
	end
end

-- Draw engine ready box
function drawfunc.EngineOff()	-- engine Ready
	local engineText
	if engineOffSw_val == 1 then 
		engineText = vars.trans.engineOff
	else	
		engineText = vars.trans.engineOn
		lcd.setColor(255,0,0)
		lcd.drawRectangle(xStart-1, yStart+1 - ybd2, lengthBox-2, 10 + yborder, 3)
		lcd.drawFilledRectangle(xStart, yStart-1, lengthBox-4, 8+yborder)
		lcd.setColor(txtr,txtg,txtb)
	end
	lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, engineText)/2,yStart - 4, engineText,FONT_BOLD)
end

-- Draw Receiver values
local function drawRxValues(RxTyp)	-- Rx Values
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
    if draw_minRx_voltage < 4.6 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
    lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",draw_minRx_voltage)),y - 2, string.format("%.1f",draw_minRx_voltage),FONT_BOLD)
    lcd.setColor(txtr,txtg,txtb)
    if vars.Rx[RxTyp].voltage < 4.6 then lcd.setColor(alarmr, alarmg, alarmb) end
    lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BOLD, string.format("%.1f",vars.Rx[RxTyp].voltage)), y + 15, string.format("%.1f",vars.Rx[RxTyp].voltage),FONT_BOLD)
    lcd.setColor(txtr,txtg,txtb)
    
    -- Empfangsqualität:
    if draw_minRx_percent < 100 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%.0f/",draw_minRx_percent)),y, string.format("%.0f/",draw_minRx_percent),FONT_MINI) --Rx_percent
    lcd.setColor(txtr,txtg,txtb)
    lcd.drawText(xStart + x2, y, string.format("%.0f",vars.Rx[RxTyp].percent),FONT_MINI)
    if draw_minRx_a1 < 7 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minRx_a1)),y + linedist, string.format("%d/",draw_minRx_a1),FONT_MINI)--xStart=98-
    lcd.setColor(txtr,txtg,txtb)
    lcd.drawText(xStart + x2, y + linedist, string.format("%d",vars.Rx[RxTyp].a1),FONT_MINI)
    if draw_minRx_a2 < 7 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
    lcd.drawText(xStart + x2 - lcd.getTextWidth(FONT_MINI, string.format("%d/",draw_minRx_a2)),y + linedist * 2, string.format("%d/",draw_minRx_a2),FONT_MINI)
    lcd.setColor(txtr,txtg,txtb)
    lcd.drawText(xStart + x2, y + linedist*2, string.format("%d",vars.Rx[RxTyp].a2),FONT_MINI)
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
	--minvperc = 0
	local battery_voltage_average_perc = vars.battery_voltage_average / vars.cell_count
	--if vars.minvtg == 99.9 then minvperc = 0 else 
	minvperc = vars.drawVal.battery_voltage_sens.min/vars.cell_count
	--end
	if minvperc >= 10.0 then deci = "%.1f" end
	if minvperc <= vars.config.voltage_alarm_thresh / 100 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
	lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BIG, string.format(deci, minvperc)),y + 10, string.format(deci, minvperc), FONT_BIG)
	lcd.setColor(txtr,txtg,txtb)
	deci = "%.2f"
	if battery_voltage_average_perc >= 10.0 then deci = "%.1f" end
	if battery_voltage_average_perc <= vars.config.voltage_alarm_thresh / 100 then lcd.setColor(alarmr, alarmg, alarmb) end
	lcd.drawText(xStart + 119 - lcd.getTextWidth(FONT_BIG, string.format(deci, battery_voltage_average_perc)),y + 10, string.format(deci, battery_voltage_average_perc), FONT_BIG)
	lcd.setColor(txtr,txtg,txtb)
end
--- Used Capacity
function drawfunc.UsedCapacity()	-- Used Capacity
	local y = yStart - 2
	local total_used_capacity =  vars.Value.used_capacity_sens - vars.resetusedcapacity + vars.lastUsedCapacity + (vars.initial_capacity_percent_used * vars.capacity) / 100  --math.ceil
	
	if col1 > 0 then 
		lcd.setColor(col1,col2,col3)
		lcd.drawRectangle(xStart-1, yStart+1 - ybd2, lengthBox-2, 33 + yborder, 3)
		lcd.drawFilledRectangle(xStart, yStart-1, lengthBox-4, 31+yborder)
		lcd.setColor(txtr,txtg,txtb)
	end
	-- draw fixed Text
	lcd.drawText(xStart + 60 - (lcd.getTextWidth(FONT_MINI,vars.trans.usedCapa) / 2),y,vars.trans.usedCapa,FONT_MINI)
	lcd.drawText(xStart + 96, y + 20, "mAh", FONT_MINI)

	-- draw Values
	lcd.drawText(xStart + 94 - lcd.getTextWidth(FONT_MAXI, string.format("%.f",total_used_capacity)),y + 5, string.format("%.f", total_used_capacity), FONT_MAXI)
end

-- Draw Status
function drawfunc.Status()	-- Status
	local pat = "%s"
	if Global_TurbineState and  Global_TurbineState ~= "" then  
		vars.Value.status_sens = Global_TurbineState 
	elseif vars.Value.status_sens == 0 then 
		local sensor = system.getSensorValueByID(vars.senslbl.status_sens[1], vars.senslbl.status_sens[2])
		if not sensor.valid then vars.Value.status_sens = "No Status" end
	end
	if tonumber(vars.Value.status_sens) then 
		pat = "%.f" 
	end
	lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, string.format(pat,vars.Value.status_sens))/2,yStart - 4, string.format(pat,vars.Value.status_sens),FONT_BOLD)	
end

-- Draw Status2
function drawfunc.Status2()	-- Status
	local pat = "%s"
	if Global_TurbineState2 and Global_TurbineState2 ~= "" then  
		vars.Value.status2_sens = Global_TurbineState2 
	elseif vars.Value.status2_sens == 0  then 
		local sensor = system.getSensorValueByID(vars.senslbl.status2_sens[1], vars.senslbl.status2_sens[2])
		if not sensor.valid then vars.Value.status2_sens = "No Status" end
	end
	if tonumber(vars.Value.status2_sens) then 
		pat = "%.f"
	end
	lcd.drawText(xStart + lengthSep/2 - lcd.getTextWidth(FONT_BOLD, string.format(pat,vars.Value.status2_sens))/2,yStart - 4, string.format(pat,vars.Value.status2_sens),FONT_BOLD)	
end

-- Draw Pump voltage
function drawfunc.Pump_voltage()	-- Pump voltage
	local y = yStart - 3
		
	-- draw fixed Text
	lcd.drawText(xStart, y + 5, "U Pump:", FONT_MINI)
	lcd.drawText(xStart + 80, y + 8,"V",FONT_MINI)
	lcd.drawText(xStart + 98, y, "max:", FONT_MINI)

	-- draw Values  
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",vars.Value.pump_voltage_sens)),y, string.format("%.1f",vars.Value.pump_voltage_sens),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.1fV",vars.drawVal.pump_voltage_sens.max)) / 2,y + 10, string.format("%.1fV",vars.drawVal.pump_voltage_sens.max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)		
end

-- Draw Rotor speed box
function drawfunc.RPM()	-- Rotor Speed RPM
	local y = yStart - 9
	lcd.drawText(xStart + 112, y + 12, "-1", FONT_MINI)
	lcd.drawText(xStart + 100, y + 21, "min", FONT_MINI)
	lcd.drawText(xStart + 00, y + 35, "Max:", FONT_MINI)

	-- draw Values
	lcd.drawText(xStart + 97 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",vars.Value.rotor_rpm_sens)),y,string.format("%.0f",vars.Value.rotor_rpm_sens),FONT_MAXI)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 95 - lcd.getTextWidth(FONT_MINI,string.format("%.0f",vars.drawVal.rotor_rpm_sens.max)),y + 35, string.format("%.0f", vars.drawVal.rotor_rpm_sens.max), FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)	
end

-- Draw current box
function drawfunc.Current() -- current
	local y = yStart - 4
	-- draw fixed Text
	lcd.drawText(xStart, y, "I", FONT_BIG)
	lcd.drawText(xStart + 7, y + 8, "Motor:", FONT_MINI)
	lcd.drawText(xStart + 86, y + 8, "A", FONT_MINI)
	lcd.drawText(xStart + 96, y, "max:", FONT_MINI)
	-- draw current 
	local deci = "%.1f"
	if vars.Value.motor_current_sens >= 100 then deci = "%.f" end
	lcd.drawText(xStart + 85 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value.motor_current_sens)),y, string.format(deci,vars.Value.motor_current_sens),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.fA",vars.drawVal.motor_current_sens.max)) / 2,y + 10, string.format("%.fA",vars.drawVal.motor_current_sens.max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

-- Draw 
local function draw_smal_max(label, einheit, val, max)	
	-- draw fixed Text
	lcd.drawText(xStart,yStart+1, label, FONT_MINI)
	lcd.drawText(xStart + 80,yStart+4,einheit,FONT_MINI)
	lcd.drawText(xStart + 96,yStart-4, "max:", FONT_MINI)
	-- draw Values  
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.f",val)),yStart-4, string.format("%.f",val),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	deci = "%.f"..einheit
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format(deci,max)) / 2,yStart+6, string.format(deci,max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.Temp()	-- Temperature
	draw_smal_max(vars.trans.label_Temp, "°C", vars.Value.Temp_sens, vars.drawVal.Temp_sens.max)
end

function drawfunc.Temp_2()  -- Temperature 2
	draw_smal_max(vars.trans.label_Temp_2, "°C", vars.Value.Temp2_sens, vars.drawVal.Temp2_sens.max)
end

function drawfunc.FET_Temp()  -- FET-Temperature
	draw_smal_max(vars.trans.label_fet_Temp, "°C", vars.Value.fet_temp_sens, vars.drawVal.fet_temp_sens.max)
end

function drawfunc.I_BEC()	-- Ibec
	draw_smal_max("IBEC:", "A", vars.Value.bec_current_sens, vars.drawVal.bec_current_sens.max)
end

local function draw_smal_percent(label, val, max)
	-- draw fixed Text
	lcd.drawText(xStart,yStart+1, label, FONT_MINI)
	lcd.drawText(xStart + 80,yStart+4,"%",FONT_MINI)
	lcd.drawText(xStart + 96,yStart-4, "max:", FONT_MINI)
	-- draw Values  
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.f",val)),yStart-4, string.format("%.f",val),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.f%%",max)) / 2,yStart+6, string.format("%.f%%",max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.PWM()	-- PWM
	draw_smal_percent("PWM:", vars.Value.pwm_percent_sens, vars.drawVal.pwm_percent_sens.max)
end

function drawfunc.Throttle()	-- Throttle
	draw_smal_percent("Throttle:", vars.Value.throttle_sens, vars.drawVal.throttle_sens.max)
end

function drawfunc.Vibes() -- Vibes
	draw_smal_percent(vars.trans.vibes_sens, vars.Value.vibes_sens, vars.drawVal.vibes_sens.max)
end

	-- -- draw fixed Text
	-- lcd.drawText(xStart,yStart+1, vars.trans.label_Temp, FONT_MINI)
	-- lcd.drawText(xStart + 80,yStart+4,"°C",FONT_MINI)
	-- lcd.drawText(xStart + 96,yStart-4, "max:", FONT_MINI)
	-- -- draw Values  
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.f",vars.Value.Temp_sens)),yStart-4, string.format("%.f",vars.Value.Temp_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.f°C",vars.drawVal.Temp_sens.max)) / 2,yStart+6, string.format("%.f°C",vars.drawVal.Temp_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

-- function drawfunc.Temp_2()  -- Temperature 2
	-- -- draw fixed Text
	-- lcd.drawText(xStart,yStart+1, vars.trans.label_Temp_2, FONT_MINI)
	-- lcd.drawText(xStart + 80,yStart+4,"°C",FONT_MINI)
	-- lcd.drawText(xStart + 96,yStart-4, "max:", FONT_MINI)
	-- -- draw Values  
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.f",vars.Value.Temp2_sens)),yStart-4, string.format("%.f",vars.Value.Temp2_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.f°C",vars.drawVal.Temp2_sens.max)) / 2,yStart+6, string.format("%.f°C",vars.drawVal.Temp2_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

-- function drawfunc.FET_Temp()  -- FET-Temperature
	-- -- draw fixed Text
	-- lcd.drawText(xStart,yStart+1, vars.trans.label_fet_Temp, FONT_MINI)
	-- lcd.drawText(xStart + 80,yStart+4,"°C",FONT_MINI)
	-- lcd.drawText(xStart + 96,yStart-4, "max:", FONT_MINI)
	-- -- draw Values  
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.f",vars.Value.fet_temp_sens)),yStart-4, string.format("%.f",vars.Value.fet_temp_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.f°C",vars.drawVal.fet_temp_sens.max)) / 2,yStart+6, string.format("%.f°C",vars.drawVal.fet_temp_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)

-- end

-- Draw PWM
-- function drawfunc.PWM()	-- PWM
	-- local y = yStart - 4
	-- -- draw fixed Text
	-- lcd.drawText(xStart, y + 5, "PWM:", FONT_MINI)
	-- lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
	-- lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- -- draw Values  
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",vars.Value.pwm_percent_sens)),y, string.format("%.0f",vars.Value.pwm_percent_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",vars.drawVal.pwm_percent_sens.max)) / 2,y + 10, string.format("%.0f%%",vars.drawVal.pwm_percent_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

-- Draw Throttle
-- function drawfunc.Throttle()	-- Throttle
	-- local y = yStart - 4
	-- -- draw fixed Text
	-- lcd.drawText(xStart, y + 5, "Throttle:", FONT_MINI)
	-- lcd.drawText(xStart + 80, y + 8,"%",FONT_MINI)
	-- lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- -- draw Values  
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",vars.Value.throttle_sens)),y, string.format("%.0f",vars.Value.throttle_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0f%%",vars.drawVal.throttle_sens.max)) / 2,y + 10, string.format("%.0f%%",vars.drawVal.throttle_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

-- Draw Ibec
-- function drawfunc.I_BEC()	-- Ibec
	-- local y = yStart - 4
	-- -- draw fixed Text
	-- lcd.drawText(xStart, y + 5, "IBEC:", FONT_MINI)
	-- lcd.drawText(xStart + 80, y + 8,"A",FONT_MINI)
	-- lcd.drawText(xStart + 96, y, "max:", FONT_MINI)

	-- -- draw Values 
	-- lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format("%.0f",vars.Value.bec_current_sens)),y, string.format("%.0f",vars.Value.bec_current_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 110 - lcd.getTextWidth(FONT_MINI, string.format("%.0fA",vars.drawVal.bec_current_sens.max)) / 2,y + 10, string.format("%.0fA",vars.drawVal.bec_current_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

--Draw Altitude
function drawfunc.Altitude() -- altitude
	local y = yStart - 4
	-- draw fixed Text
	lcd.drawText(xStart, y + 6, vars.trans.altitude_sens, FONT_MINI)
	lcd.drawText(xStart + 79, y + 9, "m", FONT_MINI)
	lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
		
	-- draw altitude
	local deci = "%.1f"
	if vars.Value.altitude_sens >= 100 or vars.Value.altitude_sens <= -100 then deci = "%.0f" end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value.altitude_sens)),y + 1, string.format(deci,vars.Value.altitude_sens),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",vars.drawVal.altitude_sens.max)) / 2,y + 10, string.format("%.0f",vars.drawVal.altitude_sens.max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

--Draw Speed
function drawfunc.Speed() -- speed
	local y = yStart - 4
	-- draw fixed Text
	lcd.drawText(xStart, y + 6, vars.trans.speed_sens, FONT_MINI)
	lcd.drawText(xStart + 79, y, "km", FONT_MINI)
	lcd.drawText(xStart + 79, y + 1, "____", FONT_MINI)
	lcd.drawText(xStart + 84, y + 11, "h", FONT_MINI)
	lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
		
	-- draw speed
	local deci = "%.1f"
	if vars.Value.speed_sens >= 10 or vars.Value.speed_sens <= -10 then deci = "%.0f" end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value.speed_sens)),y + 1, string.format(deci,vars.Value.speed_sens),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",vars.drawVal.speed_sens.max)) / 2,y + 10, string.format("%.0f",vars.drawVal.speed_sens.max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

-- Draw Vario
function drawfunc.Vario() -- vario
	local y = yStart - 3
	-- draw fixed Text
	lcd.drawText(xStart, y + 6, vars.trans.vario_sens, FONT_MINI)
	lcd.drawText(xStart + 80, y, "m", FONT_MINI)
	lcd.drawText(xStart + 79, y + 1, "___", FONT_MINI)
	lcd.drawText(xStart + 82, y + 9, "s", FONT_MINI)
			
	-- draw vario 
	local deci = "%.1f"
	if vars.Value.vario_sens >= 10 or vars.Value.vario_sens <= 10 then deci = "%.f" end
	lcd.drawText(xStart + 78 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value.vario_sens)),y + 1, string.format(deci,vars.Value.vario_sens),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal.vario_sens.max)),y + 1, string.format(deci,vars.drawVal.vario_sens.max),FONT_MINI)
	lcd.setColor(minr, ming, minb)
	lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal.vario_sens.min)),y + 10, string.format(deci,vars.drawVal.vario_sens.min),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

-- Draw C1,I1 box
function drawfunc.C1_and_I1() -- C1, I1
	local y = yStart - 2
	local deci
	if vars.senslbl.UsedCap1_sens then -- > -1000 then
		-- draw C1
		lcd.drawText(xStart, y, "C", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "1:", FONT_MINI)
		lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
		deci = "%.0f"
		lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value.UsedCap1_sens)),y, string.format(deci,vars.Value.UsedCap1_sens),FONT_NORMAL)
	end
	if vars.senslbl.I1_sens then --> -1000 then
		-- draw I1
		lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
		lcd.drawText(xStart + 84, y + 5, "1:", FONT_MINI)
		deci = "%.1fA"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.Value.I1_sens)),y - 1, string.format(deci,vars.Value.I1_sens),FONT_MINI)
		lcd.setColor(maxr, maxg, maxb)
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",vars.drawVal.I1_sens.max)),y + 7, string.format("%.1fA",vars.drawVal.I1_sens.max),FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
	end
end

-- Draw C2,I2 box
function drawfunc.C2_and_I2() -- C2, I2
	local y = yStart - 2
	local deci
	if vars.senslbl.UsedCap2_sens then -- > -1000 then
		-- draw C1
		lcd.drawText(xStart, y, "C", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "2:", FONT_MINI)
		lcd.drawText(xStart + 53, y + 5, "mAh", FONT_MINI)
		deci = "%.0f"
		lcd.drawText(xStart + 53 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value.UsedCap2_sens)),y, string.format(deci,vars.Value.UsedCap2_sens),FONT_NORMAL)
	end
	if vars.senslbl.I2_sens then -- > -1000 then
		-- draw I1
		lcd.drawText(xStart + 80, y, "I", FONT_NORMAL)
		lcd.drawText(xStart + 84, y + 5, "2:", FONT_MINI)
		deci = "%.1fA"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.Value.I2_sens)),y - 1, string.format(deci,vars.Value.I2_sens),FONT_MINI)
		lcd.setColor(maxr, maxg, maxb)
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format("%.1fA",vars.drawVal.I2_sens.max)),y + 7, string.format("%.1fA",vars.drawVal.I2_sens.max),FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
	end
end

-- Draw U1, Temp box
function drawfunc.U1_and_Temp() -- U1, Temp
	local y = yStart - 1
	local deci
	--if vars.senslbl.U1_sens then --> -1000 then
		-- draw U1
		lcd.drawText(xStart, y, "U", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "1:", FONT_MINI)
		lcd.drawText(xStart + 75, y + 5, "V", FONT_MINI)
		deci = "%.1f"
		lcd.setColor(minr, ming, minb)
		lcd.drawText(xStart + 41, y + 5, "V", FONT_MINI)
		lcd.drawText(xStart + 41 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.drawVal.U1_sens.min)),y, string.format(deci,vars.drawVal.U1_sens.min),FONT_NORMAL)
		lcd.setColor(txtr,txtg,txtb)
		lcd.drawText(xStart + 49, y, "/", FONT_NORMAL)
		lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value.U1_sens)),y, string.format(deci,vars.Value.U1_sens),FONT_NORMAL)
	--end
	if vars.senslbl.fet_temp_sens then -- > -1000 then
		-- draw Temp
		lcd.drawText(xStart + 83, y, "T:", FONT_NORMAL)
		deci = "%.0f°C"
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.Value.Temp_sens)),y - 1, string.format(deci,vars.Value.Temp_sens),FONT_MINI)
		lcd.setColor(maxr, maxg, maxb)
		lcd.drawText(xStart + 123 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal.Temp_sens.max)),y + 7, string.format(deci,vars.drawVal.Temp_sens.max),FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
	end
end

-- Draw U2, OverI
function drawfunc.U2_and_OI() -- U2, OverI
	local y = yStart - 4
	local deci
	if vars.senslbl.U2_sens then-- > -1000 then
		-- draw U1
		lcd.drawText(xStart, y, "U", FONT_NORMAL)
		lcd.drawText(xStart + 9, y + 5 , "2:", FONT_MINI)
		lcd.drawText(xStart + 75, y + 5, "V", FONT_MINI)
		deci = "%.1f"
		lcd.setColor(minr, ming, minb)
		lcd.drawText(xStart + 41, y + 5, "V", FONT_MINI)
		lcd.drawText(xStart + 41 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.drawVal.U2_sens.min)),y, string.format(deci,vars.drawVal.U2_sens.min),FONT_NORMAL)
		lcd.setColor(txtr,txtg,txtb)
		lcd.drawText(xStart + 49, y, "/", FONT_NORMAL)
		lcd.drawText(xStart + 75 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value.U2_sens)),y, string.format(deci,vars.Value.U2_sens),FONT_NORMAL)
	end
	if vars.senslbl.OverI_sens then -- > -1000 then
		-- draw Temp
		lcd.drawText(xStart + 90, y, "OI:", FONT_NORMAL)
		deci = "%.0f"
		if vars.Value.OverI_sens > 0 then lcd.setColor(alarmr, alarmg, alarmb) end
		lcd.drawText(xStart + 120 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value.OverI_sens)),y, string.format(deci,vars.Value.OverI_sens),FONT_NORMAL)
		lcd.setColor(txtr,txtg,txtb)
	end
end

-- Draw U and I
local function U_and_I(i, U_sens, I_sens) 
	local y = yStart-1
	local deci
	lcd.drawText(xStart, y,string.format("%s:",i), FONT_BOLD)
	
	if vars.senslbl[U_sens] then
		local Umin
		deci = "%.1fV"
		if vars.Value[U_sens] >= 10 then deci = "%.fV" end
		lcd.drawText(xStart + 45, y-2, "min", FONT_MINI)
		lcd.setColor(minr, ming, minb)
		Umin = vars.drawVal[U_sens].min
		lcd.drawText(xStart + 65 - lcd.getTextWidth(FONT_MINI, string.format(deci,Umin)),y+7, string.format(deci,Umin),FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
		lcd.drawText(xStart + 43 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value[U_sens])),y, string.format(deci,vars.Value[U_sens]),FONT_NORMAL)
	end
	if vars.senslbl[I_sens] then
		deci = "%.1fA"
		if vars.Value[I_sens] >= 10 then deci = "%.fA" end
		lcd.drawText(xStart + 100, y-2, "max:", FONT_MINI)
		lcd.setColor(maxr, maxg, maxb)
		lcd.drawText(xStart + 124 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal[I_sens].max)),y+7, string.format(deci,vars.drawVal[I_sens].max),FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
		lcd.drawText(xStart + 100 - lcd.getTextWidth(FONT_NORMAL, string.format(deci,vars.Value[I_sens])),y, string.format(deci,vars.Value[I_sens]),FONT_NORMAL)
	end
end

function drawfunc.U1_and_I1()
	U_and_I(1, "U1_sens", "I1_sens")
end

function drawfunc.U2_and_I2()
	U_and_I(2, "U2_sens", "I2_sens")
end

-- Draw UsedCap
local function usedCap(UsedCap_sens, batID) 
	local y = yStart -2
	local lbat= 102
	local xbat = xStart+17
	
	if vars.AkkusID[batID] then	
		-- ID
		lcd.drawText(xStart+15-lcd.getTextWidth(FONT_MINI, string.format("%.f:",batID)) ,y+4, string.format("%.f:",batID),FONT_MINI)
		if vars.Akkus[vars.AkkusID[batID]].Capacity > 0 then
			local usedCapP = 100 - vars.Value[UsedCap_sens] / vars.Akkus[vars.AkkusID[batID]].Capacity * 100
			local l_usedCap = lcd.getTextWidth(FONT_BOLD, string.format("%.f%%",usedCapP))
			lbat = lbat - l_usedCap
			lcd.setColor(0,220,0)
			lcd.drawFilledRectangle(xbat+1,y+3, (lbat-2)*usedCapP/100, 14)
			lcd.setColor(txtr,txtg,txtb)
			lcd.drawText(xStart+125-l_usedCap,y,string.format("%.f%%",usedCapP),FONT_BOLD)
		end
	else
		xbat = xbat-19
		lbat = lbat+19
	end
	lcd.drawRectangle(xbat,y+2, lbat, 16)
	lcd.drawFilledRectangle(xbat+lbat,y+5, 4, 10)	-- top of Battery
	lcd.drawText(xbat + lbat/2 - (lcd.getTextWidth(FONT_MINI, string.format("%.f mAh",vars.Value[UsedCap_sens]))/2),y+4, string.format("%.f mAh",vars.Value[UsedCap_sens]),FONT_MINI)
end

function drawfunc.used_Cap1()
	usedCap("UsedCap1_sens", vars.config.Akku1ID)
end

function drawfunc.used_Cap2()
	usedCap("UsedCap2_sens", vars.config.Akku2ID)
end

function drawfunc.weakest_Cell()
	local y = yStart
	local x = xStart+20
	local checkedCells = string.format("%.f",vars.Value.checkedCells_sens)..vars.trans.of..string.format("%.f",vars.cell_count) ..vars.trans.checked
	lcd.drawText(xStart + 64 - lcd.getTextWidth(FONT_MINI, checkedCells)/2,y-2, checkedCells,FONT_MINI)
	-- delta Voltage
	if vars.senslbl.deltaVoltage_sens then
		lcd.drawLine(xStart+89,y+15,xStart+85,y+21)	
		lcd.drawLine(xStart+89,y+15,xStart+93,y+21)
		lcd.drawLine(xStart+85,y+21,xStart+93,y+21)
		lcd.drawText(xStart+96,y+8,string.format("%.1fv",vars.Value.deltaVoltage_sens),FONT_NORMAL)
		
		lcd.drawLine(xStart+89,y+29,xStart+85,y+35)	
		lcd.drawLine(xStart+89,y+29,xStart+93,y+35)
		lcd.drawLine(xStart+85,y+35,xStart+93,y+35)
		lcd.drawText(xStart+96,y+22,string.format("%.1fv",vars.drawVal.deltaVoltage_sens.min),FONT_NORMAL)
		x=xStart
	end

	if vars.drawVal.weakPack > 0 then
		x=xStart+6
		lcd.drawText(x+62,y+8,string.format("(P%.f/",vars.drawVal.weakPack)..string.format("C%.f)",vars.Value.weakCell_sens),FONT_NORMAL)
	else	
		lcd.drawText(x+59,y+8,string.format("(%.f)",vars.Value.weakCell_sens),FONT_NORMAL)
	end
	lcd.drawText(x+5, y+12, vars.trans.act, FONT_MINI)
	lcd.drawText(x+27,y+8,string.format("%.1fv",vars.Value.weakVoltage_sens),FONT_BOLD)
				
	
	lcd.setColor(minr, ming, minb)
	if vars.drawVal.weakPack > 0 then
		x=xStart+6
		lcd.drawText(x+62,y+22,string.format("(P%.f/",vars.drawVal.weakPackmin)..string.format("C%.f)",vars.drawVal.weakCell_sens.min),FONT_NORMAL)
	else	
		lcd.drawText(x+59,y+22,string.format("(%.f)",vars.drawVal.weakCell_sens.min),FONT_NORMAL)
	end
	lcd.drawText(x+27,y+22,string.format("%.1fv",vars.drawVal.weakVoltage_sens.min),FONT_BOLD)
	lcd.setColor(txtr,txtg,txtb)
	lcd.drawText(x+1, y+26, "min:", FONT_MINI)
end

function drawfunc.ax_ay_az()
	local y = yStart - 3
	for i,j in ipairs({"ax_sens", "ay_sens", "az_sens"}) do
		if vars.senslbl[j] then
			-- draw fixed Text
			lcd.drawText(xStart-42 + 42*i, y, "a  :", FONT_NORMAL)
			lcd.drawText(xStart-33 + 42*i, y+5, string.char(119+i) , FONT_MINI)
					
			-- draw vario 
			local deci = "%.1f"
			lcd.setColor(maxr, maxg, maxb)
			lcd.drawText(xStart-4 +42*i - lcd.getTextWidth(FONT_MINI, string.format("%.1f",vars.drawVal[j].max)),y + 1, string.format("%.1f",vars.drawVal[j].max),FONT_MINI)
			lcd.setColor(minr, ming, minb)
			lcd.drawText(xStart-4+42*i - lcd.getTextWidth(FONT_MINI, string.format("%.1f",vars.drawVal[j].min)),y + 10, string.format("%.1f",vars.drawVal[j].min),FONT_MINI)
			lcd.setColor(txtr,txtg,txtb)
		end
	end
end

--Draw Vibes
-- function drawfunc.Vibes() -- Vibes
	-- local y = yStart - 4
	-- -- draw fixed Text
	-- lcd.drawText(xStart, y + 6, vars.trans.vibes_sens, FONT_MINI)
	-- lcd.drawText(xStart + 98, y, "max:", FONT_MINI)
	-- -- draw vibes 
	-- local deci = "%.f%%"
	-- lcd.drawText(xStart + 90 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value.vibes_sens)),y + 1, string.format(deci,vars.Value.vibes_sens),FONT_BIG)
	-- lcd.setColor(maxr, maxg, maxb)
	-- lcd.drawText(xStart + 111 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal.vibes_sens.max)) / 2,y + 10, string.format(deci,vars.drawVal.vibes_sens.max),FONT_MINI)
	-- lcd.setColor(txtr,txtg,txtb)
-- end

local function showDisplay(page)
	local ySep, yBox
	lcd.setColor(txtr,txtg,txtb)
	--left:	
	xStart = xli + 1
	for i,j in ipairs(vars[page].leftdrawcol) do 
		yStart = j.yStart
		if j.SepO < 0 then
			ySep = vars[page].leftdrawcol[math.min(i - j.SepO - 1,#vars[page].leftdrawcol)].yStart - ybd2
			yBox = yStart + ybd2 + vars.cd[j.order].y - ySep
			if vars.configG.color[vars[page].cd[j.order].col] then
				lcd.setColor(vars.configG.color[vars[page].cd[j.order].col][1],vars.configG.color[vars[page].cd[j.order].col][2],vars.configG.color[vars[page].cd[j.order].col][3])
				lcd.drawRectangle(xli, ySep+1, lengthBox-2, yBox-2, 3)
				lcd.drawFilledRectangle(xStart, ySep+2, lengthBox-4, yBox-4)
				lcd.setColor(txtr,txtg,txtb)
			end
			lcd.drawRectangle(xli-1, ySep, lengthBox, yBox, 4)
		else
			if j.Sep > 0 then 
				lcd.drawFilledRectangle(xli, yStart + vars.cd[j.order].y + j.ydist, lengthSep, vars[page].cd[j.order].sep)
			end	
		end
		drawfunc[j.order]()
	end
	
	-- for i,j in ipairs(vars[page].leftdrawcol) do 
		-- yStart = vars[page].cd[j].yStart
		-- if vars[page].cd[j].sep < 0 then
			-- local ySBox = yStart - vars[page].cd[j].yBox + ybd2 + vars.cd[j].y
			-- if vars.configG.color[vars[page].cd[j].col] then
				-- lcd.setColor(vars.configG.color[vars[page].cd[j].col][1],vars.configG.color[vars[page].cd[j].col][2],vars.configG.color[vars[page].cd[j].col][3])
				-- lcd.drawRectangle(xli, ySBox+1, lengthBox-2, vars[page].cd[j].yBox-2, 3)
				-- lcd.drawFilledRectangle(xStart, ySBox+2, lengthBox-4, vars[page].cd[j].yBox-4)
				-- lcd.setColor(txtr,txtg,txtb)
			-- end
			-- lcd.drawRectangle(xli-1, ySBox, lengthBox, vars[page].cd[j].yBox, 4)
		-- else
			-- if vars[page].cd[j].sepdraw > 0 then 
				-- lcd.drawFilledRectangle(xli, (vars[page].cd[vars[page].leftdrawcol[i-1]].yStart + yStart - vars[page].cd[j].sepdraw + vars.cd[j].y)/2 , lengthSep, vars[page].cd[j].sep)
			-- end	
		-- end
		-- drawfunc[j]()
	-- end
	
--------------	
	--right
	xStart = xre + 1
	for i,j in ipairs(vars[page].rightdrawcol) do 
		yStart = j.yStart
		if j.SepO < 0 then
			ySep = vars[page].rightdrawcol[math.min(i - j.SepO - 1,#vars[page].rightdrawcol)].yStart - ybd2
			yBox = yStart + ybd2 + vars.cd[j.order].y - ySep
			if vars.configG.color[vars[page].cd[j.order].col] then
				lcd.setColor(vars.configG.color[vars[page].cd[j.order].col][1],vars.configG.color[vars[page].cd[j.order].col][2],vars.configG.color[vars[page].cd[j.order].col][3])
				lcd.drawRectangle(xre, ySep+1, lengthBox-2, yBox-2, 3)
				lcd.drawFilledRectangle(xStart, ySep+2, lengthBox-4, yBox-4)
				lcd.setColor(txtr,txtg,txtb)
			end
			lcd.drawRectangle(xre-1, ySep, lengthBox, yBox, 4)
		else
			if j.Sep > 0 then 
				lcd.drawFilledRectangle(xre, yStart + vars.cd[j.order].y + j.ydist, lengthSep, vars[page].cd[j.order].sep)
			end	
		end
		drawfunc[j.order]()
	end
	
	-- for i,j in ipairs(vars[page].rightdrawcol) do 
		-- if vars[page].cd[j].sep < 0 then
			-- yStart = yStart - vars.cd[j].y - yborder/2 - vars[page].cd[j].distdraw
			-- local y = yborder
			-- local sep = -1
			-- for k = i+1,math.min(i-1-vars[page].cd[j].sep,#vars[page].rightdrawcol) do
				-- local box = vars[page].rightdrawcol[k]
				-- y = y + vars.cd[box].y + vars[page].cd[box].distdraw 
				-- sep = vars[page].cd[box].sep
				-- if  sep < 0 then 
					-- y = y + yborder
				-- elseif sep > 0 then
					-- y = y + sep + vars[page].cd[box].distdraw
				-- end
			-- end	
			-- if sep > -1 then y = y + yborder/2 end
			-- if vars.configG.color[vars[page].cd[j].col] then
				-- lcd.setColor(vars.configG.color[vars[page].cd[j].col][1],vars.configG.color[vars[page].cd[j].col][2],vars.configG.color[vars[page].cd[j].col][3])
				-- lcd.drawRectangle(xre, yStart+1-y+yborder/2, lengthBox-2, y-2 + vars.cd[j].y, 3)
				-- lcd.drawFilledRectangle(xStart, yStart+2-y+yborder/2, lengthBox-4, y-4 + vars.cd[j].y)
				-- lcd.setColor(txtr,txtg,txtb)
			-- end
			-- lcd.drawRectangle(xre-1, yStart - y+yborder/2, lengthBox, y + vars.cd[j].y, 4)
			-- drawfunc[j]()
			-- if vars[page].cd[j].sep < 0 then yStart = yStart-yborder/2 end
		-- else
			-- if vars[page].cd[j].sepdraw > 0 then 
				-- yStart = yStart - vars[page].cd[j].sep - vars[page].cd[j].distdraw
				-- lcd.drawFilledRectangle(xre, yStart , lengthSep, vars[page].cd[j].sep)
			-- end	
			-- yStart = yStart - vars.cd[j].y - vars[page].cd[j].distdraw
			-- drawfunc[j]()
		-- end
	-- end

	-- middle
	drawBattery()
	--draw2Battery(xMitte-13,25,vars.config.Akku1ID)
	--draw2Battery(xMitte+14,25,vars.config.Akku2ID)
	drawTank()

	collectgarbage()
end

local function oldshowDisplay(page)	
	lcd.setColor(txtr,txtg,txtb)
	--left:	
	yStart = 159
	xStart = xli + 1
	for i,j in ipairs(vars[page].leftdrawcol) do 
		if vars[page].cd[j].sep < 0 then
			yStart = yStart - vars.cd[j].y - yborder/2 - vars[page].cd[j].distdraw
			local y = yborder
			local sep = -1
			for k = i+1,math.min(i-1-vars[page].cd[j].sep,#vars[page].leftdrawcol) do
				local box = vars[page].leftdrawcol[k]
				y = y + vars.cd[box].y + vars[page].cd[box].distdraw 
				sep = vars[page].cd[box].sep
				if  sep < 0 then 
					y = y + yborder
				elseif sep > 0 then
					y = y + sep + vars[page].cd[box].distdraw
				end
			end	
			if sep > -1 then y = y + yborder/2 end
			if vars.configG.color[vars[page].cd[j].col] then
				lcd.setColor(vars.configG.color[vars[page].cd[j].col][1],vars.configG.color[vars[page].cd[j].col][2],vars.configG.color[vars[page].cd[j].col][3])
				lcd.drawRectangle(xli, yStart+1-y+yborder/2, lengthBox-2, y-2 + vars.cd[j].y, 3)
				lcd.drawFilledRectangle(xStart, yStart+2-y+yborder/2, lengthBox-4, y-4 + vars.cd[j].y)
				lcd.setColor(txtr,txtg,txtb)
			end
			lcd.drawRectangle(xli-1, yStart - y+yborder/2, lengthBox, y + vars.cd[j].y, 4)
			drawfunc[j]()
			if vars[page].cd[j].sep < 0 then yStart = yStart-yborder/2 end
		else
			-- if vars.drawVal[j].valid then 
				-- drawfunc[j]()
			-- elseif tickTime % 2 == 0 then 
				-- drawfunc[j]() 
			-- end
			if vars[page].cd[j].sepdraw > 0 then 
				yStart = yStart - vars[page].cd[j].sep - vars[page].cd[j].distdraw
				lcd.drawFilledRectangle(xli, yStart , lengthSep, vars[page].cd[j].sep)
				
			end	
			yStart = yStart - vars.cd[j].y - vars[page].cd[j].distdraw
			drawfunc[j]()
		end
	end
	
	
	-- boxes from top to down:
	
	-- for i,j in ipairs(vars[page].leftdrawcol) do 
		-- if vars[page].cd[j].sep < 0 then
			-- yStart = yStart + yborder / 2
			-- local y = yborder
			-- local sep = -1
			-- for k = i-1,math.max(i+1+vars[page].cd[j].sep,1),-1 do
				-- local box = vars[page].leftdrawcol[k]
				-- y = y + vars.cd[box].y + vars[page].cd[box].distdraw 
				-- sep = vars[page].cd[box].sep
				-- if  sep < 0 then 
					-- y = y + yborder
				-- elseif sep > 0 then
					-- y = y + sep + vars[page].cd[box].distdraw
				-- end
			-- end	
			-- if sep > -1 then y = y + yborder/2 end 
			-- if vars[0].cd[j].col then
				-- lcd.setColor(vars[0].cd[j].col[1],vars[0].cd[j].col[2],vars[0].cd[j].col[3])
				-- lcd.drawRectangle(xli, yStart+1 - yborder / 2, lengthBox-2, yborder-2 + vars.cd[j].y, 3)
				-- lcd.drawFilledRectangle(xStart, yStart-1, lengthBox-4, yborder-4 + vars.cd[j].y)
				-- lcd.setColor(txtr,txtg,txtb)
			-- end
			-- lcd.drawRectangle(xli-1, yStart - y + yborder/2 , lengthBox, y + vars.cd[j].y, 4)		
			-- drawfunc[j]() 
			-- yStart = yStart + vars.cd[j].y + yborder / 2 + vars[page].cd[j].distdraw
		-- else
			-- -- if vars.drawVal[j].valid then 
				-- -- drawfunc[j]()
			-- -- elseif tickTime % 2 == 0 then 
				-- -- drawfunc[j]() 
			-- -- end
			-- drawfunc[j]()
			-- yStart = yStart + vars.cd[j].y + vars[page].cd[j].distdraw
			-- if vars[page].cd[j].sepdraw > 0 then 
				-- lcd.drawFilledRectangle(xli, yStart , lengthSep, vars[page].cd[j].sep)
				-- yStart = yStart + vars[page].cd[j].sep + vars[page].cd[j].distdraw
			-- end
		-- end
	-- end
		
			--  Version mit Umrandung von oben nach unten erweiternd:
			
			-- local y = vars.cd[j].y
			-- local ydistdraw = vars[page].cd[j].distdraw + yborder/2
			-- for k = i+1,math.min(i-1-vars[page].cd[j].sep,#vars[page].leftdrawcol) do
				-- local box = vars[page].leftdrawcol[k]
				-- y = y + vars.cd[box].y + ydistdraw
				-- if vars[page].cd[box].sep < 0 then 
					-- y = y + yborder/2
				-- elseif vars[page].cd[box].sep > 0 then
					-- ydistdraw = vars[page].cd[box].sep + vars[page].cd[box].distdraw*2
				-- end				
			-- end	
			-- lcd.drawRectangle(xli-1, yStart, lengthBox, y + yborder, 4)
			-- yStart = yStart + yborder / 2
			-- drawfunc[j]()			
			-- yStart = yStart + vars.cd[j].y + yborder / 2 + vars[page].cd[j].distdraw

--------------	
	--right
	yStart = 159
	xStart = xre + 1
	for i,j in ipairs(vars[page].rightdrawcol) do 
		if vars[page].cd[j].sep < 0 then
			yStart = yStart - vars.cd[j].y - yborder/2 - vars[page].cd[j].distdraw
			local y = yborder
			local sep = -1
			for k = i+1,math.min(i-1-vars[page].cd[j].sep,#vars[page].rightdrawcol) do
				local box = vars[page].rightdrawcol[k]
				y = y + vars.cd[box].y + vars[page].cd[box].distdraw 
				sep = vars[page].cd[box].sep
				if  sep < 0 then 
					y = y + yborder
				elseif sep > 0 then
					y = y + sep + vars[page].cd[box].distdraw
				end
			end	
			if sep > -1 then y = y + yborder/2 end
			if vars.configG.color[vars[page].cd[j].col] then
				lcd.setColor(vars.configG.color[vars[page].cd[j].col][1],vars.configG.color[vars[page].cd[j].col][2],vars.configG.color[vars[page].cd[j].col][3])
				lcd.drawRectangle(xre, yStart+1-y+yborder/2, lengthBox-2, y-2 + vars.cd[j].y, 3)
				lcd.drawFilledRectangle(xStart, yStart+2-y+yborder/2, lengthBox-4, y-4 + vars.cd[j].y)
				lcd.setColor(txtr,txtg,txtb)
			end
			lcd.drawRectangle(xre-1, yStart - y+yborder/2, lengthBox, y + vars.cd[j].y, 4)
			drawfunc[j]()
			if vars[page].cd[j].sep < 0 then yStart = yStart-yborder/2 end
		else
			if vars[page].cd[j].sepdraw > 0 then 
				yStart = yStart - vars[page].cd[j].sep - vars[page].cd[j].distdraw
				lcd.drawFilledRectangle(xre, yStart , lengthSep, vars[page].cd[j].sep)
			end	
			yStart = yStart - vars.cd[j].y - vars[page].cd[j].distdraw
			drawfunc[j]()
		end
	end
	
	-- for i,j in ipairs(vars[page].rightdrawcol) do 
		-- if vars[page].cd[j].sep < 0 then
			-- yStart = yStart - vars.cd[j].y - yborder/2 - vars[page].cd[j].distdraw
			-- local y = yborder/2
			-- local sep = -1
			-- for k = i+1,math.min(i-1-vars[page].cd[j].sep,#vars[page].rightdrawcol) do
				-- local box = vars[page].rightdrawcol[k]
				-- y = y + vars.cd[box].y + vars[page].cd[box].distdraw 
				-- sep = vars[page].cd[box].sep
				-- if  sep < 0 then 
					-- y = y + yborder
				-- elseif sep > 0 then
					-- y = y + sep + vars[page].cd[box].distdraw
				-- end
			-- end	
			-- if sep > -2 then y = y + yborder/2 end 
			-- if vars[0].cd[j].col then
				-- lcd.setColor(vars[0].cd[j].col[1],vars[0].cd[j].col[2],vars[0].cd[j].col[3])
				-- lcd.drawRectangle(xre, yStart+1-y + yborder / 2, lengthBox-2, y-2 + vars.cd[j].y, 3)
				-- lcd.drawFilledRectangle(xStart, yStart+2-y+ yborder/2, lengthBox-4, y-4 + vars.cd[j].y)
				-- lcd.setColor(txtr,txtg,txtb)
			-- end
			-- lcd.drawRectangle(xre-1, yStart - y + yborder/2 , lengthBox, y + vars.cd[j].y, 4)
			-- drawfunc[j]()
			-- yStart = yStart-yborder/2
		-- else
			-- if vars[page].cd[j].sepdraw > 0 then 
				-- yStart = yStart - vars[page].cd[j].sep - vars[page].cd[j].distdraw
				-- lcd.drawFilledRectangle(xre, yStart , lengthSep, vars[page].cd[j].sep)
			-- end	
			-- yStart = yStart - vars.cd[j].y - vars[page].cd[j].distdraw
			-- drawfunc[j]()
		-- end
	-- end
	
	
		
	-- middle
	drawBattery()
	--draw2Battery(xMitte-13,25,vars.config.Akku1ID)
	--draw2Battery(xMitte+14,25,vars.config.Akku2ID)
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
	if varstemp then vars = varstemp end
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
						
-- Count percentage from cell voltage
local function get_capacity_percent_used(cell_voltage)
	local result=0
	if vars.configG.CalcUsedCapacity then
		if cell_voltage > 4.2 or cell_voltage < 3.00 then
			if(cell_voltage > 4.2)then
				result=0
			end
			if(cell_voltage < 3.00)then
				result=100
			end
		else
			for i,v in ipairs(percentList) do
				if ( v[1] >= cell_voltage ) then
					result =  100 - v[2]
					break
				end
			end
		end
	end

	collectgarbage()
	return result
end

local function batIDchanged()
	vars.capacity = vars.Akkus[vars.AkkusID[vars.batID]].Capacity
	dbdis_capacity = vars.capacity
	vars.cell_count = vars.Akkus[vars.AkkusID[vars.batID]].iCells
	vars.batC = vars.Akkus[vars.AkkusID[vars.batID]].batC
	if vars.lastUsedCapacity == 0 then 
		vars.lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity
	end 
	if vars.AkkuwasFull then
		vars.usedAkku = false
		vars.lastUsedCapacity = 0
	else
		if vars.usedAkku  then -- Akku war nicht voll und usedCapacity > 0 oder der Akku wurde bereits gespeichert
				--print("batID -1:"..vars.batID)
			if vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity == 0 then -- jetzt usedCapacity = 0
				--print("UC 0:"..vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity)
				if ( vars.Value.battery_voltage_sens / vars.cell_count) > 1.1  then
					vars.initial_capacity_percent_used = get_capacity_percent_used(vars.Value.battery_voltage_sens / vars.cell_count)
					system.messageBox("Init. used cap.:"..string.format("%.fmAh",vars.initial_capacity_percent_used*vars.capacity/100) ,5)
					if vars.capacity > 0 then 
						 vars.initial_capacity_percent_used  = vars.initial_capacity_percent_used - (vars.Value.used_capacity_sens-vars.resetusedcapacity)/vars.capacity*100
					end
				end
				vars.lastUsedCapacity = 0
				vars.usedAkku = false
				--print("IUCP 1: "..vars.initial_capacity_percent_used)
			else --jetzt usedCapacity > 0
				vars.lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity 
				--print("LUC 2: "..vars.lastUsedCapacity)
			end
		else -- Akku war nicht voll und usedCapacity = 0
			if vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity > 0 then -- jetzt usedCapacity > 0
				vars.lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity
				vars.initial_capacity_percent_used = 0
				vars.usedAkku = true
				--print("3:"..vars.lastUsedCapacity)
			else
				vars.lastUsedCapacity = 0
			end
		end
	end
end

local function reset()	
	for i,RxTyp in ipairs(RxTypen) do
		vars.Rx[RxTyp].initial = false
		vars.Rx[RxTyp].mina1 = 99
		vars.Rx[RxTyp].mina2 = 99
		vars.Rx[RxTyp].minvoltage = 9.9
		vars.Rx[RxTyp].minpercent = 101.0
		vars.Rx[RxTyp].voltage = 0
		vars.Rx[RxTyp].percent = 0
		vars.Rx[RxTyp].a1 = 0
		vars.Rx[RxTyp].a2 = 0
	end
	for i in pairs(Minlbl) do
		vars.Value[i] = 0
		vars.drawVal[i].min = 0
		vars.drawVal[i].measured = false
	end
	for i in pairs(Maxlbl) do
		vars.Value[i] = 0
		vars.drawVal[i].max = 0
		vars.drawVal[i].measured = false
	end
	for i in pairs(MinMaxlbl) do
		vars.Value[i] = 0
		vars.drawVal[i].max = 0
		vars.drawVal[i].min = 0
		vars.drawVal[i].measured = false
	end
	for i in pairs(Valuelbl) do
		vars.Value[i] = 0
	end

	vars.Value.weakVoltage_sens1 = 0
	
	vars.drawVal.battery_voltage_sens.min = 0
	vars.drawVal.battery_voltage_sens.measured = false
	vars.drawVal.weakVoltage_sens.min = 0
	vars.drawVal.weakVoltage_sens.measured = false
	vars.drawVal.weakCell_sens.min = 0
	vars.drawVal.deltaVoltage_sens.min = 0
	vars.drawVal.weakPack = 0
	vars.drawVal.weakPackmin = 0
	
	-- dese beiden werden jetzt mit Valuelbl auf 0 gesetzt, prüfen ob das passt, sonst bei init auf 0 setzen:
	--vars.Value.battery_voltage_sens = 0 
	--vars.Value.used_capacity_sens = 0	  
	
	-- vars.Value.batC_sens = -2
	-- vars.Value.batCap_sens = -2
	-- vars.Value.batCells_sens = -2

	vars.Value.status_sens = "No Status"
	vars.Value.status2_sens = "No Status"
	vars.battery_voltage_average = 0
	vars.flightTime = 0
	vars.engineTime = 0
	vars.counttheFlight = false
    vars.counttheTime = false  
	vars.countedTime = 0
	vars.lastFlightTime = 0
	vars.RfID = -1
	vars.SWold_Akku = -2
	imainAlarm = 0
	ipreAlarm = 0
	iVoltageAlarm = 0
	calcaApp = false
	
	if vars.receiverOn then 
		vars.RfID = -2   --reset switch
	end
	--Akkudaten neu laden:
	if vars.AkkusID[vars.batID] then
		batIDchanged()
	end
	
	vars.lastTime = system.getTimeCounter()
	vars.lastEngineTime = vars.lastTime
	collectgarbage()
end

local function init (varstemp)
	if varstemp then vars = varstemp end
	vars.Value = {}
	--vars.drawVal = {}
	vars.Rx = {}
	for i,RxTyp in ipairs(RxTypen) do
		vars.Rx[RxTyp] = {}
	end
	-- for i in pairs(Minlbl) do
		-- vars.drawVal[i] = {}
	-- end
	-- for i in pairs(Maxlbl) do
		-- vars.drawVal[i] = {}
	-- end
	-- for i in pairs(MinMaxlbl) do
		-- vars.drawVal[i] = {}
	-- end
	
	-- vars.drawVal.battery_voltage_sens = {}
	-- vars.drawVal.deltaVoltage_sens = {}
	-- vars.drawVal.UsedCap1_sens = {}	
	-- vars.drawVal.UsedCap2_sens = {}
	-- vars.drawVal.OverI_sens = {}
	
	vars.drawVal.weakVoltage_sens = {}
	vars.drawVal.weakCell_sens = {}
	vars.receiverOn = false
	vars.Value.batID_sens = 0
	--vars.Value.used_capacity_sens = 0
	--vars.Value.battery_voltage_sens = 0
	
	vars.initial_capacity_percent_used = 0
	vars.remaining_capacity_percent = 100
	vars.resetusedcapacity = 0
	vars.lastUsedCapacity = 0
	vars.capacity = 0
	vars.usedAkku = false
	vars.AkkuwasFull = false
	vars.cell_count = 1
	vars.batID = 0
	vars.batC = 0
 	setvars()
	reset()
	--reset = false

	loadFlights()
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
	
    local battDspCount = 0
	local usedcap = 0
	
	if vars.AkkusID[vars.batID] then 	
		--if (vars.battery_voltage_average / cell_count) < (vars.initial_cell_voltage - 0.1) or vars.Value.used_capacity_sens > (capacity / 10) then -- Akku wurde gebraucht
		if (vars.battery_voltage_average / vars.cell_count) < vars.configG.AkkuUsed then -- Akku wurde gebraucht
			if (vars.AkkuwasFull and not vars.usedAkku) then -- or (vars.resetusedcapacity == 0 and (vars.Value.battery_voltage_sens == 0 or (calcaApp and vars.Value.battery_voltage_sens == 0))) then -- Akku frisch geladen gewesen
				vars.Akkus[vars.AkkusID[vars.batID]].Cycl = vars.Akkus[vars.AkkusID[vars.batID]].Cycl + 1
				vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity = 0
				vars.usedAkku = true
				vars.AkkuwasFull = false
				--print("-5")
			end
			usedcap = vars.Value.used_capacity_sens - vars.resetusedcapacity
			vars.resetusedcapacity = vars.Value.used_capacity_sens
			vars.Akkus[vars.AkkusID[vars.batID]].Ah = vars.Akkus[vars.AkkusID[vars.batID]].Ah + (usedcap / 1000)
			vars.Akkus[vars.AkkusID[vars.batID]].lastVoltage = vars.battery_voltage_average / vars.cell_count
			vars.lastUsedCapacity = vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity + usedcap
			vars.Akkus[vars.AkkusID[vars.batID]].usedCapacity = vars.lastUsedCapacity	
			--print("-4:"..vars.lastUsedCapacity)
			saveAkkus()
			--reset = true
		end
		battDspCount = string.format("%.0f",vars.Akkus[vars.AkkusID[vars.batID]].Cycl)
	end
		
	-- write logfile
	local dtflighttime = string.format("%4d:%02d:%02d", vars.flightTime // 3600000, (vars.flightTime % 3600000) / 60000, (vars.flightTime % 60000) / 1000)
	local dtengineTime = string.format("%4d:%02d:%02d", vars.engineTime // 3600000, (vars.engineTime % 3600000) / 60000, (vars.engineTime % 60000) / 1000)
	local dttotalFlighttime = string.format("%4d:%02d:%02d", vars.totalFlighttime // 3600, (vars.totalFlighttime % 3600) / 60, vars.totalFlighttime % 60)
    local dt = system.getDateTime()
    local dtDate = string.format("%02d.%02d.%02d", dt.year, dt.mon, dt.day)
	local dtTime = string.format("%02d:%02d", dt.hour, dt.min)
	local usedFuel = (100 - vars.Value.remaining_fuel_percent_sens) * vars.config.tank_volume // 100
	
    local logLine = string.format("%s;%s;%15s;%4s;%4s;%s;%s;% 3d;% 6d;% 9d;%  .2f;% 5d", dtDate, dtTime, vars.model, math.floor(vars.totalCount), dttotalFlighttime, dtflighttime, dtengineTime, vars.batID, battDspCount, string.format("%.0f",usedcap), minvperc, usedFuel)
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
           
-- Flight time
-- Der Flug wird erst gezählt und die Flugzeit zur Gesamtflugzeit addiert sobald der Timer zum ersten mal gestoppt wird und die minimale Flugzeit erreicht wurde.
-- Wird der Flug fortgesetzt wird beim nächsten Stop des Timers die Zeit zur Gesamtzeit hinzugefügt.
-- Wird wärend der Timer läuft der Reset betätigt wird der Timer auf 0 gesetzt. Wurde der Flug bereits gezählt, sprich der Timer vorher schon einmal gestoppt, dann beginnt ein neuer Flug
-- Wird der Reset betätigt ohne dass der Flug bereits gezählt wurde, dann wird der ganze Flug verworfen, und der Timer beginnt von vorne.

local function FlightTime()

	timeSw_val = system.getInputsVal(vars.switches.timeSw)
	engineSw_val = system.getInputsVal(vars.switches.engineSw)
	
	if vars.switches.timeSw ~= nil and timeSw_val ~= 0.0 then 
		if timeSw_val == 1 then
			vars.flightTime = newTime - vars.lastTime
			vars.counttheTime = false
			if vars.config.timeToCount > 0 and not vars.counted then 
				vars.todayCount = vars.todayCount + 1
				vars.counted = true
			end
		else	-- Stoppuhr gestoppt
			vars.lastTime = newTime - vars.flightTime -- properly start of first interval
			if vars.config.timeToCount > 0 and vars.flightTime > vars.config.timeToCount * 1000 and not vars.counttheFlight then  -- Count of the flights
				vars.totalCount = vars.totalCount + 1
				saveFlights()
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", system.getTime() // 86400)
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
  
	if vars.switches.engineSw ~= nil and engineSw_val ~= 0.0 then	
		if engineSw_val == 1 then
			vars.engineTime = newTime - vars.lastEngineTime
		else
			vars.lastEngineTime = newTime - vars.engineTime -- properly start of first interval
		end
	else
		vars.lastEngineTime = newTime
	end
	
	collectgarbage()
end
 
local function accuvalues()
	local AkkuNeu = false
	vars.RfID = vars.Value.batID_sens
	vars.batID = vars.Value.batID_sens
	if vars.AkkusID[vars.batID] then 
		batIDchanged()
	else
		i = #vars.Akkus + 1
		vars.Akkus[i] = {}
		vars.Akkus[i].ID = vars.batID
		vars.Akkus[i].Name = ""
		vars.Akkus[i].Cycl = 0
		vars.Akkus[i].Ah = 0
		vars.Akkus[i].lastVoltage = 0
		vars.Akkus[i].usedCapacity = 0
		vars.Akkus[i].batC = 0
		vars.lastUsedCapacity = 0
		vars.capacity = 0
		vars.cell_count = 0
		vars.batC = 0
		AkkuNeu = true	
	end
		
	-- C-Rate von Rfid
	if vars.Value.batC_sens and vars.Value.batC_sens > 0 then vars.batC = vars.Value.batC_sens end
		
	-- Kapazität von Rfid
	if vars.Value.batCap_sens and vars.Value.batCap_sens > 0 then vars.capacity = vars.Value.batCap_sens end
	
	-- Zellenzahl von Rfid
	if vars.Value.batCells_sens and vars.Value.batCells_sens > 0 then vars.cell_count = vars.Value.batCells_sens end
	
	if AkkuNeu then 
		vars.Akkus[i].iCells = vars.cell_count
		vars.Akkus[i].Capacity = vars.capacity
		vars.Akkus[i].batC = vars.batC
		saveAkkus()
		AkkuNeu = false
	end
	dbdis_capacity = vars.capacity
end

	--Read Sensor Parameter Voltage 
local function battery_voltage_sens()
	local initial_cell_voltage
	if vars.Value.battery_voltage_sens > 0 then
	-- guess used capacity from voltage if we started with partially discharged battery 
		if not vars.drawVal.battery_voltage_sens.measured then
			if ( vars.Value.battery_voltage_sens / vars.cell_count) > 1.1 and vars.AkkusID[vars.batID] then 
				vars.drawVal.battery_voltage_sens.measured = true
				vars.drawVal.battery_voltage_sens.min = vars.Value.battery_voltage_sens
				next_voltage_alarm = tickTime + 2
				iVoltageAlarm = 0
				initial_cell_voltage = vars.Value.battery_voltage_sens / vars.cell_count
				if initial_cell_voltage < vars.configG.AkkuFull then
					vars.AkkuwasFull = false
				else 
					vars.AkkuwasFull = true
				end
				if vars.AkkuwasFull or (not vars.AkkuwasFull and vars.lastUsedCapacity == 0) then
					vars.initial_capacity_percent_used = get_capacity_percent_used(initial_cell_voltage)
					system.messageBox("Init. used cap.:"..string.format("%.fmAh",vars.initial_capacity_percent_used*vars.capacity/100) ,5)
					if vars.capacity > 0 then 
						 vars.initial_capacity_percent_used = vars.initial_capacity_percent_used - (vars.Value.used_capacity_sens-vars.resetusedcapacity)/vars.capacity*100
					end
					--print("4:"..vars.ICPUsaved)
					--print("5:"..UCPS)
					vars.lastUsedCapacity = 0
					vars.usedAkku = false
					--print("UCS 6:"..vars.Value.used_capacity_sens)
				end
			else
				vars.initial_capacity_percent_used = 0
			end  
		elseif vars.Value.battery_voltage_sens < vars.drawVal.battery_voltage_sens.min then 
			vars.drawVal.battery_voltage_sens.min = vars.Value.battery_voltage_sens 
		end
		
		-- calculate Min/Max Sensor 1
		--if vars.Value.battery_voltage_sens < vars.minvtg and vars.initial_voltage_measured then vars.minvtg = vars.Value.battery_voltage_sens end
		--if vars.Value.battery_voltage_sens > vars.maxvtg then vars.maxvtg = vars.Value.battery_voltage_sens end
		
		if newTime > (last_averaging_time + 400) then          -- one second period (1000), newTime set from FlightTime()
			vars.battery_voltage_average = average(vars.Value.battery_voltage_sens)   -- average voltages over n samples
			last_averaging_time = newTime
		end
		
		if ((vars.drawVal.battery_voltage_sens.measured and (vars.battery_voltage_average / vars.cell_count) <= vars.config.voltage_alarm_thresh/100) or (vars.drawVal.weakVoltage_sens.measured and vars.Value.weakVoltage_sens <= vars.config.voltage_alarm_thresh/100)) and vars.config.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime and iVoltageAlarm < vars.configG.imaxVoltAlarm then
			system.messageBox(vars.trans.voltWarn,2)
			system.playFile(vars.config.voltage_alarm_voice,AUDIO_QUEUE)
			iVoltageAlarm = iVoltageAlarm + 1
			next_voltage_alarm = tickTime + 5 -- battery voltage alarm every 4 second 
		end  
		
		if(anVoltGo == 1 and tickTime >= next_voltage_announcement) then
			system.playNumber(vars.Value.battery_voltage_sens / vars.cell_count, 1, "V", "U Battery")
			next_voltage_announcement = tickTime + 10 -- say battery voltage every 10 seconds
		end
	else
		vars.battery_voltage_average = 0
		vars.drawVal.battery_voltage_sens.measured = false
	end
 end

function calcfunc.weakVoltage_sens1()
	local Umin = 1000
	local imin = 1
	local i = 1
	
	if vars.drawVal.weakVoltage_sens.measured then
		--Umin=vars.Value.weakVoltage_sens1
		while vars.Value["weakVoltage_sens"..i] do
			local tmpU = vars.Value["weakVoltage_sens"..i]
			if tmpU > 0 and  tmpU < Umin then 
				Umin = tmpU
				imin = i
			end
			i=i+1
		end
		if Umin < 1000 then 
			vars.Value.weakVoltage_sens = Umin
			if vars.Value["weakCell_sens"..imin] then 
				if i>2 then 
					vars.drawVal.weakPack = imin
				end
				vars.Value.weakCell_sens = vars.Value["weakCell_sens"..imin]
				if not vars.senslbl.checkedCells_sens then
					vars.Value.checkedCells_sens = (i-1)*6
				end
			else
				vars.Value.weakCell_sens = imin
				if not vars.senslbl.checkedCells_sens then
					vars.Value.checkedCells_sens = i-1
				end
			end
			if Umin < vars.drawVal.weakVoltage_sens.min then
				vars.drawVal.weakVoltage_sens.min = Umin
				if vars.Value["weakCell_sens"..imin] then 
					vars.drawVal.weakCell_sens.min = vars.Value["weakCell_sens"..imin]
					vars.drawVal.weakPackmin = imin
					vars.drawVal.deltaVoltage_sens.min = vars.Value.deltaVoltage_sens			
				else
					vars.drawVal.weakCell_sens.min = imin
				end
			end
		end
	else
		if vars.Value.weakVoltage_sens1 > 0 then
			vars.drawVal.weakVoltage_sens.measured = true
			vars.drawVal.weakVoltage_sens.min = vars.Value.weakVoltage_sens1
			if vars.Value.weakCell_sens1 then 
				vars.Value.weakCell_sens = vars.Value.weakCell_sens1
				vars.drawVal.weakPackmin = 1				
			else
				vars.Value.weakCell_sens = 1
			end
			vars.drawVal.deltaVoltage_sens.min = vars.Value.deltaVoltage_sens
			vars.drawVal.weakCell_sens.min = vars.Value.weakCell_sens
		end
	end
	collectgarbage()
end	

--alt
-- function calcfunc.weakVoltage_sens()
	-- if not vars.drawVal.weakVoltage_sens.measured then
		-- if vars.Value.weakVoltage_sens ~= 0.0 then
			-- vars.drawVal.weakVoltage_sens.measured = true
			-- vars.drawVal.weakVoltage_sens.min = vars.Value.weakVoltage_sens
			-- vars.drawVal.weakCell_sens.min = vars.Value.weakCell_sens
			-- vars.drawVal.deltaVoltage_sens.min = vars.Value.deltaVoltage_sens
		-- end
	-- elseif vars.Value.weakVoltage_sens < vars.drawVal.weakVoltage_sens.min then 
		-- vars.drawVal.weakCell_sens.min = vars.Value.weakCell_sens
		-- vars.drawVal.deltaVoltage_sens.min = vars.Value.deltaVoltage_sens
		-- vars.drawVal.weakVoltage_sens.min = vars.Value.weakVoltage_sens
	-- end 
-- end	


local function loop()
	local temp
	local itemp
	local calcaApptemp
	
	resetSw_val = system.getInputsVal(vars.switches.resSw)
	engineOffSw_val = system.getInputsVal(vars.switches.engineOffSw)
	tickTime = system.getTime()
	newTime = system.getTimeCounter()

	-- Rx values:
	txtelemetry = system.getTxTelemetry()
	for i,RxTyp in ipairs(RxTypen) do
		vars.Rx[RxTyp].percent = txtelemetry[RxTyp.."Percent"] 
		
		--if vars.switches.engineSw then vars.Rx.rx1.percent = system.getInputsVal(vars.switches.engineSw) * 100 end ----------------- zum Testen Auskommentierung aufheben!!!!!!!!!!!!!!!!!!!
		
		if not vars.Rx[RxTyp].initial then
			if vars.Rx[RxTyp].percent > 99.0 then
				if not vars.receiverOn then
					itemp = vars.Rx[RxTyp].percent
					calcaApptemp = calcaApp
					init()
					vars.Rx[RxTyp].percent = itemp
					vars.receiverOn = true
					if calcaApptemp and not vars.senslbl.battery_voltage_sens then 
						vars.AkkuwasFull = true
						vars.usedAkku = false
					end
				end		
				vars.Rx[RxTyp].initial = true
			end
		else
			vars.Rx[RxTyp].voltage = txtelemetry[RxTyp.."Voltage"]
			vars.Rx[RxTyp].a1 = txtelemetry.RSSI[i*2-1]
			vars.Rx[RxTyp].a2 = txtelemetry.RSSI[i*2]
			if vars.Rx[RxTyp].voltage > 0.0 and vars.Rx[RxTyp].voltage < vars.Rx[RxTyp].minvoltage then vars.Rx[RxTyp].minvoltage = vars.Rx[RxTyp].voltage end
			if vars.Rx[RxTyp].percent > 0.0 and vars.Rx[RxTyp].percent < vars.Rx[RxTyp].minpercent then vars.Rx[RxTyp].minpercent = vars.Rx[RxTyp].percent end
			if vars.Rx[RxTyp].a1 > 0 and vars.Rx[RxTyp].a1 < vars.Rx[RxTyp].mina1 then vars.Rx[RxTyp].mina1 = vars.Rx[RxTyp].a1 end
			if vars.Rx[RxTyp].a2 > 0 and vars.Rx[RxTyp].a2 < vars.Rx[RxTyp].mina2 then vars.Rx[RxTyp].mina2 = vars.Rx[RxTyp].a2 end
		end
	end 
	
	if vars.Rx.rx1.percent < 1 and vars.Rx.rx2.percent < 1 and vars.Rx.rxB.percent < 1 then -- Empfänger aus
		if vars.receiverOn then 
			if  vars.switches.timeSw ~= nil and timeSw_val == 1 and vars.config.timeToCount > 0 and vars.flightTime > vars.config.timeToCount * 1000 then  --Empfänger aus während Stoppuhr läuft
				if not vars.counttheFlight then 
					vars.totalCount = vars.totalCount + 1 
				end
				vars.totalFlighttime = vars.totalFlighttime + ((vars.flightTime - vars.lastFlightTime) / 1000)
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", system.getTime() // 86400)			
				saveFlights() 
				writeLog()
				vars.counted = false
			elseif vars.counttheFlight then 
				vars.counted = false 
				writeLog()
			end
	
			vars.Rx.rx1.initial = false
			vars.Rx.rx2.initial = false
			vars.Rx.rxB.initial = false
			vars.RfID = 0
			vars.receiverOn = false
		end
	end
	
	temp = system.getInputsVal(vars.switches.anVoltSw)
	if anVoltGo ~= temp then
		anVoltGo = temp
		next_voltage_announcement = tickTime
	end
	
	temp = system.getInputsVal(vars.switches.anCapaSw)
	if anCapaGo ~= temp then
		anCapaGo = temp
		next_capacity_announcement = tickTime
	end
	
	temp = system.getInputsVal(vars.switches.anCapaValSw)
	if anCapaValGo ~= temp then
		anCapaValGo = temp
		next_value_announcement = tickTime
	end
	
	if vars.config.gyChannel ~= 17 then gyro_channel_value = system.getInputs(vars.config.gyro_output)
	else gyro_channel_value = 17
	end	
	
	-- to be in sync with a system timer, do not use CLR key 
	if (resetSw_val == 1) then
		local question = -1
		if vars.counttheFlight then 
			vars.counted = false 
			if vars.receiverOn then 
				writeLog() 
			end
			question = 1
		elseif vars.receiverOn and vars.config.timeToCount > 0 and vars.flightTime > vars.config.timeToCount * 1000 then
			question = form.question("Do you want to save?","Flight not saved yet!","",0,false, 0)
			if  question == 1 then 
				if not vars.counttheFlight then 
					vars.totalCount = vars.totalCount + 1 
				end
				vars.totalFlighttime = vars.totalFlighttime + ((vars.flightTime - vars.lastFlightTime) / 1000)
				system.pSave("todayCount", vars.todayCount)
				system.pSave("lastDay", system.getTime() // 86400)			
				saveFlights()
				vars.counted = false
				writeLog()	
			end
		else question = 1
		end
		if question > -1 then reset() end
	end	
 
	--Akkuwerte
	vars.AkkuSW = system.getInputsVal(vars.switches.akkuSw)
	if vars.RfID == -1 then
		if vars.AkkuSW ~= vars.SWold_Akku then
			vars.SWold_Akku = vars.AkkuSW
			if  vars.AkkuSW == 1 and vars.AkkusID[vars.config.Akku2ID] then 
				newbatID = vars.config.Akku2ID
			elseif vars.AkkusID[vars.config.Akku1ID] then 
				newbatID = vars.config.Akku1ID
			elseif vars.AkkusID[vars.config.Akku2ID] then 
				newbatID = vars.config.Akku2ID
			end		
			if newbatID > 0 and newbatID ~=vars.batID then
				vars.batID = newbatID
				batIDchanged()
			end	
		end
	end
		
		-- kein Spritsensor zugeordnet
	if not vars.senslbl.remaining_fuel_percent_sens then
		if Calca_dispGas then 
			vars.Value.remaining_fuel_percent_sens = Calca_dispGas
			-- if vars.config.tank_volume <= 0 then 
				-- vars.config.tank_volume = Calca_selTank 
			-- end
		end
	end
	
		-- kein Kapazitätssensor zugeordnet
	if not vars.senslbl.used_capacity_sens then
		if Calca_dispFuel then 
			if vars.capacity <= 0 then 
				vars.capacity = Calca_capacity
			end
			vars.Value.used_capacity_sens = vars.capacity * (1 - Calca_dispFuel / 100 )
			--vars.remaining_capacity_percent = Calca_dispFuel
			--vars.config.capacity_alarm_thresh = Calca_sBingo 
			calcaApp = true
		else 
			--vars.Value.used_capacity_sens = -1 
			calcaApp = false
		end
	end

	
	if vars.receiverOn then
	
		FlightTime()
	
		--Sensorwerte abfragen
		for senslbl, sens in pairs(vars.senslbl) do
			sensor = system.getSensorValueByID(sens[1], sens[2])
			if (sensor and sensor.valid) then
				vars.Value[senslbl] = sensor.value
				vars.drawVal[senslbl].valid = true
			else
				vars.drawVal[senslbl].valid = false
				--vars.Value[senslbl] = 0  --nil
			end
		end
	 	
		--accuvalues from RFID
		if vars.senslbl.batID_sens and vars.Value.batID_sens > 0 then
			if vars.RfID ~= vars.Value.batID_sens then accuvalues() end
		else
			if vars.RfID < 0 then  -- comes from reset switch (zuerst RfID abfragen und dann erst den Akkuschalter abfragen um umschalten zw. den Akkus zu vermeiden)
				vars.RfID = -1
			else
				vars.RfID = 0
			end
		end
		
		-- min und max Werte abfragen
		for senslbl, sens in pairs(vars.senslbl) do	
			if Maxlbl[senslbl] then
				if vars.drawVal[senslbl].measured then
					if vars.Value[senslbl] > vars.drawVal[senslbl].max then 
						vars.drawVal[senslbl].max = vars.Value[senslbl]
					end
				elseif vars.Value[senslbl] ~= 0.0 then
					vars.drawVal[senslbl].measured = true
					vars.drawVal[senslbl].max = vars.Value[senslbl]
				end
			elseif Minlbl[senslbl] then
				if vars.drawVal[senslbl].measured then
					if vars.Value[senslbl] < vars.drawVal[senslbl].min then 
						vars.drawVal[senslbl].min = vars.Value[senslbl]
					end
				elseif vars.Value[senslbl] ~= 0.0 then
					vars.drawVal[senslbl].measured = true
					vars.drawVal[senslbl].min = vars.Value[senslbl]
				end
			elseif MinMaxlbl[senslbl] then
				if vars.drawVal[senslbl].measured then
					if vars.Value[senslbl] < vars.drawVal[senslbl].min then 
						vars.drawVal[senslbl].min = vars.Value[senslbl] 
					elseif vars.Value[senslbl] > vars.drawVal[senslbl].max then 
						vars.drawVal[senslbl].max = vars.Value[senslbl] 
					end				
				elseif vars.Value[senslbl] ~= 0.0 then
					vars.drawVal[senslbl].measured = true
					vars.drawVal[senslbl].min = vars.Value[senslbl]
					vars.drawVal[senslbl].max = vars.Value[senslbl]
				end
			elseif calcfunc[senslbl] then
				calcfunc[senslbl]()
			end
		end
		

		if vars.senslbl.battery_voltage_sens then
			battery_voltage_sens()
		else-- kein Spannungssensor zugeordnet
			vars.drawVal.battery_voltage_sens.measured = true 	
		end	
		
		--if reset then
		if vars.Value.used_capacity_sens < vars.resetusedcapacity  then  vars.resetusedcapacity = vars.Value.used_capacity_sens end
			-- reset = false
		--end
		
		---Alarme:
		--vars.remaining_capacity_percent alarm
		if vars.remaining_capacity_percent > 0 and next_capacity_alarm < tickTime then
			if imainAlarm < vars.configG.imaxMainAlarm and vars.remaining_capacity_percent <= vars.config.capacity_alarm_thresh then
				if vars.config.capacity_alarm_voice == "..." then
					system.playNumber(vars.remaining_capacity_percent, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				imainAlarm = imainAlarm + 1
				if imainAlarm == vars.configG.imaxMainAlarm then ipreAlarm = vars.configG.imaxPreAlarm end
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			elseif ipreAlarm < vars.configG.imaxPreAlarm and vars.remaining_capacity_percent <= vars.config.capacity_alarm_thresh2 then
				if vars.config.capacity_alarm_voice2 == "..." then
					system.playNumber(vars.remaining_capacity_percent, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice2,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				ipreAlarm = ipreAlarm + 1
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			end
		end
		
		--remaining_fuel_percent_sens alarm
		if vars.Value.remaining_fuel_percent_sens > 0 and next_capacity_alarm < tickTime then
			if imainAlarm < vars.configG.imaxMainAlarm and vars.Value.remaining_fuel_percent_sens <= vars.config.capacity_alarm_thresh then
				if vars.config.capacity_alarm_voice == "..." then
					system.playNumber(vars.Value.remaining_fuel_percent_sens, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				imainAlarm = imainAlarm + 1
				if imainAlarm == vars.configG.imaxMainAlarm then ipreAlarm = vars.configG.imaxPreAlarm end
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			elseif ipreAlarm < vars.configG.imaxPreAlarm and vars.Value.remaining_fuel_percent_sens <= vars.config.capacity_alarm_thresh2 then
				if vars.config.capacity_alarm_voice2 == "..." then
					system.playNumber(vars.Value.remaining_fuel_percent_sens, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice2,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				ipreAlarm = ipreAlarm + 1
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			end
		end
		
		if anCapaGo == 1 and tickTime >= next_capacity_announcement then
			if vars.senslbl.remaining_fuel_percent_sens or Calca_dispGas  then
				system.playNumber(vars.Value.remaining_fuel_percent_sens, 0, "%")
				next_capacity_announcement = tickTime + 10 -- say fuel percentage every 10 seconds
			else
				system.playNumber(vars.remaining_capacity_percent, 0, "%")
				next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
			end	
		end
		
		if anCapaValGo == 1 and tickTime >= next_value_announcement then
			if vars.senslbl.remaining_fuel_percent_sens or Calca_dispGas  then
				system.playNumber(vars.Value.remaining_fuel_percent_sens * vars.config.tank_volume / 100, 0, "ml")
				next_value_announcement = tickTime + 10 -- say fuel value every 10 seconds
			else
				system.playNumber(vars.remaining_capacity_percent * vars.capacity / 100, 0, "mAh")
				next_value_announcement = tickTime + 10 -- say battery value every 10 seconds
			end	
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
