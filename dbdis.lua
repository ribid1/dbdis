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
	V1.3 select sensors from different devices
		- save the History (fight counts and total flight time in a file)
 	V1.4 Rx values of 2nd Receiver and Backup Receiver added
	V1.5 2nd Battery added
	V1.6 moved the drawfunctions in the screen modul
	V1.7 Central box added
	V2.0 Second Form to change the order of the boxes added
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
local Version = "1.9"
local owner = " ", " "
local Title
--local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local Form, Form2, Screen
local trans
local senslbls = {}
local formID

-- Telemetry Window
local function Window(width, height)
	Screen.showDisplay()
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
local function setupForm(ID)
	formID = ID
	Screen = nil						-- comment out if closeForm not available
	unrequire(appName.."/Screen")		-- comment out if closeForm not available
	system.unregisterTelemetry(1)		-- comment out if closeForm not available
  
	collectgarbage()

	Form = require (appName.."/Form")
	Form2 = require (appName.."/Form2")
	
	
	if (formID == 1) then setupvars = Form.setup(setupvars, Version, senslbls) -- return modified data from user
	elseif (formID == 2) then 
		setupvars = Form2.setup(setupvars)
	end

	form.setButton(1, "1", formID == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "2", formID == 2 and HIGHLIGHTED or ENABLED)

	if (formID == 2) then
		form.setButton(3, ":up", ENABLED)
		form.setButton(4, ":down", ENABLED)
	end
	collectgarbage()

end

local function saveOrder()
		local filename 
		if setupvars.template then filename = "Apps/"..setupvars.appName.."/template_O.txt"
			else filename = "Apps/"..setupvars.appName.."/"..setupvars.model.."_O.txt"
		end
		local file = io.open(filename, "w+")
		local i, line
		if file then
		for i, line in ipairs(setupvars.leftcolumn) do 
			io.write(file, line, "\n") 
			io.write(file, setupvars.param[line][1],"   ", setupvars.param[line][2], "\n")  
		end
		io.write(file, "---\n")
		for i, line in ipairs(setupvars.rightcolumn) do 
			io.write(file, line, "\n") 
			io.write(file, setupvars.param[line][1],"   ", setupvars.param[line][2], "\n")  
		end
		io.write(file, "---\n")
		for i, line in ipairs(setupvars.notused) do 
			io.write(file, line, "\n") 
			io.write(file, setupvars.param[line][1],"   ", setupvars.param[line][2], "\n")  
		end
		io.close(file)
		end
		collectgarbage()
end

local function moveLine(window, back)
	local startleft = 5
	local rowsleft = #setupvars.leftcolumn
	local startright = startleft + rowsleft + 2
	local rowsright = #setupvars.rightcolumn
	local startnotused = startright + rowsright + 2
	local rowsnotused = #setupvars.notused
	local row = form.getFocusedRow()
	if back then
		if row < startleft then
			form.setFocusedRow(row - 1)
		elseif row == startleft then
			table.insert(setupvars.notused, setupvars.leftcolumn[1])
			table.remove(setupvars.leftcolumn, 1)
			form.setFocusedRow(startnotused + rowsnotused - 1)
		elseif row < startleft + rowsleft then
			setupvars.leftcolumn[row - startleft],setupvars.leftcolumn[row - startleft + 1]  = setupvars.leftcolumn[row - startleft + 1], setupvars.leftcolumn[row - startleft]
			form.setFocusedRow(row - 1)
		elseif row < startright then
			form.setFocusedRow(row -1)
		elseif row == startright then
			table.insert(setupvars.leftcolumn, setupvars.rightcolumn[1])
			table.remove(setupvars.rightcolumn, 1)
			form.setFocusedRow(startleft + rowsleft)
		elseif row < startright + rowsright then
			setupvars.rightcolumn[row - startright],setupvars.rightcolumn[row - startright + 1]  = setupvars.rightcolumn[row - startright + 1], setupvars.rightcolumn[row - startright]
			form.setFocusedRow(row - 1)
		elseif row < startnotused then
			form.setFocusedRow(row - 1)
		elseif row < startnotused + rowsnotused then
			table.insert(setupvars.rightcolumn, setupvars.notused[row - startnotused + 1])
			table.remove(setupvars.notused, row - startnotused + 1)
			form.setFocusedRow(startright + rowsright)
		else
			form.setFocusedRow(row -1)
		end
	else
		if row < startleft then
			form.setFocusedRow(row + 1)
		elseif row < startleft + rowsleft - 1 then
			setupvars.leftcolumn[row - startleft + 2],setupvars.leftcolumn[row - startleft + 1]  = setupvars.leftcolumn[row - startleft + 1], setupvars.leftcolumn[row - startleft + 2]
			form.setFocusedRow(row + 1)
		elseif row == startleft + rowsleft - 1 then
			table.insert(setupvars.rightcolumn,1, setupvars.leftcolumn[rowsleft])
			table.remove(setupvars.leftcolumn, rowsleft)
			form.setFocusedRow(startright - 1)
		elseif row < startright then
			form.setFocusedRow(row + 1)
		elseif row < startright + rowsright - 1 then
			setupvars.rightcolumn[row - startright + 2],setupvars.rightcolumn[row - startright + 1]  = setupvars.rightcolumn[row - startright + 1], setupvars.rightcolumn[row - startright + 2]
			form.setFocusedRow(row + 1)
		elseif row == startright + rowsright -1 then
			table.insert(setupvars.notused,1, setupvars.rightcolumn[rowsright])
			table.remove(setupvars.rightcolumn, rowsright)
			form.setFocusedRow(startnotused - 1)
		elseif row < startnotused then
			form.setFocusedRow(row + 1)
		elseif row < startnotused + rowsnotused then
			table.insert(setupvars.leftcolumn, 1, setupvars.notused[row - startnotused + 1])
			table.remove(setupvars.notused, row - startnotused + 1)
			form.setFocusedRow(startleft)
		else
			form.setFocusedRow(row + 1)
		end
	end
	saveOrder()
