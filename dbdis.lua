--[[
	----------------------------------------------------------------------------
	App using Sensor Data to display in a full screen window
	----------------------------------------------------------------------------
	MIT License
   
	Hiermit wird unentgeltlich jeder Person, die eine Kopie der Software und der
	zugehörigen Dokumentationen (die "Software") erhält, die Erlaubnis erteilt,
	sie uneingeschränkt zu nutzen, inklusive und ohne Ausnahme mit dem Recht, sie
	zu verwenden, zu kopieren, zu verändern, zusammenzufügen, zu veröffentlichen,
	zu verbreiten, zu unterlizenzieren und/oder zu verkaufen, und Personen, denen
	diese Software überlassen wird, diese Rechte zu verschaffen, unter den
	folgenden Bedingungen: 
	Der obige Urheberrechtsvermerk und dieser Erlaubnisvermerk sind in allen Kopien
	oder Teilkopien der Software beizulegen. 
	DIE SOFTWARE WIRD OHNE JEDE AUSDRÜCKLICHE ODER IMPLIZIERTE GARANTIE BEREITGESTELLT,
	EINSCHLIEßLICH DER GARANTIE ZUR BENUTZUNG FÜR DEN VORGESEHENEN ODER EINEM
	BESTIMMTEN ZWECK SOWIE JEGLICHER RECHTSVERLETZUNG, JEDOCH NICHT DARAUF BESCHRÄNKT.
	IN KEINEM FALL SIND DIE AUTOREN ODER COPYRIGHTINHABER FÜR JEGLICHEN SCHADEN ODER
	SONSTIGE ANSPRÜCHE HAFTBAR ZU MACHEN, OB INFOLGE DER ERFÜLLUNG EINES VERTRAGES,
	EINES DELIKTES ODER ANDERS IM ZUSAMMENHANG MIT DER SOFTWARE ODER SONSTIGER
	VERWENDUNG DER SOFTWARE ENTSTANDEN. 
	----------------------------------------------------------------------------


	copied from nichtgedacht Version History: V1.1
	V1.0 initial release
	V1.1 Turbine status and turbine telemetry added
	V1.2 improvement of the timer function:
		- if you activate the reset switch during the timer runs, the actual flight will not count and the timer starts at zero again.
		  if you activate the reset switch during the timer stops, and you have already reached the time limit, the actual flight will be count and the timer starts at zero again an other flight.
		- impliment of the CalCa- Gas and the CalCa-Elec App: If you get values from the app they will be used.
--]]

