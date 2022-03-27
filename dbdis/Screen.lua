local col1, col2, col3 = 0,0,0
local colr, colg, colb
local txtr,txtg,txtb
local maxr, maxg, maxb
local minr, ming, minb = 0,140,0
local alarmr, alarmg, alarmb = 200,0,0
local xStart
local yStart
local xMitte = 159
local xli = 1 -- x Abstand der Anzeigeboxen vom linken Rand
local lengthSep = 126
local lengthBox = 128
local xre = 191  -- xMitte - xli - lengthSep + xMitte
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
local sens12 = {"_sens", "2_sens"}
local rcp_min, rcv_min = 0, 0
local rfp_min, rfv_min = 0, 0


-- 28 Sensoren + 2 Variable
Maxlbl = {["motor_current_sens"] = true,["motor_current2_sens"] = true, ["bec_current_sens"] = true, ["pwm_percent_sens"] = true, ["fet_temp_sens"] = true, ["throttle_sens"] = true, ["I1_sens"] = true, ["I2_sens"] = true, ["Temp_sens"] = true,["Temp2_sens"] = true, ["rotor_rpm_sens"] = true,["rpm2_sens"] = true, ["altitude_sens"] = true, ["speed_sens"] = true, ["vibes_sens"] = true, ["pump_voltage_sens"] = true}	--16
Minlbl = {["U1_sens"] = true, ["U2_sens"] = true} --2
MinMaxlbl = {["vario_sens"] = true, ["ax_sens"] = true, ["ay_sens"] = true, ["az_sens"] = true} --4
Valuelbl = {["battery_voltage_sens"] = true,["battery_voltage2_sens"] = true, ["UsedCap1_sens"] = true, ["UsedCap2_sens"] = true, ["OverI_sens"] = true,["used_capacity_sens"] = true, ["used_capacity2_sens"] = true, ["remaining_fuel_percent_sens"] = true,["remaining_fuel_percent2_sens"] = true, ["checkedCells_sens"] = true, ["deltaVoltage_sens"] = true,["weakVoltage_sens"] = true, ["weakCell_sens"] = true} --10



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
	lcd.drawRectangle(134, 4, 51, 22, 3)
	lcd.drawFilledRectangle(135, 5, 49, 20)
	lcd.setColor(txtr,txtg,txtb)
	lcd.drawRectangle(132, 2, 55, 26, 5)
	lcd.drawRectangle(133, 3, 53, 24, 4)
	lcd.drawText(160 - (lcd.getTextWidth(FONT_BIG, string.format("%.f%%",value)) / 2),4, string.format("%.f%%",value),FONT_BIG)
end

local function drawPercent2(xleft,value)
	lcd.drawRectangle(xleft, 4, 24, 23, 3)
	lcd.drawRectangle(xleft-1, 3, 26, 25, 4)
	lcd.drawFilledRectangle(xleft+1, 5, 22, 21)
	lcd.setColor(txtr,txtg,txtb)
	lcd.drawRectangle(xleft-2, 2, 28, 27, 5)
	lcd.drawText(xleft+12 - (lcd.getTextWidth(FONT_BOLD, string.format("%.f",value)) / 2),2, string.format("%.f", value),FONT_BOLD)
	lcd.drawText(xleft+8, 16,"%",FONT_MINI)		
end