end



local function keyForm(key)
	if (key == KEY_1 and formID ~= 1) then
		form.reinit(1)
	elseif (key == KEY_2 and formID ~= 2) then
		form.reinit(2)
	elseif (key == KEY_3 and formID == 2) then
		moveLine(formID, true)
		form.reinit(formID)
	elseif (key == KEY_4 and formID == 2) then
		moveLine(formID)
		form.reinit(formID)
	end
end

-- switch to telemetry context
local function closeForm()
  
	Form = nil
	unrequire(appName.."/Form")
  
	collectgarbage()

	-- register telemetry window again after 500 ms
	goregisterTelemetry = 500 + system.getTimeCounter() -- used in loop()
  
	collectgarbage()
  
end


-- main loop
local function loop()
  
  -- code of loop from screen module
	if ( Screen ) then
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
	local i,j
	local lModel
	local lli
	local today, intToday
	local sensCat
	local senslbl
	local catName
	owner = system.getUserName()
	
	senslbls.cat = {"eDrive", "fuelDrive", "Rx", "mixed"}
	senslbls.catName = {trans["all"]}
	for i,catName in ipairs(senslbls.cat) do
		table.insert(senslbls.catName, trans[catName])
	end
	
	senslbls.eDrive = {"battery_voltage_sens", "motor_current_sens", "used_capacity_sens", "bec_current_sens", "pwm_percent_sens", "throttle_sens"}
	senslbls.fuelDrive = {"remaining_fuel_percent_sens", "pump_voltage_sens", "status_sens"}
	senslbls.Rx = {"U1_sens", "U2_sens", "I1_sens", "I2_sens", "UsedCap1_sens", "UsedCap2_sens", "Temp_sens", "OverI_sens"}
	senslbls.mixed = {"rotor_rpm_sens", "fet_temp_sens", "altitude_sens", "vario_sens"}
    	
	setupvars.deviceId = system.pLoad("deviceId", 0)	-- remember last selectet device
	setupvars.catsel = system.pLoad("catsel", 1) 		-- selection of sensor category
	for i,sensCat in pairs(senslbls) do
		for j, senslbl in pairs(sensCat) do
			setupvars[senslbl] = system.pLoad(senslbl, { 0, 0 } )
		end
	end
	setupvars.appName = appName	
	setupvars.model = system.getProperty("Model")
	setupvars.anCapaSw = system.pLoad("anCapaSw")
	setupvars.anVoltSw = system.pLoad("anVoltSw")
	setupvars.voltage_alarm_voice = system.pLoad("voltage_alarm_voice", "...")
	setupvars.capacity_alarm_voice = system.pLoad("capacity_alarm_voice", "...")
	setupvars.capacity1 = system.pLoad("capacity1",0)
	setupvars.capacity2 = system.pLoad("capacity2",0)
	setupvars.akkuSw = system.pLoad("akkuSw")	
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
	setupvars.template = system.pLoad("template", 1) == 1 and true or false
  
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
	system.registerForm(1, MENU_MAIN, appName, setupForm, keyForm, nil, closeForm)
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