--[[
Jlog2.6 Telemetry Parameters (Number is Sensor Parameter, quoted Text is Parameter Label):
                                                                                                                                          
Basis                                                                                                                                     
1 “U battery”   nn.n    V   (Akkuspannung)
2 “I motor”     nnn.n   A   (Motorstrom)
3 “RPM uni”     nnnn    rpm (Rotordrehzahl)
4 “mAh”         nnnnn   mAh (verbrauchte Kapazität)
5 “U bec”       n.n     V   (BEC-Ausgangsspannung)
6 “I bec”       nn.n    A   (BEC-Ausgangsstrom)
7 “Throttle”    nnn     %   (Gas 0..100%)
8 “PWM”         nnn     %   (Stelleraussteuerung 0..100%)
9 “Temp         nnn     °C  (Temperatur der Leistungs-FETs (Endstufe), bisher “TempPA” genannt)

+

Configuration 0 setup by JLC5 (Standard):
10 “extTemp1″   [-]nn.n     °C (JLog-eigener (Steller-externer) Temperatursensor 1 (1/5))
11 “extTemp2″   [-]nn.n     °C (JLog-eigener (Steller-externer) Temperatursensor 2 (2/5))
12 “extRPM”     nnnnn       rpm (JLog-eigener (Steller-externer) Drehzahlsensor)
13 “Speed”      nnn         km/h (JLog-eigener Sensor, Prandtl-Sonde (Staurohr) SM#2560)
14 “MaxSpd”     nnn         km/h (Maximalgeschwindigkeit)
15 “RPM mot”    nnnnn       rpm (Motordrehzahl)

or Configuration 1 (selected config) setup by JLC5 (Min/Max-Werte):
10 “RPM mot”    nnnnn   rpm (Motordrehzahl)
11 “Ubat Min”   nn.n    V   (Akkuminimalspannung)
12 “Ubec Min”   n.n     V   (BEC-Minimalspannung)
13 “Imot Max”   nnn.n   A   (Motormaximalstrom)
14 “Ibec Max”   nn.n    A   (BEC-Maximalstrom)
15 “Power Max”  nnnnn   W   (Maximalleistung)
--]]

collectgarbage()
--------------------------------------------------------------------------------
local appName = "dbdis"
local setupvars = {}
local Version = "1.3"
local owner = " ", " "
local Title
--local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local Screen
local trans

local yliDist, yliStart = 0, 0   
local yreDist, yreStart = 0, 0
local maxliDraw, maxreDraw = 0, 0

-- Telemetry Window
local function Window(width, height)
	local xli, xre = 2, 193 -- x Abstand der Anzeigeboxen vom linken Rand
	local lengthSep = 160 - (xre - 160) - xli
  
	
	local xStart = xli
	local yStart = yliStart
	local yDist = yliDist  -- berechneter Abstand zw. den Feldern und Seperatoren
	local iSep = 0   -- Anzahl der Seperatoren mit variablen Abstand
	local iDraw = 0
	local maxDraw = maxliDraw  -- maximale Anzahl der Felder
	
	
	--left:
	-----------------------------------------------------
	-- hier die Zeilen für die linken Felder in die Reihenfolge bringen wie sie angezeigt werden sollen: (die Zeilen können auch zw. li. und re. hin und her kopiert werden)
	-- der Wert nach iSep bestimmt die Dicke der Trennlinie (0 = keine Trennlinie)
	-- die letzten beiden Werte bestimmen den Abstand zw. den Feldern:
	-- z. Bsp.: ..., 2, false) bedeutet der Abstand zum nächsten Feld sind 2 Punkte
	-- oder ..., yDist, true) beudet der Abstand zum nächsten Feld wird berechnet und gleichmäßig aufgeteilt
	yStart, iDraw, iSep = Screen.drawTotalCount(iDraw, maxDraw, iSep, 0, lengthSep, xStart, yStart, yDist, true) -- TotalTime
	yStart, iDraw, iSep = Screen.drawFlightTime(iDraw, maxDraw, iSep, 0, lengthSep, xStart, yStart, yDist, true)  -- FlightTime
	yStart, iDraw, iSep = Screen.drawEngineTime(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true)  -- EngineTime
	yStart, iDraw, iSep = Screen.drawRxValues(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true)	-- Rx values
	yStart, iDraw, iSep = Screen.drawrpmbox(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true)    -- rpm
	yStart, iDraw, iSep = Screen.drawHeight(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, yDist, true)   -- height
	yStart, iDraw, iSep = Screen.drawVario(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true)   -- vario
	yStart, iDraw, iSep = Screen.drawStatusbox(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, yDist, true)    -- Status
	
	------------------------------------------------------
	 	 
	maxliDraw = iDraw
	yliDist = math.floor((160 - yStart + yliStart + iSep * yliDist) / (iSep + 2))
	yliStart = math.floor((160 - (yStart - yliStart)) / 2)
		
	xStart = xre
	yStart = yreStart
	yDist = yreDist
	iSep = 0
	iDraw = 0
	maxDraw = maxreDraw

	--right
	----------------------------------------------------------
	-- hier die Zeilen für die rechten Felder in die Reihenfolge bringen wie sie angezeigt werden sollen: (die Zeilen können auch zw. li. und re. hin und her kopiert werden)
	-- der Wert nach iSep bestimmt die Dicke der Trennlinie (0 = keine Trennlinie)
	-- die letzten beiden Werte bestimmen den Abstand zw. den Feldern:
	-- z. Bsp.: ..., 2, false) bedeutet der Abstand zum nächsten Feld sind 2 Punkte
	-- oder ..., yDist, true) beudet der Abstand zum nächsten Feld wird berechnet und gleichmäßig aufgeteilt
	yStart, iDraw, iSep = Screen.drawVpC(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true) -- battery voltage
	yStart, iDraw, iSep = Screen.drawUsedCapacity(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true) -- used capacity
	yStart, iDraw, iSep = Screen.drawCurrent(iDraw, maxDraw, iSep, 2, lengthSep, xStart, yStart, yDist, true)   -- Current
	yStart, iDraw, iSep = Screen.drawPump_voltagebox(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, 2, false)     -- Pump voltage
	yStart, iDraw, iSep = Screen.drawIBECbox(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, 2, false)     -- IBEC
	yStart, iDraw, iSep = Screen.drawTempbox(iDraw, maxDraw, iSep, 1 , lengthSep, xStart, yStart, 2, false)      -- Temperature
	yStart, iDraw, iSep = Screen.drawThrottlebox(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, 2, false)    -- Throttle
	yStart, iDraw, iSep = Screen.drawPWMbox(iDraw, maxDraw, iSep, 1, lengthSep, xStart, yStart, yDist, true)      -- PWM
	----------------------------------------------------------
	
	
	maxreDraw = iDraw
	yreDist = math.floor((160 - yStart + yreStart + iSep * yreDist) / (iSep + 2))
	yreStart = math.floor((160 - (yStart - yreStart)) / 2)
	

	-- middle
  Screen.drawBattery()
  Screen.drawTank()
  Screen.drawMibotbox()
  