-- Draw Battery and percentage display
function drawfunc.drawBattery()
	local temp
	local topbat = 39   
	local highbat = 108  
	
	-- Battery
	lcd.drawFilledRectangle(144, 32, 31, 5)	-- top of Battery
	lcd.drawRectangle(132, 37, 55, 112)
	lcd.drawRectangle(133, 38, 53, 110)

	-- Level of Battery
	local chgH = vars.remaining_capacity_percent1 * highbat // 100
	local chgY = 147 - chgH
	local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
	local Halarm = chgHalarm
	local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
	
	if vars.remaining_capacity_percent1 <= vars.config.capacity_alarm_thresh then
		chgHalarm = chgH
		chgHalarm2 = chgH
		if system.getTime() % 2 == 0 then
			lcd.setColor(250,0,0) -- rot
			drawPercent(vars.remaining_capacity_percent1)
		end
	elseif vars.remaining_capacity_percent1 <= vars.config.capacity_alarm_thresh2 then 
		chgHalarm2 = chgH
		if system.getTime() % 4 ~= 0 then
			lcd.setColor(250,250,0) -- gelb
			drawPercent(vars.remaining_capacity_percent1) 
		end
	else
		lcd.setColor(colr,colg,colb) --grün
		drawPercent(vars.remaining_capacity_percent1)
	end

	local chgYalarm = 147 - chgHalarm
	local chgYalarm2 = 147 - chgHalarm2
	  
	lcd.setColor(colr,colg,colb)
	lcd.drawFilledRectangle(134, chgY, 51, chgH) --grün
	lcd.setColor(250,250,0)
	lcd.drawFilledRectangle(134, chgYalarm2, 51, chgHalarm2) --gelb
	lcd.setColor(250,0,0)
	lcd.drawFilledRectangle(134, chgYalarm, 51, chgHalarm) --rot
	lcd.setColor(txtr,txtg,txtb)
	
	-- Text in battery
	local drawcapacity = vars.Akkus[vars.Akku1].Capacity
	if drawcapacity == 1 then drawcapacity = 0 end
	lcd.drawText(160-(lcd.getTextWidth(FONT_BIG, string.format("%.f",drawcapacity)) / 2),40, string.format("%.f", drawcapacity),FONT_BIG)
	lcd.drawText(149, 60, "mAh", FONT_MINI)
	--s and C-Rate
	temp = string.format("%.f",vars.Akkus[vars.Akku1].iCells).."S"
	if vars.Akkus[vars.Akku1].batC > 0 then temp = temp.." / "..string.format("%.f",vars.Akkus[vars.Akku1].batC).."C" end
	if gyro_channel_value == 17 then 
		lcd.drawText(xMitte-(lcd.getTextWidth(FONT_MINI, temp) / 2),148, temp,FONT_MINI)
	else
		lcd.setColor(0,0,200)
		lcd.drawText(160-(lcd.getTextWidth(FONT_MINI,temp) / 2),134,temp,FONT_MINI)
		lcd.setColor(txtr,txtg,txtb)
	end
	-- ID, Name
	lcd.drawText(160-(lcd.getTextWidth(FONT_NORMAL, vars.Akkus[vars.Akku1].ID) / 2),81, vars.Akkus[vars.Akku1].ID,FONT_NORMAL)
	lcd.setColor(0,0,200)
	lcd.drawText(160-(lcd.getTextWidth(FONT_MINI, string.format("%s",vars.Akkus[vars.Akku1].Name)) / 2),136-Halarm, string.format("%s", vars.Akkus[vars.Akku1].Name),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
	
	if vars.ak[1].RfID > 0 then
		lcd.drawCircle(160,91,13)
		lcd.drawCircle(160,91,12)
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
local function draw2Batteries(xleft, value, Akku, RfID)
	local temp
	local topbat = 39   
	local highbat = 118
	
	-- Battery
	lcd.drawFilledRectangle(xleft+5, 33, 13, 4)	-- top of Battery
	lcd.drawRectangle(xleft-2, 37, 28, 122)
	lcd.drawRectangle(xleft-1, 38, 26, 120)

	-- Level of Battery
	local chgH = value * highbat // 100
	local chgY = 157 - chgH
	local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
	local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
	
	if value <= vars.config.capacity_alarm_thresh then
		chgHalarm = chgH
		chgHalarm2 = chgH
		if system.getTime() % 2 == 0 then
			lcd.setColor(250,0,0) -- rot
			drawPercent2(xleft,value)
		end
	elseif value <= vars.config.capacity_alarm_thresh2 then 
		chgHalarm2 = chgH
		if system.getTime() % 4 ~= 0 then
			lcd.setColor(250,250,0) -- gelb
			drawPercent2(xleft,value) 
		end
	else
		lcd.setColor(colr,colg,colb) --grün
		drawPercent2(xleft,value)
	end
	
	local chgYalarm = 157 - chgHalarm
	local chgYalarm2 = 157 - chgHalarm2
	  
	lcd.setColor(colr,colg,colb)
	lcd.drawFilledRectangle(xleft, chgY, 24, chgH) --grün
	lcd.setColor(250,250,0)
	lcd.drawFilledRectangle(xleft, chgYalarm2, 24, chgHalarm2) --gelb
	lcd.setColor(250,0,0)
	lcd.drawFilledRectangle(xleft, chgYalarm, 24, chgHalarm) --rot
	lcd.setColor(txtr,txtg,txtb)
	-- Text in battery
	local drawcapacity
	drawcapacity = vars.Akkus[Akku].Capacity/1000
	lcd.drawText(xleft+12-(lcd.getTextWidth(FONT_BOLD, string.format("%.1f",drawcapacity)) / 2),42, string.format("%.1f", drawcapacity),FONT_BOLD)
	lcd.drawText(xleft+5, 59, "Ah", FONT_MINI)
	--s
	temp = string.format("%.fS",vars.Akkus[Akku].iCells)
	lcd.drawText(xleft+12-(lcd.getTextWidth(FONT_MINI, temp) / 2),143, temp,FONT_MINI)
	-- ID, Name
	lcd.drawText(xleft+12-(lcd.getTextWidth(FONT_NORMAL, vars.Akkus[Akku].ID) / 2),81, vars.Akkus[Akku].ID,FONT_NORMAL)
	
	if RfID > 0 then
		lcd.drawRectangle(xleft+1,81,22,20,6)
	end
	
	collectgarbage()
end

function drawfunc.draw1stBattery()
	draw2Batteries(133, vars.remaining_capacity_percent1, vars.Akku1, vars.ak[1].RfID)
end

function drawfunc.draw2ndBattery(i)
	draw2Batteries(104+i*29, vars.remaining_capacity_percent2, vars.Akku2, vars.ak[2].RfID)
end

-- Draw tank and percentage display
function drawfunc.drawTank()
	local topbat = 33   
	local highbat = 124
	local strTank_volume = tostring(math.floor(vars.config.tank_volume1 / vars.tankRatio))

	lcd.setColor(0,220,0)
	lcd.drawText(171,38, "F", FONT_BOLD)  
	lcd.setColor(250,0,0)
	lcd.drawText(171,132, "E", FONT_BOLD) 
	lcd.setColor(txtr,txtg,txtb)

	-- Tank
	lcd.drawFilledRectangle(134, topbat, 2, highbat)
	lcd.drawFilledRectangle(162, topbat, 2, highbat)
	lcd.drawFilledRectangle(134,157, 30, 2)

	lcd.drawFilledRectangle(167, topbat, 17, 2)
	lcd.drawFilledRectangle(167, 157, 17, 2)
	lcd.drawFilledRectangle(167, 95, 14, 2)
	lcd.drawFilledRectangle(167, 64, 12, 1)
	lcd.drawFilledRectangle(167, 126, 12, 1)
	
	-- Level of fuel
	local chgH = vars.remaining_fuel_percent1 * highbat // 100
	local chgY = 157 - chgH
	local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
	local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
	
	if vars.remaining_fuel_percent1 <= vars.config.capacity_alarm_thresh then
		chgHalarm = chgH
		chgHalarm2 = chgH
		if system.getTime() % 2 == 0 then
			lcd.setColor(250,0,0) -- rot
			drawPercent(vars.remaining_fuel_percent1)
		end
	elseif vars.remaining_fuel_percent1 <= vars.config.capacity_alarm_thresh2 then 
		chgHalarm2 = chgH
		if system.getTime() % 4 ~= 0 then
			lcd.setColor(250,250,0) -- gelb
			drawPercent(vars.remaining_fuel_percent1) 
		end
	else
		lcd.setColor(colr,colg,colb) --grün
		drawPercent(vars.remaining_fuel_percent1)
	end
	
	local chgYalarm = 157 - chgHalarm
	local chgYalarm2 = 157 - chgHalarm2
	  
	lcd.setColor(colr,colg,colb)
	lcd.drawFilledRectangle(136, chgY, 26, chgH) --grün
	lcd.setColor(250,250,0)
	lcd.drawFilledRectangle(136, chgYalarm2, 26, chgHalarm2) --gelb
	lcd.setColor(250,0,0)
	lcd.drawFilledRectangle(136, chgYalarm, 26, chgHalarm) --rot
	lcd.setColor(txtr,txtg,txtb)

	 -- Text in Tank
	for i = 1, #strTank_volume do
		lcd.drawText(145,22 + i * 15, string.sub(strTank_volume, i,i),FONT_NORMAL)
	end
	lcd.drawText(140, 38 + #strTank_volume * 15, "ml", FONT_NORMAL)
  
 	collectgarbage()
end

local function draw2Tanks(xleft, value, tank_volume)
	local topbat = 33   
	local highbat = 124
	local strTank_volume = tostring(math.floor(tank_volume))
	-- Tank
	lcd.drawFilledRectangle(xleft-2, topbat, 2, highbat)
	lcd.drawFilledRectangle(xleft+24, topbat, 2, highbat)
	lcd.drawFilledRectangle(xleft-2,157, 28, 2)

	-- Level of fuel
	local chgH = value * highbat // 100
	local chgY = 157 - chgH
	local chgHalarm = vars.config.capacity_alarm_thresh * highbat // 100
	local chgHalarm2 = vars.config.capacity_alarm_thresh2 * highbat // 100
	
	if value <= vars.config.capacity_alarm_thresh then
		chgHalarm = chgH
		chgHalarm2 = chgH
		if system.getTime() % 2 == 0 then
			lcd.setColor(250,0,0) -- rot
			drawPercent2(xleft,value)
		end
	elseif value <= vars.config.capacity_alarm_thresh2 then 
		chgHalarm2 = chgH
		if system.getTime() % 4 ~= 0 then
			lcd.setColor(250,250,0) -- gelb
			drawPercent2(xleft,value) 
		end
	else
		lcd.setColor(colr,colg,colb) --grün
		drawPercent2(xleft,value)
	end

	local chgYalarm = 157 - chgHalarm
	local chgYalarm2 = 157 - chgHalarm2
	  
	lcd.setColor(colr,colg,colb)
	lcd.drawFilledRectangle(xleft, chgY, 24, chgH) --grün
	lcd.setColor(250,250,0)
	lcd.drawFilledRectangle(xleft, chgYalarm2, 24, chgHalarm2) --gelb
	lcd.setColor(250,0,0)
	lcd.drawFilledRectangle(xleft, chgYalarm, 24, chgHalarm) --rot
	lcd.setColor(txtr,txtg,txtb)
	
	-- Höhenmarkierungen
	lcd.drawFilledRectangle(xleft, 95, 7, 2)
	lcd.drawFilledRectangle(xleft+17, 95, 7, 2)
	lcd.drawFilledRectangle(xleft, 64, 5, 1)
	lcd.drawFilledRectangle(xleft+19, 64, 5, 1)
	lcd.drawFilledRectangle(xleft, 126, 5, 1)
	lcd.drawFilledRectangle(xleft+19, 126, 5, 1)
	
	 -- Text in Tank
	for i = 1, #strTank_volume do
		lcd.drawText(xleft+8,92 - i * 15, string.sub(strTank_volume, -i,-i),FONT_NORMAL)
	end
	lcd.drawText(xleft+5, 97, "ml", FONT_MINI)
	
 	collectgarbage()
end

function drawfunc.draw1stTank()
	draw2Tanks(133,vars.remaining_fuel_percent1,vars.config.tank_volume1)
end

function drawfunc.draw2ndTank()  
	draw2Tanks(162,vars.remaining_fuel_percent2,vars.config.tank_volume2)
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
		--sec = vars.totalFlighttime % 60
		
		--lcd.drawText(xStart + 122 - lcd.getTextWidth(FONT_MINI, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_MINI) -- total Flight time	
		lcd.drawText(xStart + 120 - lcd.getTextWidth(FONT_MINI, string.format("%0dh %02d'", std, min)), y, string.format("%0dh %02d'",std, min), FONT_MINI) -- total Flight time	

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
		lcd.drawText(xStart + 124 - lcd.getTextWidth(FONT_BIG, string.format("%0dh %02d' %02d\"", std, min, sec)), y, string.format("%0dh %02d' %02d\"",std, min, sec), FONT_BIG) -- Flight time
	else
		lcd.drawText(xStart + 124 - lcd.getTextWidth(FONT_BIG, string.format("%02d' %02d\"",min, sec)), y, string.format("%02d' %02d\"",min, sec), FONT_BIG) -- Flight time
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
local function drawVolt_per_Cell(batID, battery_voltage_average_perc, minvperc)    -- Flightpack Voltage
	-- draw fixed Text
	lcd.drawText(xStart + 120 - (lcd.getTextWidth(FONT_MINI,vars.trans.mainbat)),yStart-2,vars.trans.mainbat,FONT_MINI)  
	lcd.drawText(xStart + 43,yStart-2,batID,FONT_MINI)
	lcd.drawText(xStart, yStart+ 14, "min:", FONT_MINI)
	--lcd.drawText(xStart + 51, yStart-2 + 18, "V", FONT_MINI)
	lcd.drawText(xStart + 63, yStart+14, "akt:", FONT_MINI)
	--lcd.drawText(xStart + 111, yStart-2 + 18, "V", FONT_MINI)
	
	-- draw Values, average is average of last 1000 values
	deci = "%.2f"
	if minvperc >= 10.0 then deci = "%.1f" end
	if minvperc <= vars.config.voltage_alarm_thresh / 100 then lcd.setColor(alarmr, alarmg, alarmb) else lcd.setColor(minr, ming, minb) end
	lcd.drawText(xStart + 60 - lcd.getTextWidth(FONT_BIG, string.format(deci, minvperc)),yStart+6, string.format(deci, minvperc), FONT_BIG)
	lcd.setColor(txtr,txtg,txtb)
	deci = "%.2f"
	if battery_voltage_average_perc >= 10.0 then deci = "%.1f" end
	if battery_voltage_average_perc <= vars.config.voltage_alarm_thresh / 100 then lcd.setColor(alarmr, alarmg, alarmb) end
	lcd.drawText(xStart + 119 - lcd.getTextWidth(FONT_BIG, string.format(deci, battery_voltage_average_perc)),yStart+6, string.format(deci, battery_voltage_average_perc), FONT_BIG)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.Volt_per_Cell()
	drawVolt_per_Cell(vars.Akkus[vars.Akku1].ID, vars.ak[1].battery_voltage_average / vars.Akkus[vars.Akku1].iCells, vars.ak[1].minVoltpC)
end

function drawfunc.Volt_per_Cell_2()
	drawVolt_per_Cell(vars.Akkus[vars.Akku2].ID, vars.ak[2].battery_voltage_average / vars.Akkus[vars.Akku2].iCells, vars.ak[2].minVoltpC)
end

--- Used Capacity
local function drawUsedCapacity(AkkuNr, value)	-- Used Capacity
	if value <= vars.config.capacity_alarm_thresh then
		lcd.setColor(250,0,0) -- rot
		lcd.drawRectangle(xStart-1, yStart+1 - ybd2, lengthBox-2, 33 + yborder, 3)
		lcd.drawFilledRectangle(xStart, yStart-1, lengthBox-4, 31+yborder)
		lcd.setColor(txtr,txtg,txtb)			
	elseif value <= vars.config.capacity_alarm_thresh2 then 
		lcd.setColor(250,250,0) -- gelb
		lcd.drawRectangle(xStart-1, yStart+1 - ybd2, lengthBox-2, 33 + yborder, 3)
		lcd.drawFilledRectangle(xStart, yStart-1, lengthBox-4, 31+yborder)
		lcd.setColor(txtr,txtg,txtb)
	end
	-- draw fixed Text
	lcd.drawText(xStart + 1, yStart-2, vars.trans.usedCapa..vars.Akkus[AkkuNr].ID, FONT_MINI)
	lcd.drawText(xStart + 96, yStart+18, "mAh", FONT_MINI)
	
	local used_cap = string.format("%.f",(1 - value / 100) * vars.Akkus[AkkuNr].Capacity)
	-- draw Values
	lcd.drawText(xStart + 94 - lcd.getTextWidth(FONT_MAXI, used_cap ), yStart+3, used_cap, FONT_MAXI)
	collectgarbage()
end

function drawfunc.UsedCapacity()
	drawUsedCapacity(vars.Akku1, vars.remaining_capacity_percent1)
end

function drawfunc.UsedCapacity_2()
	drawUsedCapacity(vars.Akku2, vars.remaining_capacity_percent2)
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
local function draw_rpm(label,value,max)	-- Rotor Speed RPM
	lcd.drawText(xStart + 113, yStart + 3, "-1", FONT_MINI)
	lcd.drawText(xStart + 103, yStart + 13, "min", FONT_MINI)
	lcd.drawText(xStart + 99, yStart + 26, "max", FONT_MINI)
	lcd.drawText(xStart, yStart + 26, label, FONT_MINI)
	-- draw Values
	if value > 99999 then 
		value = value / 1000
		max = max / 1000
		deci = "%.fk"
	else
		deci = "%.f"
	end
	lcd.drawText(xStart + 101 - lcd.getTextWidth(FONT_MAXI,string.format(deci,value)),yStart-9,string.format(deci,value),FONT_MAXI)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 96 - lcd.getTextWidth(FONT_MINI,string.format(deci,max)),yStart + 26, string.format(deci, max), FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)	
end

function drawfunc.RPM()	-- Rotor Speed RPM
	draw_rpm(vars.trans.label_RPM, vars.Value.rotor_rpm_sens, vars.drawVal.rotor_rpm_sens.max )
end

function drawfunc.RPM_2()	-- Rotor Speed RPM
	draw_rpm(vars.trans.label_RPM_2, vars.Value.rpm2_sens * vars.config.rpm2_faktor / 100, vars.drawVal.rpm2_sens.max * vars.config.rpm2_faktor / 100)
end

-- Draw current box
local function draw_current(label,sens) -- current
	-- draw fixed Text
	lcd.drawText(xStart, yStart-4, "I", FONT_BIG)
	lcd.drawText(xStart + 7, yStart + 4, label, FONT_MINI)
	lcd.drawText(xStart + 89, yStart + 4, "A", FONT_MINI)
	lcd.drawText(xStart + 98, yStart-4, "max:", FONT_MINI)
	-- draw current 
	deci = "%.1f"
	if vars.Value.motor_current_sens >= 100 then deci = "%.f" end
	lcd.drawText(xStart + 88 - lcd.getTextWidth(FONT_BIG, string.format(deci,vars.Value[sens])),yStart-4, string.format(deci,vars.Value[sens]),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 112 - lcd.getTextWidth(FONT_MINI, string.format("%.fA",vars.drawVal[sens].max)) / 2,yStart + 6, string.format("%.fA",vars.drawVal[sens].max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.Current() -- current
	draw_current("Motor:", "motor_current_sens")
end

function drawfunc.Current_2() -- current
	draw_current("Motor 2:", "motor_current2_sens")
end

-- Draw smal box
local function draw_smal_max(label, einheit, sens)	
	-- draw fixed Text
	lcd.drawText(xStart,yStart+1, label, FONT_MINI)
	lcd.drawText(xStart + 84,yStart+4,einheit,FONT_MINI)
	lcd.drawText(xStart + 99,yStart-4, "max:", FONT_MINI)
	-- draw Values  
	lcd.drawText(xStart + 82 - lcd.getTextWidth(FONT_BIG, string.format("%.f",vars.Value[sens])),yStart-4, string.format("%.f",vars.Value[sens]),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	deci = "%.f"..einheit
	lcd.drawText(xStart + 113 - lcd.getTextWidth(FONT_MINI, string.format(deci,vars.drawVal[sens].max)) / 2,yStart+6, string.format(deci,vars.drawVal[sens].max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.Temp()	-- Temperature
	draw_smal_max(vars.trans.label_Temp, "°C", "Temp_sens")
end

function drawfunc.Temp_2()  -- Temperature 2
	draw_smal_max(vars.trans.label_Temp_2, "°C", "Temp2_sens")
end

function drawfunc.FET_Temp()  -- FET-Temperature
	draw_smal_max(vars.trans.label_fet_Temp, "°C", "fet_temp_sens")
end

function drawfunc.I_BEC()	-- Ibec
	draw_smal_max("IBEC:", "A", "bec_current_sens")
end

local function draw_smal_percent(label, sens)
	-- draw fixed Text
	lcd.drawText(xStart,yStart+1, label, FONT_MINI)
	lcd.drawText(xStart + 85,yStart+4,"%",FONT_MINI)
	lcd.drawText(xStart + 99,yStart-4, "max:", FONT_MINI)
	-- draw Values  
	lcd.drawText(xStart + 83 - lcd.getTextWidth(FONT_BIG, string.format("%.f",vars.Value[sens])),yStart-4, string.format("%.f",vars.Value[sens]),FONT_BIG)
	lcd.setColor(maxr, maxg, maxb)
	lcd.drawText(xStart + 113 - lcd.getTextWidth(FONT_MINI, string.format("%.f%%",vars.drawVal[sens].max)) / 2,yStart+6, string.format("%.f%%",vars.drawVal[sens].max),FONT_MINI)
	lcd.setColor(txtr,txtg,txtb)
end

function drawfunc.PWM()	-- PWM
	draw_smal_percent("PWM:", "pwm_percent_sens")
end

function drawfunc.Throttle()	-- Throttle
	draw_smal_percent("Throttle:", "throttle_sens")
end

function drawfunc.Vibes() -- Vibes
	draw_smal_percent(vars.trans.vibes_sens,"vibes_sens")
end

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
local function usedCap(Akku, UsedCap_sens) 
	local y = yStart -2
	local lbat= 103
	local xbat = xStart+15
	
	if vars.Akkus[Akku].ID > 0 then	
		-- ID
		lcd.drawText(xStart+13-lcd.getTextWidth(FONT_MINI, vars.Akkus[Akku].ID) ,y+4, vars.Akkus[Akku].ID,FONT_MINI)
		if vars.Akkus[Akku].Capacity > 0 then
			local usedCapP = 100 - vars.Value[UsedCap_sens] / vars.Akkus[Akku].Capacity * 100
			local l_usedCap = lcd.getTextWidth(FONT_BOLD, string.format("%.f%%",usedCapP))
			lbat = lbat - l_usedCap
			lcd.setColor(0,220,0)
			lcd.drawFilledRectangle(xbat+1,y+3, (lbat-2)*usedCapP/100, 14)
			lcd.setColor(txtr,txtg,txtb)
			lcd.drawText(xStart+124-l_usedCap,y,string.format("%.f%%",usedCapP),FONT_BOLD)
		end
	else
		xbat = xbat-13
		lbat = lbat+13
	end
	lcd.drawRectangle(xbat,y+2, lbat, 16)
	lcd.drawFilledRectangle(xbat+lbat,y+5, 4, 10)	-- top of Battery
	lcd.drawText(xbat + lbat/2 - (lcd.getTextWidth(FONT_MINI, string.format("%.f mAh",vars.Value[UsedCap_sens]))/2),y+4, string.format("%.f mAh",vars.Value[UsedCap_sens]),FONT_MINI)
end

function drawfunc.used_Cap1()
	usedCap(vars.Akku3, "UsedCap1_sens")
end

function drawfunc.used_Cap2()
	usedCap(vars.Akku4,"UsedCap2_sens")
end

function drawfunc.weakest_Cell()
	local y = yStart
	local x = xStart+20
	local checkedCells = string.format("%.f",vars.Value.checkedCells_sens)..vars.trans.of..string.format("%.f",vars.Akkus[vars.Akku1].iCells) ..vars.trans.checked
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


local function showDisplay(page)
	local ySep, yBox
	--lcd.setColor(txtr,txtg,txtb)
	--left:	
	lengthSep = 127
	lengthBox = 129
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
	
--------------	
	--right
	lengthSep = 126
	lengthBox = 128
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
	
	-- middle
	for i,j in ipairs(vars.middle) do
		colr = vars.col[page][i][1]
		colg = vars.col[page][i][2]
		colb = vars.col[page][i][3]
		drawfunc[j](i)
	end
	
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
	if varstemp then 
		vars = varstemp 
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
						
-- Count percentage from cell voltage
local function get_capacity_percent_used(cell_voltage)
	local result=0
	if vars.config.calcAkkuCond == 1 then
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

local function batIDchanged(AkkuNr, iAkku, Voltsens, Capsens)
	local ruc
	dbdis_capacity = vars.Akkus[vars.Akku1].Capacity
	if vars.ak[iAkku].lastUsedCapacity == 0 then 
		vars.ak[iAkku].lastUsedCapacity = vars.Akkus[AkkuNr].usedCapacity
	end 
	if vars.ak[iAkku].AkkuwasFull then
		vars.ak[iAkku].usedAkku = false
		vars.ak[iAkku].lastUsedCapacity = 0
	else
		if vars.ak[iAkku].usedAkku  then -- Akku war nicht voll und usedCapacity > 0 oder der Akku wurde bereits gespeichert
			if vars.Akkus[AkkuNr].usedCapacity == 0 then -- jetzt usedCapacity = 0
				if (vars.Value[Voltsens] / vars.Akkus[AkkuNr].iCells) > 1.1  then
					vars.ak[iAkku].initial_capacity_percent_used = get_capacity_percent_used(vars.Value[Voltsens] / vars.Akkus[AkkuNr].iCells)
					system.messageBox("Init. used cap.:"..string.format("%.fmAh",vars.ak[iAkku].initial_capacity_percent_used * vars.Akkus[AkkuNr].Capacity / 100) ,5)
					if vars.Akkus[AkkuNr].Capacity > 0 then 
						if vars.iEngines == 2 and #vars.iAkkus == 1 then
							ruc = vars.ak[1].resetusedcapacity + vars.ak[2].resetusedcapacity
						else
							ruc = vars.ak[iAkku].resetusedcapacity
						end
						vars.ak[iAkku].initial_capacity_percent_used  = vars.ak[iAkku].initial_capacity_percent_used - (vars.Value[Capsens] - ruc)/vars.Akkus[AkkuNr].Capacity * 100
					end
				end
				vars.ak[iAkku].lastUsedCapacity = 0
				vars.ak[iAkku].usedAkku = false
			else --jetzt usedCapacity > 0
				vars.ak[iAkku].lastUsedCapacity = vars.Akkus[AkkuNr].usedCapacity 
			end
		else -- Akku war nicht voll und usedCapacity = 0
			if vars.Akkus[AkkuNr].usedCapacity > 0 then -- jetzt usedCapacity > 0
				vars.ak[iAkku].lastUsedCapacity = vars.Akkus[AkkuNr].usedCapacity
				vars.ak[iAkku].initial_capacity_percent_used = 0
				vars.ak[iAkku].usedAkku = true
			else
				vars.ak[iAkku].lastUsedCapacity = 0
			end
		end
	end
	vars.ak[iAkku].minVoltpC = vars.Value[Voltsens] / vars.Akkus[AkkuNr].iCells
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
	vars.drawVal.battery_voltage2_sens.min = 0
	vars.drawVal.battery_voltage2_sens.measured = false
	
	vars.drawVal.weakVoltage_sens.min = 0
	vars.drawVal.weakVoltage_sens.measured = false
	vars.drawVal.weakCell_sens.min = 0
	vars.drawVal.deltaVoltage_sens.min = 0
	vars.drawVal.weakPack = 0
	vars.drawVal.weakPackmin = 0
	
	vars.Value.status_sens = "No Status"
	vars.Value.status2_sens = "No Status"
	
	vars.SWold_Akku = -2

	vars.ak[1].battery_voltage_average = 0
	vars.ak[2].battery_voltage_average = 0
	vars.ak[1].last_averaging_time = 0
	vars.ak[2].last_averaging_time = 0
	vars.ak[1].minVoltpC = 0
	vars.ak[2].minVoltpC = 0
	
	vars.ak[1].RfID = -1
	vars.ak[2].RfID = -1
	if vars.receiverOn then 
		if vars.senslbl.batID_sens then
			vars.ak[1].RfID = -2 	--reset switch
		end
		if vars.senslbl.batID2_sens then 
			vars.ak[2].RfID = -2   --reset switch
		end
	end
	
		--Akkudaten neu laden:
	if not vars.AkkusID[vars.config.Akku1ID] then
		vars.config.Akku1ID = 0
	end
	if not vars.AkkusID[vars.config.Akku2ID] then
		vars.config.Akku2ID = 0
	end
	vars.Akku1 = vars.AkkusID[vars.config.Akku1ID]
	vars.Akku2 = vars.AkkusID[vars.config.Akku2ID]
	batIDchanged(vars.Akku1, 1, "battery_voltage_sens", "used_capacity_sens")
	batIDchanged(vars.Akku2, 2, "battery_voltage2_sens", "used_capacity2_sens")
	
	vars.flightTime = 0
	vars.engineTime = 0
	vars.counttheFlight = false
    vars.counttheTime = false  
	vars.countedTime = 0
	vars.lastFlightTime = 0
	
	imainAlarm = 0
	ipreAlarm = 0
	iVoltageAlarm = 0
	calcaApp = false
	
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
	vars.Value.batID2_sens = 0
	--vars.Value.used_capacity_sens = 0
	--vars.Value.battery_voltage_sens = 0
	
	vars.ak = {}
	for i=1,2 do
		vars.ak[i] = {}
		vars.ak[i].initial_capacity_percent_used = 0
		vars.ak[i].resetusedcapacity = 0
		vars.ak[i].lastUsedCapacity = 0
		vars.ak[i].usedAkku = false
		vars.ak[i].AkkuwasFull = false
		vars.ak[i].RfID = 0
	end
	
	vars.remaining_capacity_percent1 = 100
	vars.remaining_capacity_percent2 = 100
	vars.remaining_fuel_percent1 = 0
	vars.remaining_fuel_percent2 = 0
	vars.tankRatio = 1
	
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
	local usedcap = 0
	local Akku
	local logbat = {}
	logbat[1] = string.format(";% 3d;% 6d;% 9d;%  .2f;% 5d", 0, 0, 0, 0, 0)
	logbat[2] = string.format(";% 3d;% 6d;% 9d;%  .2f;% 5d", 0, 0, 0, 0, 0)
	
	
	for i,j in ipairs(vars.iAkkus) do
		Akku = vars.Akkus[vars["Akku"..j]]
		if (vars.ak[i].battery_voltage_average / Akku.iCells * 100) < vars.config.AkkuUsed then -- Akku wurde gebraucht
			if (vars.ak[i].AkkuwasFull and not vars.ak[i].usedAkku) then 
				Akku.Cycl = Akku.Cycl + 1
				Akku.usedCapacity = 0
				vars.ak[i].usedAkku = true
				vars.ak[i].AkkuwasFull = false
			end 
			if vars.iEngines == 2 and #vars.iAkkus == 1 then
				usedcap = vars.Value.used_capacity_sens + vars.Value.used_capacity2_sens - vars.ak[1].resetusedcapacity - vars.ak[2].resetusedcapacity
				vars.ak[1].resetusedcapacity = vars.Value.used_capacity_sens
				vars.ak[2].resetusedcapacity = vars.Value.used_capacity2_sens
			else
				usedcap = vars.Value["used_capacity"..sens12[j]] - vars.ak[i].resetusedcapacity
				vars.ak[i].resetusedcapacity = vars.Value["used_capacity"..sens12[j]]	
			end
			Akku.Ah = Akku.Ah + (usedcap / 1000)
			vars.ak[i].lastUsedCapacity = Akku.usedCapacity + usedcap
			Akku.usedCapacity = vars.ak[i].lastUsedCapacity	
			logbat[i] = string.format(";% 3d;% 6d;% 9d;%  .2f;% 5d", Akku.ID, Akku.Cycl, usedcap, vars.ak[i].minVoltpC, vars.drawVal["motor_current"..sens12[j]].max)
			saveAkkus()
		end	
	end
		
	-- write logfile
	local dtflighttime = string.format("%4d:%02d:%02d", vars.flightTime // 3600000, (vars.flightTime % 3600000) / 60000, (vars.flightTime % 60000) / 1000)
	local dtengineTime = string.format("%4d:%02d:%02d", vars.engineTime // 3600000, (vars.engineTime % 3600000) / 60000, (vars.engineTime % 60000) / 1000)
	local dttotalFlighttime = string.format("%4d:%02d:%02d", vars.totalFlighttime // 3600, (vars.totalFlighttime % 3600) / 60, vars.totalFlighttime % 60)
    local dt = system.getDateTime()
    local dtDate = string.format("%02d.%02d.%02d", dt.year, dt.mon, dt.day)
	local dtTime = string.format("%02d:%02d", dt.hour, dt.min)
	
    local logline = string.format("%s;%s;%15s;%4s;%4s;%s;%s", dtDate, dtTime, vars.model, math.floor(vars.totalCount), dttotalFlighttime, dtflighttime, dtengineTime)
	if vars.iAkkus[1] then
		logline = logline..logbat[1] 
	end
	if vars.iTanks[1] then
		logline = logline..logbat[1]..string.format(";% 5d", (100 - vars["remaining_fuel_percent"..vars.iTanks[1]]) * vars.config.tank_volume1 / vars.tankRatio // 100)
	end
	if vars.iAkkus[2] then
		logline = logline.."    0"..logbat[2]
	end
	if vars.iTanks[2] then
		logline = logline..logbat[2]..string.format(";% 5d", (100 - vars.remaining_fuel_percent2) * vars.config.tank_volume2 // 100)
	end
	
	local fn = vars.appName.."_Log.txt"        
	local header = true
	local fwriteLog = io.open(fn,"r")
	if fwriteLog then 
		header = false 
		io.close(fwriteLog)
	end  
    fwriteLog = io.open(fn,"a")
    if(fwriteLog) then
		if header then io.write(fwriteLog,vars.trans.header) end
        io.write(fwriteLog, logline,"\n")
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
 
local function accuvalues(AkkuNr, RfID)
	vars.ak[AkkuNr].RfID = RfID
	if  not vars.AkkusID[RfID] then
		i = #vars.Akkus + 1
		vars.Akkus[i] = {}
		vars.Akkus[i].ID = RfID
		vars.Akkus[i].Name = ""
		vars.Akkus[i].Cycl = 0
		vars.Akkus[i].Ah = 0
		vars.Akkus[i].usedCapacity = 0
		vars.Akkus[i].batC = 0
		vars.Akkus[i].Capacity = 0
		vars.Akkus[i].iCells = 1		
		vars.ak[AkkuNr].lastUsedCapacity = 0
		saveAkkus()	
	end
	
	if AkkuNr == 1 then 
		-- -- C-Rate von Rfid
		-- if vars.Value.batC_sens and vars.Value.batC_sens > 0 then vars.Akkus[Akku1].batC = vars.Value.batC_sens end
		-- -- Kapazität von Rfid
		-- if vars.Value.batCap_sens and vars.Value.batCap_sens > 0 then vars.Akkus[Akku1].Capacity = vars.Value.batCap_sens end
		-- -- Zellenzahl von Rfid
		-- if vars.Value.batCells_sens and vars.Value.batCells_sens > 0 then vars.Akkus[Akku1].iCells = vars.Value.batCells_sens end
		vars.Akku1 = vars.AkkusID[RfID]
		batIDchanged(vars.Akku1, 1, "battery_voltage_sens", "used_capacity_sens")
		dbdis_capacity = vars.Akkus[vars.Akku1].Capacity		
	else 
		vars.Akku2 = vars.AkkusID[RfID]
		batIDchanged(vars.Akku2, 2, "battery_voltage2_sens", "used_capacity2_sens")
	end
end
 
local function battery_voltage_sens(Voltsens, Capsens, AkkuNr, iAkku)
	local initial_cell_voltage
	local cell_voltage
	local ruc
	if vars.drawVal[Voltsens].valid then
	-- guess used capacity from voltage if we started with partially discharged battery 
		cell_voltage = vars.Value[Voltsens] / vars.Akkus[AkkuNr].iCells
		if not vars.drawVal[Voltsens].measured then
			if cell_voltage > 1.1 then 
				vars.drawVal[Voltsens].measured = true
				next_voltage_alarm = tickTime + 2
				iVoltageAlarm = 0
				initial_cell_voltage = cell_voltage
				vars.ak[iAkku].minVoltpC = cell_voltage
				if initial_cell_voltage * 100 < vars.config.AkkuFull then
					vars.ak[iAkku].AkkuwasFull = false
				else 
					vars.ak[iAkku].AkkuwasFull = true
				end
				if vars.ak[iAkku].AkkuwasFull or (not vars.ak[iAkku].AkkuwasFull and vars.ak[iAkku].lastUsedCapacity == 0) then
					vars.ak[iAkku].initial_capacity_percent_used = get_capacity_percent_used(initial_cell_voltage)
					system.messageBox("Init. used cap.:"..string.format("%.fmAh",vars.ak[iAkku].initial_capacity_percent_used*vars.Akkus[AkkuNr].Capacity/100) ,5)
					if vars.Akkus[AkkuNr].Capacity > 0 then 
						if vars.iEngines == 2 and #vars.iAkkus == 1 then
							ruc = vars.ak[1].resetusedcapacity + vars.ak[2].resetusedcapacity
						else
							ruc = vars.ak[iAkku].resetusedcapacity
						end
						vars.ak[iAkku].initial_capacity_percent_used = vars.ak[iAkku].initial_capacity_percent_used - (vars.Value[Capsens] - ruc)/vars.Akkus[AkkuNr].Capacity*100
					end
					vars.ak[iAkku].lastUsedCapacity = 0
					vars.ak[iAkku].usedAkku = false
				end
			else
				vars.ak[iAkku].initial_capacity_percent_used = 0
			end  
		elseif cell_voltage < vars.ak[iAkku].minVoltpC then 
			vars.ak[iAkku].minVoltpC = cell_voltage
		end
				
		if newTime > (vars.ak[iAkku].last_averaging_time + 400) then          -- one second period (1000), newTime set from FlightTime()
			vars.ak[iAkku].battery_voltage_average = average(vars.Value[Voltsens])   -- average voltages over n samples
			vars.ak[iAkku].last_averaging_time = newTime
		end
		
		if ((vars.drawVal[Voltsens].measured and (vars.ak[iAkku].battery_voltage_average / vars.Akkus[AkkuNr].iCells) <= vars.config.voltage_alarm_thresh/100) or (vars.drawVal.weakVoltage_sens.measured and vars.Value.weakVoltage_sens <= vars.config.voltage_alarm_thresh/100)) and vars.config.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime and iVoltageAlarm < vars.config.imaxVoltAlarm then
			system.messageBox(vars.trans.voltWarn,2)
			system.playFile(vars.config.voltage_alarm_voice,AUDIO_QUEUE)
			iVoltageAlarm = iVoltageAlarm + 1
			next_voltage_alarm = tickTime + 5 -- battery voltage alarm every 4 second 
		end  
		
		if(anVoltGo == 1 and tickTime >= next_voltage_announcement) then
			system.playNumber(cell_voltage, 1, "V", "U Battery")
			next_voltage_announcement = tickTime + 10 -- say battery voltage every 10 seconds
		end
	else
		vars.ak[iAkku].battery_voltage_average = 0
		vars.drawVal[Voltsens].measured = false
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


-- function calcfunc.remaining_fuel_percent_sens()
	-- if not vars.senslbl.remaining_fuel_percent2_sens then
		-- vars.remaining_fuel_percent1 = 100 - vars.tankRatio * (100 - vars.Value.remaining_fuel_percent_sens)
		-- rfp_min = math.max(0, vars.remaining_fuel_percent1)
	-- end
	-- print("1:"..vars.remaining_fuel_percent1)
-- end

-- function calcfunc.remaining_fuel_percent2_sens()
	-- vars.remaining_fuel_percent2 = 100 - vars.tankRatio2 * (100 - vars.Value.remaining_fuel_percent2_sens)
	-- rfp_min = math.max(0, vars.remaining_fuel_percent2)
	
	-- if vars.senslbl.remaining_fuel_percent_sens then
		-- rfp_min = math.min(vars.remaining_fuel_percent1, vars.remaining_fuel_percent2)
		-- if #vars.iTanks == 1 then
			-- vars.remaining_fuel_percent1 = math.max(0, 100 - vars.tankRatio * (200 - vars.Value.remaining_fuel_percent_sens - vars.Value.remaining_fuel_percent2_sens))
			-- print("2:"..vars.remaining_fuel_percent1)
			-- rfp_min = math.max(0, vars.remaining_fuel_percent1)
		-- end
	-- end
-- end


function calcfunc.remaining_fuel_percent_sens()
	if vars.senslbl.remaining_fuel_percent2_sens and #vars.iTanks == 1 then
		vars.remaining_fuel_percent1 = math.max(0, 100 - vars.tankRatio * (200 - vars.Value.remaining_fuel_percent_sens - vars.Value.remaining_fuel_percent2_sens))
	else
		vars.remaining_fuel_percent1 = 100 - vars.tankRatio * (100 - vars.Value.remaining_fuel_percent_sens)
	end
	rfp_min = math.max(0, vars.remaining_fuel_percent1)
end

function calcfunc.remaining_fuel_percent2_sens()
	vars.remaining_fuel_percent2 = 100 - vars.tankRatio2 * (100 - vars.Value.remaining_fuel_percent2_sens)
	if vars.senslbl.remaining_fuel_percent_sens then
		rfp_min = math.min(vars.remaining_fuel_percent1, vars.remaining_fuel_percent2)
	else
		rfp_min = math.max(0, vars.remaining_fuel_percent2)
	end
end

function calcfunc.usedCap1()
	if vars.Akkus[vars.Akku1].Capacity > 0 then
		if vars.iEngines == 2 and #vars.iAkkus == 1 then
			vars.remaining_capacity_percent1 = math.max(0, (vars.Akkus[vars.Akku1].Capacity - vars.Value.used_capacity_sens - vars.Value.used_capacity2_sens + vars.ak[1].resetusedcapacity + vars.ak[2].resetusedcapacity - vars.ak[1].lastUsedCapacity) * 100 / vars.Akkus[vars.Akku1].Capacity - vars.ak[1].initial_capacity_percent_used)
		else
			vars.remaining_capacity_percent1 = math.max(0, (vars.Akkus[vars.Akku1].Capacity - vars.Value.used_capacity_sens + vars.ak[1].resetusedcapacity - vars.ak[1].lastUsedCapacity) * 100 / vars.Akkus[vars.Akku1].Capacity - vars.ak[1].initial_capacity_percent_used)
		end
		rcp_min = vars.remaining_capacity_percent1
	end
end

function calcfunc.usedCap2()	
	if vars.Akkus[vars.Akku2].Capacity > 0 then
		vars.remaining_capacity_percent2 = math.max(0, (vars.Akkus[vars.Akku2].Capacity - vars.Value.used_capacity2_sens + vars.ak[2].resetusedcapacity - vars.ak[2].lastUsedCapacity) * 100 / vars.Akkus[vars.Akku2].Capacity - vars.ak[2].initial_capacity_percent_used)
		rcp_min = math.min(vars.remaining_capacity_percent1, vars.remaining_capacity_percent2)
	end
end

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
			if vars.Rx[RxTyp].percent then  --alt: vars.Rx[RxTyp].percent > 99.0
				if not vars.receiverOn then
					itemp = vars.Rx[RxTyp].percent
					calcaApptemp = calcaApp
					init()
					vars.Rx[RxTyp].percent = itemp
					vars.receiverOn = true
					if not vars.senslbl.battery_voltage_sens then  --and calcaApptemp und calcaApp wird nicht mehr benötigt.
						vars.ak[1].AkkuwasFull = true
						vars.ak[1].usedAkku = false
						vars.ak[1].lastUsedCapacity = 0
					end
					if not vars.senslbl.battery_voltage2_sens then 
						vars.ak[2].AkkuwasFull = true
						vars.ak[2].usedAkku = false
						vars.ak[2].lastUsedCapacity = 0
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
			vars.ak[1].RfID = 0
			vars.ak[2].RfID = 0
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
	if resetSw_val == 1 then
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
	
	if vars.ak[1].RfID == -1 then
		if vars.AkkuSW ~= vars.SWold_Akku then
			vars.SWold_Akku = vars.AkkuSW
			if  vars.AkkuSW == 1 then 
				newbatID = vars.config.Akku2ID
				vars.tankRatio = vars.tankRatio2
			else
				newbatID = vars.config.Akku1ID
				vars.tankRatio = 1
			end
			if newbatID == 0 then 
				newbatID = math.max(vars.config.Akku1ID, vars.config.Akku2ID)
			end
		
			if newbatID > 0 and newbatID ~= vars.Akkus[vars.Akku1].ID then
				vars.Akku1 = vars.AkkusID[newbatID]
				batIDchanged(vars.Akku1, 1, "battery_voltage_sens", "used_capacity_sens")
			end	
		end
	end
		
		-- kein Spritsensor zugeordnet
	if not vars.senslbl.remaining_fuel_percent_sens then
		if Calca_dispGas then 
			vars.Value.remaining_fuel_percent_sens = Calca_dispGas
			calcfunc.remaining_fuel_percent_sens()
		end
	end
	
		-- kein Kapazitätssensor zugeordnet
	if not vars.senslbl.used_capacity_sens then
		if Calca_dispFuel then 
			vars.Value.used_capacity_sens = vars.Akkus[vars.Akku1].Capacity * (1 - Calca_dispFuel / 100 )
			calcaApp = true
		else 
			calcaApp = false
		end
	end
	
	
	for i,j in ipairs(vars.iAkkus) do
		calcfunc["usedCap"..j]()
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
		for i,ID in pairs(vars.sensID) do
			if vars.Value[ID] > 0 then
				if vars.ak[i].RfID ~= vars.Value[ID] then accuvalues(i,math.floor(vars.Value[ID])) end
			else
				if vars.ak[i].RfID < 0 then  -- comes from reset switch (zuerst RfID abfragen und dann erst den Akkuschalter abfragen um umschalten zw. den Akkus zu vermeiden)
					vars.ak[i].RfID = -1
				else
					vars.ak[i].RfID = 0
				end
			end
		end
		
		-- min und max Werte abfragen
		for senslbl in pairs(vars.senslbl) do	
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
			battery_voltage_sens("battery_voltage_sens","used_capacity_sens",vars.Akku1, 1)
		else-- kein Spannungssensor zugeordnet
			vars.drawVal.battery_voltage_sens.measured = true 	
		end	
		
		if vars.senslbl.battery_voltage2_sens then
			battery_voltage_sens("battery_voltage2_sens","used_capacity2_sens",vars.Akku2, 2)
		else-- kein Spannungssensor zugeordnet
			vars.drawVal.battery_voltage2_sens.measured = true 	
		end	
		
		-- wenn die verbrauchten mAh manuell zurückgesetzt werden (z.Bsp bei der calcaApp)
		-- math.abs ist nur weil der Spirit Telemetriewert bei Kontronik Reglern manchmal ins negative fällt.
		for i=1,vars.iEngines do
			if math.abs(vars.Value["used_capacity"..sens12[i]]) < vars.ak[i].resetusedcapacity  then  vars.ak[i].resetusedcapacity = vars.Value["used_capacity"..sens12[i]] end
		end
		
		--if vars.Value.used_capacity_sens < vars.ak[1].resetusedcapacity  then  vars.ak[1].resetusedcapacity = vars.Value.used_capacity_sens end
		--if vars.Value.used_capacity2_sens < vars.ak[2].resetusedcapacity  then  vars.ak[2].resetusedcapacity = vars.Value.used_capacity2_sens end
		
		---Alarme:
		--vars.remaining_capacity_percent1 alarm
		if rcp_min > 0 and next_capacity_alarm < tickTime then
			if imainAlarm < vars.config.imaxMainAlarm and rcp_min <= vars.config.capacity_alarm_thresh then
				if vars.config.capacity_alarm_voice == "..." then
					system.playNumber(rcp_min, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				imainAlarm = imainAlarm + 1
				if imainAlarm == vars.config.imaxMainAlarm then ipreAlarm = vars.config.imaxPreAlarm end
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			elseif ipreAlarm < vars.config.imaxPreAlarm and rcp_min <= vars.config.capacity_alarm_thresh2 then
				if vars.config.capacity_alarm_voice2 == "..." then
					system.playNumber(rcp_min, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice2,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.capaWarn,2)
				ipreAlarm = ipreAlarm + 1
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			end
		end
		
		--remaining_fuel_percent_sens alarm
		if rfp_min > 0 and next_capacity_alarm < tickTime then
			if imainAlarm < vars.config.imaxMainAlarm and rfp_min <= vars.config.capacity_alarm_thresh then
				if vars.config.capacity_alarm_voice == "..." then
					system.playNumber(rfp_min, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.fuelWarn,2)
				imainAlarm = imainAlarm + 1
				if imainAlarm == vars.config.imaxMainAlarm then ipreAlarm = vars.config.imaxPreAlarm end
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			elseif ipreAlarm < vars.config.imaxPreAlarm and rfp_min <= vars.config.capacity_alarm_thresh2 then
				if vars.config.capacity_alarm_voice2 == "..." then
					system.playNumber(rfp_min, 0, "%")
				else
					system.playFile(vars.config.capacity_alarm_voice2,AUDIO_QUEUE)
				end
				system.messageBox(vars.trans.fuelWarn,2)
				ipreAlarm = ipreAlarm + 1
				next_capacity_alarm = tickTime + 5 -- battery percentage alarm every 4 seconds
			end
		end
		
		if anCapaGo == 1 and tickTime >= next_capacity_announcement then
			if vars.iTanks[1] then
				system.playNumber(rfp_min, 0, "%")
				next_capacity_announcement = tickTime + 10 -- say fuel percentage every 10 seconds
			end
			if vars.iAkkus[1] then
				system.playNumber(rcp_min, 0, "%")
				next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
			end	
		end
		
		if anCapaValGo == 1 and tickTime >= next_value_announcement then
			if vars.iAkkus[1] then
				rcv_min = vars["remaining_capacity_percent"..vars.iAkkus[1]] * vars.Akkus[vars["Akku"..vars.iAkkus[1]]].Capacity
				if vars.iAkkus[2] then 
					rcv_min = math.min(rcv_min, vars.remaining_capacity_percent2 * vars.Akkus[vars.Akku2].Capacity)
				end
				system.playNumber(rcv_min / 100, 0, "mAh")
				next_value_announcement = tickTime + 10 -- say battery value every 10 seconds
			end
			
			if vars.iTanks[1]  then
				rfv_min = vars["remaining_fuel_percent"..vars.iTanks[1]] * vars.config.tank_volume1 / vars.tankRatio
				if vars.iTanks[2] then 
					rfv_min = math.min(rfv_min, vars.remaining_fuel_percent2 * vars.config.tank_volume2)
				end
				system.playNumber(rfv_min / 100, 0, "ml")
				next_value_announcement = tickTime + 10 -- say fuel value every 10 seconds	
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