--	if used_capacity > -1 then Screen.drawBattery(remaining_capacity_percent, setupvars.capacity_alarm_thresh, setupvars.capacity, setupvars.cell_count, gyro_channel_value) 
--	else
--		if remaining_fuel_percent >= 0 then 
--			Screen.drawTank(remaining_fuel_percent, setupvars.capacity_alarm_thresh) 
--		gyro_channel_value = 17 end
--	end
--	if gyro_channel_value ~= 17 then Screen.drawMibotbox(gyro_channel_value) end
	
  collectgarbage()
end


-- Read translations
local function setLanguage()
	local lng = system.getLocale()
	local file = io.readall("Apps/"..appName.."/lang.jsn")
	local obj = json.decode(file)
	if(obj) then
		trans = obj[lng] or obj[obj.default]
	end
end

-- remove unused module
local function unrequire(module)
	package.loaded[module] = nil
	_G[module] = nil
end

-- switch to setup context
local function setupForm(formID)
  local Screen, Form
  
	Screen = nil
	unrequire(appName.."/Screen")
	system.unregisterTelemetry(1)
  
	collectgarbage()

	Form = require (appName.."/Form")

	-- return modified data from user
	setupvars = Form.setup(setupvars, Version)

	collectgarbage()
end

-- switch to telemetry context
local function closeForm()
  local Screen, Form
  
	Form = nil
	unrequire(appName.."/Form")
  
  collectgarbage()
  
	--Screen = require (appName.."/Screen")

	-- register telemetry window again after 500 ms
	goregisterTelemetry = 500 + system.getTimeCounter() -- used in loop()
  
	collectgarbage()
  
end


-- main loop
local function loop()
  
  -- code of loop from screen module
	if ( Screen ~= nil ) then
		Screen.loop()
	end
  
  -- register telemetry display again after form was closed 
	if ( goregisterTelemetry and system.getTimeCounter() > goregisterTelemetry ) then
    
    Screen = require(appName.."/Screen")
		Screen.init(setupvars)
    
		system.registerTelemetry(1, Title, 4, Window)
		goregisterTelemetry = nil
    
	end

	-- debug, memory usage
	--mem = math.modf(collectgarbage("count")) + 1
	--if ( maxmem < mem ) then
	--	maxmem = mem
	--	print (maxmem)
	--end

	collectgarbage()

end

-- init all
local function init(code1)
  local day
	local spaceLe, spaceRi = "", ""
	local i = 0 
	local lModel
	local lli
  local today, intToday
  
  
  setupvars.appName = appName	
	setupvars.model = system.getProperty("Model")
	owner = system.getUserName()
	

	setupvars.sensorId = system.pLoad("sensorId", 0)
	setupvars.battery_voltage_param = system.pLoad("battery_voltage_param", 0)
	setupvars.motor_current_param = system.pLoad("motor_current_param", 0)
	setupvars.rotor_rpm_param = system.pLoad("rotor_rpm_param", 0)
	setupvars.used_capacity_param = system.pLoad("used_capacity_param", 0)
	setupvars.bec_current_param = system.pLoad("bec_current_param", 0)
	setupvars.pwm_percent_param = system.pLoad("pwm_percent_param", 0)
	setupvars.fet_temp_param = system.pLoad("fet_temp_param", 0)
	setupvars.throttle_param = system.pLoad("throttle_param", 0)
	setupvars.status_param = system.pLoad("status_param", 0)
	setupvars.pump_voltage_param = system.pLoad("pump_voltage_param", 0)
	setupvars.remaining_fuel_percent_param = system.pLoad("remaining_fuel_percent_param", 0)
	setupvars.height_param = system.pLoad("height_param", 0)
	setupvars.vario_param = system.pLoad("vario_param", 0)

	setupvars.anCapaSw = system.pLoad("anCapaSw")
	setupvars.anVoltSw = system.pLoad("anVoltSw")
	setupvars.voltage_alarm_voice = system.pLoad("voltage_alarm_voice", "...")
	setupvars.capacity_alarm_voice = system.pLoad("capacity_alarm_voice", "...")
	setupvars.capacity = system.pLoad("capacity",0)
	setupvars.cell_count = system.pLoad("cell_count",1)
	setupvars.capacity_alarm_thresh = system.pLoad("capacity_alarm_thresh", 0)
	setupvars.voltage_alarm_thresh = system.pLoad("voltage_alarm_thresh", 0)
	setupvars.timeSw = system.pLoad("timeSw")
	setupvars.engineSw = system.pLoad("engineSw")
	setupvars.resSw = system.pLoad("resSw")
	setupvars.gyChannel = system.pLoad("gyChannel", 17) -- going to form only
	setupvars.gyro_output = system.pLoad("gyro_output", 0) -- coming from form only
	setupvars.todayCount = system.pLoad("todayCount", 0)
	setupvars.timeToCount = system.pLoad("timeToCount", 120)
	setupvars.lastDay = system.pLoad("lastDay", 0)
  
	today = system.getDateTime()	
	intToday = math.floor(system.getTime() / 86400)
  if setupvars.lastDay < intToday then
		setupvars.todayCount = 0
		system.pSave("lastDay", intToday)
		system.pSave("todayCount", 0)
	end
	
	setupvars.trans = trans
	
	day = string.format("%02d.%02d.%02d", today.day, today.mon, today.year)
	owner = system.getUserName()
	lModel = lcd.getTextWidth(FONT_MINI,string.format(setupvars.model))
	lli = 160 - lcd.getTextWidth(FONT_MINI,string.format(appName.." - "..owner)) -  lModel / 2
	
	for i = 1, lli/3.2 do spaceLe = spaceLe.." " end
	for i = 1, (160 - lModel / 2 - lcd.getTextWidth(FONT_MINI,string.format(day)))/3.2 do spaceRi = spaceRi.." " end
	Title = appName.." - "..owner..spaceLe.. setupvars.model..spaceRi..day
	system.registerForm(1, MENU_MAIN, appName, setupForm, nil, nil, closeForm)
	system.registerTelemetry(1,Title, 4, Window) -- registers a full size Window  

	unrequire("wifi")	-- there is no hardware present for this module
	--unrequire("io")	-- can be unloaded if no other App loaded uses file IO 

	Screen = require (appName.."/Screen")
  Screen.init(setupvars)

	-- debug, loaded modules
	--local i, p
	--for i, p in pairs(package.loaded) do
	--	print (i, p)
	--end	

	collectgarbage()
end
--------------------------------------------------------------------------------

setLanguage()
collectgarbage()
return {init=init, loop=loop, author="dit71", version=Version, name=appName}
