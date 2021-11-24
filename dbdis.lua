--[[
	----------------------------------------------------------------------------
	App using Sensor Data to display in a full screen window
	----------------------------------------------------------------------------
	
	MIT License

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
   
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
	

	copied from nichtgedacht	Version History: V1.1
	
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
	V2.1 Permanent Value Alarm added
		 Tank Volume added
	V2.2 Possibility for a surrounding edge of the value boxes added
	V2.3 V2.3 The high in pixels of each box is displayed in the layout form
		- Not assigned boxes are shown in small letters
		- The left space in pixel is shown at the top of the right and the left row
	V2.4 Second page and speed box added	
	V2.6 Changed the format of the config file to .jsn 
	V3.0 Flightbook and RFid Sensors added
		- Site "BAT" to configurate Batteries added
	V3.2 Possibility to load a config file for the layout settings
	V3.21 Added acceleration values min/max ax, ay, az
	V3.22 Possibility to load a config file with all settings inklusive switch settings
			Improvement of saving the values of used batteries, especially for calc-el values.
	V3.23 Pre alarm added
	V3.24 Improvements to calculate the used capacity
	V3.27 Changed beause the DS12 isn't able to unload not used packages
		- Sensors with no labels like from the spirit system causes a failure
	V3.37 - Muli, Muli EX and 6x cell voltage sensorvalues added
		  - dbdis_config.jsn for global settings added
		  - background color for edged boxes added
		  - a 3rd temperatur sensorvalue added and temp sensorvalues new sortet, please pay attention!
          - manual updated
	V3.40 - Battery selection is limited to the batteries in the database
		  - In the flightbook max. current of the flight is saved
		  - A second tank volume is added
		  - Sensor values for a second drive is added
		  - A rpm factor for the RPM_2 box is added
	V3.41 - Improvement if Seperator < -1 und Trennstrich 
		  - Color of batteries and Tanks are driven by the usedCapacity boxes
		  - Improvement in combination with the CalCa-Gas App 
	V3.42 - Improvemtnt in combination with Jeti Assist (Sensor ID > 1)
		  - Multiple pages of the Akku page


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

-- setmetatable(_G, {
	-- __newindex = function(array, key, value)
		-- print(string.format("Changed _G: %s = %s", tostring(key), tostring(value)));
		-- rawset(array, key, value);
	-- end
-- });

--------------------------------------------------------------------------------
-- global:
dbdis_capacity = 0 -- dbdis_capacity wird in CalCa-Elec verwendet
dbdis_tank_volume = 0  -- dbdis_tank_volume wird in CalCa-Gas verwendet

local vars = {}
vars.appName = "dbdis"
vars.Version = "3.42"
local owner = " "
local Title1, Title2
--local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local Form, Form2, Screen
local senslbls = {}
local formID
local columns = {"leftcolumn", "rightcolumn", "notused"}
local checkNewBox = {true, true}

-- Telemetry Window
local function Window1(width, height)
	Screen.showDisplay(1)
	collectgarbage()
end

local function Window2(width, height)
	Screen.showDisplay(2)
	collectgarbage()
end

-- Read translations
local function setLanguage()
	local lng = system.getLocale()
	local file = io.readall("Apps/"..vars.appName.."/lang.jsn")
	local obj = json.decode(file)
	if(obj) then
		vars.trans = obj[lng] or obj[obj.default]
	end
	for i=1,6 do
		vars.trans["weakCell_sens"..i] = vars.trans.weakCell_sens..string.format("% d:",i)
		vars.trans["weakVoltage_sens"..i]= vars.trans.weakVoltage_sens..string.format("% d:",i)
	end
end

-- remove unused module -- doesn't work in DS12
-- local function unrequire(module)
	-- package.loaded[module] = nil
	-- _G[module] = nil
-- end

local function boxvisible()
	local paired
	local timeSw_val, engineSw_val, engineOffSw_val

	-- was wird angezeigt, was nicht
	for _,m in ipairs(columns) do
		for i,j in ipairs(vars[0][m]) do
			paired = false
			if #vars.cd[j].sensors > 0 then 
				for k,l in ipairs(vars.cd[j].sensors) do
					if vars.senslbl[l] and vars.senslbl[l][2]~= 0 then paired = true end
				end
			else
				paired = true	
				if j == "FlightTime" then
					 timeSw_val = system.getInputsVal(vars.switches.timeSw)
					 if not (vars.switches.timeSw ~= nil and timeSw_val ~= 0.0) then paired = false end
				end
				if j == "EngineTime" then
					engineSw_val = system.getInputsVal(vars.switches.engineSw)
					if not (vars.switches.engineSw ~= nil and engineSw_val ~= 0.0) then paired = false end
				end
				if j == "EngineOff" then
					engineOffSw_val = system.getInputsVal(vars.switches.engineOffSw)
					if not (vars.switches.engineOffSw ~= nil and engineOffSw_val ~= 0.0) then paired = false end
				end
			end
			if j == "UsedCapacity" and Calca_dispFuel then paired = true end
			if j == "Status1" and Global_TurbineState then paired = true end
			if j == "Status2" and Global_TurbineState2 then paired = true end
			if paired then
				vars.cd[j].visible = true
			else
				vars.cd[j].visible = false
			end
		end
	end
	vars.sensID = {}
	if vars.senslbl.batID_sens then vars.sensID[1] = "batID_sens" end
	if vars.senslbl.batID2_sens then vars.sensID[2] = "batID2_sens" end
	
	
	if vars.config.tank_volume2 == 0 then 
		vars.tankRatio2 = 1
	else
		vars.tankRatio2 = vars.config.tank_volume1 / vars.config.tank_volume2
	end
	
	vars.iAkkus = {}
	vars.iTanks = {}
	vars.middle = {}
	vars.iEngines = 0
	
	if vars.senslbl.used_capacity_sens or Calca_dispFuel then
		vars.middle = {"drawBattery"}
		vars.iEngines = 1
		vars.iAkkus = {1}
		if vars.senslbl.used_capacity2_sens then
			vars.iEngines = 2
			if not vars.switches.akkuSw then
				vars.iAkkus = {1,2}
				vars.middle = {"draw1stBattery", "draw2ndBattery"} 
			end
		end
	elseif vars.senslbl.used_capacity2_sens then
		vars.iEngines = 1
		vars.iAkkus = {2}
		vars.middle = {"draw2ndBattery"}
	end
	
	if vars.senslbl.remaining_fuel_percent_sens or Calca_dispGas then
		vars.middle = {"drawTank"}
		vars.iTanks = {1}
		if vars.senslbl.remaining_fuel_percent2_sens then
			if not vars.switches.akkuSw then
				vars.iTanks = {1,2}
				vars.middle = {"draw1stTank", "draw2ndTank"}
			end
		end
	elseif vars.senslbl.remaining_fuel_percent2_sens then
		table.insert(vars.middle, "draw2ndTank")
		vars.iTanks = {2}
	end
	
	collectgarbage()
end


		-- local function calcDistanceold(page,column)
			-- local totalhight = 0
			-- local icalc = 1
			-- local ycalc = 0
			-- local yborder = 6
			-- local ybd2 = 3  -- yborder / 2
			-- local dcol = {}    -- drawcolumn
			-- -- dcol.order - Reihenfolge der Box
			-- -- dcol.yStart - Start der Box
			-- -- dcol.Sep  - Tatsächlich gezeichneter Seperator
			-- local yStart = 159   -- Start der Box
			-- local distO = {} -- Original Distanz
			-- local count = {}
			-- local k,l = 0,0
			
			-- for i,j in ipairs(column) do
				-- if vars.cd[j] then 
					-- if vars.cd[j].visible then 
						-- table.insert(dcol,1,{})
						-- dcol[1].order = j
					-- end
				-- else
					-- table.remove(column,i)
				-- end
			-- end
			
			-- if #dcol > 0 then	
				-- for i,j in ipairs(dcol) do
					-- j.SepO = vars[page].cd[j.order].sep
					-- j.Sep = j.SepO
					-- distO[i] = vars[page].cd[j.order].dist
					-- count[i] = true
				-- end
				-- dcol[1].Sep = 0
				-- for i,j in ipairs(dcol) do
					-- totalhight = totalhight + vars.cd[j.order].y			
					-- if j.SepO < 0 then -- Box mit Rand
						-- totalhight = totalhight + yborder
						-- if i-j.SepO <= #dcol then
							-- dcol[i-j.SepO].Sep = 0
						-- end
						-- l = math.min(i-1-j.SepO,#dcol)
						-- if dcol[l].SepO > -1 and count[l] then
							-- count[l] = false
							-- totalhight = totalhight + ybd2
						-- end
					-- end	
					-- k = 1
					-- if j.Sep > 0 then -- Box mit Trennzeichen
						-- k = 2
						-- totalhight = totalhight + j.Sep
					-- end
					
					-- if distO[i] > -9 then  -- Distanz angegeben
						-- totalhight = totalhight + distO[i] * k
					-- else --Distanz wird berechnet
						-- icalc = icalc + k
					-- end
				-- end
				-- ycalc = math.floor((159 - totalhight) / icalc)
				-- for i,j in ipairs(dcol) do
					-- if distO[i] == -9 then 
						-- dcol[i].ydist = ycalc
					-- else
						-- dcol[i].ydist = distO[i]
					-- end
					-- j.yStart = 0
				-- end		
				
				-- if distO[1] == -9 then
					-- dcol[1].ydist = math.floor((yStart-totalhight-(icalc-2)*ycalc)/2)
				-- end
				
				-- for i,j in ipairs(dcol) do
					-- yStart = yStart - dcol[i].ydist + j.yStart - vars.cd[j.order].y
					-- if j.SepO < 0 then
						-- yStart = yStart - ybd2
						-- j.yStart = yStart
						-- if j.SepO < -1 and i-j.SepO <= #dcol then
							-- dcol[i-j.SepO].yStart = -ybd2
						-- end
						-- if i < #dcol then dcol[i+1].yStart = -ybd2 end
					-- else
						-- if j.Sep > 0 then 
							-- yStart = yStart - j.SepO - dcol[i].ydist
						-- end	
						-- j.yStart = yStart
					-- end
				-- end		
			-- end	
			-- collectgarbage()
			-- return ycalc, dcol
		-- end

local function calcDistance(page,column)
	local totalhight = 0
	local icalc = 1
	local ycalc = 0
	local yborder = 6
	local ybd2 = 3  -- yborder / 2
	local dcol = {}    -- drawcolumn
	-- dcol.order - Reihenfolge der Box
	-- dcol.yStart - Start der Box
	-- dcol.Sep  - Tatsächlich gezeichneter Seperator
	local yStart = 159   -- Start der Box
	local distO = {} -- Original Distanz
	local k,l = 0,0
	
	for i,j in ipairs(column) do
		if vars.cd[j] then 
			if vars.cd[j].visible then 
				table.insert(dcol,1,{})
				dcol[1].order = j
			end
		else
			table.remove(column,i)
		end
	end
	
	if #dcol > 0 then	
		for i,j in ipairs(dcol) do
			j.SepO = vars[page].cd[j.order].sep
			j.Sep = j.SepO
			distO[i] = vars[page].cd[j.order].dist
		end
		dcol[1].Sep = 0
		for i,j in ipairs(dcol) do
			totalhight = totalhight + vars.cd[j.order].y	-- Höhe der Box
			if j.SepO < 0 then -- Box mit Rand
				totalhight = totalhight + yborder  -- + unteren und oberen Rand
				if i-j.SepO <= #dcol then
					dcol[i-j.SepO].Sep = 0      -- Seperator der vorhergehenden Box wird auf 0 gesetzt
				end
			end	
			k = 1
			if j.Sep > 0 then -- Box mit Trennzeichen
				k = 2
				totalhight = totalhight + j.Sep
			end
			
			if distO[i] > -9 then  -- Distanz angegeben
				totalhight = totalhight + distO[i] * k
			else --Distanz wird berechnet
				icalc = icalc + k
			end
		end
		ycalc = math.floor((159 - totalhight) / icalc)
		for i,j in ipairs(dcol) do
			if distO[i] == -9 then 
				dcol[i].ydist = ycalc
			else
				dcol[i].ydist = distO[i]
			end
			j.yStart = 0
		end		
		
		if distO[1] == -9 then
			dcol[1].ydist = math.floor((yStart-totalhight-(icalc-2)*ycalc)/2)
		end
		
		for i,j in ipairs(dcol) do
			yStart = yStart - dcol[i].ydist + j.yStart - vars.cd[j.order].y
			if j.SepO < 0 then
				yStart = yStart - ybd2
				if i-j.SepO <= #dcol then  
					dcol[i-j.SepO].yStart = -ybd2
				end
				j.yStart = yStart
			else
				if j.Sep > 0 then 
					yStart = yStart - j.SepO - dcol[i].ydist
				end	  
				j.yStart = yStart
			end
		end		
	end	
	collectgarbage()
	return ycalc, dcol
end

local function load_txt(page)
	local line
	local i
	local column = "left"
	local value
	local file = nil
	local temp = {}
	
	vars[page] = {}
	vars[page].leftcolumn = {}
	vars[page].rightcolumn = {}
	vars[page].notused = {}
	vars[page].cd = {}
	
	file = io.open("Apps/"..vars.appName.."/"..vars.NameTemplate, "r")
	if file then
		line = io.readline(file)
		repeat
			if column == "left" then
				if line ~= "---" then
					table.insert(vars[page].leftcolumn, line)
					temp[line] = true
					i = 0
					vars[page].cd[line] = {}
					for value in string.gmatch(io.readline(file), "%S+") do 
						i = i + 1
						if value then 
							if i == 1 then 
								vars[page].cd[line].sep = tonumber(value)								
							elseif i == 2 then 
								vars[page].cd[line].dist = tonumber(value) 
							end
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
					vars[page].cd[line] = {}
					for value in string.gmatch(io.readline(file), "%S+") do
						i = i + 1
						if value then 
							if i == 1 then 
								vars[page].cd[line].sep = tonumber(value) 
							elseif i == 2 then 
								vars[page].cd[line].dist = tonumber(value) 
							end
						end
					end
				else 
					column = "notused"
				end	
			else
				table.insert(vars[page].notused, line)
				temp[line] = true
				i = 0
				vars[page].cd[line] = {}
				for value in string.gmatch(io.readline(file), "%S+") do 
					i = i + 1
					if value then 
						if i == 1 then 
							vars[page].cd[line].sep = tonumber(value) 
						elseif i == 2 then 
							vars[page].cd[line].dist = tonumber(value) 
						end
					end
				end
			end
			line = io.readline(file)
		until (not line)
		io.close(file)
	end

  collectgarbage()
end

local function loadOrder(page)
	local file
	if vars.NameTemplate then 
		if string.sub(vars.NameTemplate,-3,-1) == "jsn" then
			file = io.readall("Apps/"..vars.appName.."/"..vars.NameTemplate, "r") 
			if file then 
				vars[page] = json.decode(file)
			end
		else
			load_txt(page)
		end
		vars.NameTemplate = nil
	end
	collectgarbage()
end
		
local function loadStartOrder()	
	local file
	for page=1,2 do	
		file = io.readall("Apps/"..vars.appName.."/"..vars.model.."_d"..page..".jsn", "r") 
		if file then
			vars[page] = json.decode(file)
			-- Farbe noch nicht vorhanden:
			for i,j in pairs(vars[page].cd) do
				if not j.col then j.col = 0 end
			end
			--if vars.deviceId == 0 then 
				vars[page].ycalcLeft, vars[page].leftdrawcol = calcDistance(page,vars[page].leftcolumn)
				vars[page].ycalcRight, vars[page].rightdrawcol = calcDistance(page,vars[page].rightcolumn)
			--end
		else
			vars[page] = json.decode(json.encode(vars[page-1]))
			if page == 1 then
				vars[page].ycalcLeft, vars[page].leftdrawcol = calcDistance(page,vars[page].leftcolumn)
				vars[page].ycalcRight, vars[page].rightdrawcol = calcDistance(page,vars[page].rightcolumn)
			end
		end
		-- bat colors
		if vars[page].cd.UsedCapacity and vars.configG.color[vars[page].cd.UsedCapacity.col] then
			vars.col[page][1] = vars.configG.color[vars[page].cd.UsedCapacity.col]
		end
		if vars[page].cd.UsedCapacity_2 and vars.configG.color[vars[page].cd.UsedCapacity_2.col] then
			vars.col[page][2] = vars.configG.color[vars[page].cd.UsedCapacity_2.col]
		end
	end
	collectgarbage()
end

local function saveOrder(page)
		local filename 
		filename = "Apps/"..vars.appName.."/"..vars.model.."_d"..page..".jsn"
		local obj = json.encode(vars[page])
		local file = io.open(filename, "w+")
		
		if file then
			io.write(file,obj)
			io.close(file)
		end
		collectgarbage()
end

local function loadBat()
	vars.Akkus = {}
	vars.AkkusID = {}
	local Atemp = {}
	local file = io.readall("Apps/"..vars.appName.."/Akkus.jsn")
	if file then
		local obj = json.decode(file)
		if obj then
			vars.Akkus = obj
		end
	end
	
	for i,j in ipairs(vars.Akkus) do
		vars.AkkusID[math.floor(j.ID)]= i
		j.ID = math.floor(j.ID)
	end
	
	if not vars.AkkusID[0] then
		Atemp.ID = 0
		Atemp.usedCapacity = 0
		Atemp.Ah = 0
		Atemp.Capacity = 0
		Atemp.iCells = 1
		Atemp.Name = ""
		Atemp.batC = 0
		Atemp.Cycl = 0
		table.insert(vars.Akkus,Atemp)
		vars.AkkusID[0] = #vars.Akkus
	end
	
	if not vars.AkkusID[vars.config.Akku1ID] then
		vars.config.Akku1ID = 0
	end
	if not vars.AkkusID[vars.config.Akku2ID] then
		vars.config.Akku2ID = 0
	end
	vars.Akku1 = vars.AkkusID[vars.config.Akku1ID]
	vars.Akku2 = vars.AkkusID[vars.config.Akku2ID]

	collectgarbage()
end

local function changed(page)
	if vars.changeSens > 0 then
		boxvisible()
		if vars.change[1] < 2 then vars.change[1] = 2 end
		if vars.change[2] < 2 then vars.change[2] = 2 end
		vars.changeSens = 0
	end
	
	if vars.change[page] == 4 then -- template hat sich geändert
		loadOrder(page)
		checkNewBox[page] = true
	end
	if vars.change[page] > 1 then -- Reihenfolge geändert
		vars[page].ycalcLeft, vars[page].leftdrawcol = calcDistance(page,vars[page].leftcolumn)
		vars[page].ycalcRight, vars[page].rightdrawcol = calcDistance(page,vars[page].rightcolumn)
	end
	if vars.change[page] > 0 then
		saveOrder(page)
	end 
	vars.change[page] = 0
	collectgarbage()
end

local function saveConfig()
		local filename 
		local senstxt = {}
		for i,senslbl in pairs(vars.senslbl) do
			senstxt[i]={}
			senstxt[i][1] = tostring(senslbl[1])
			senstxt[i][2] = tostring(senslbl[2])	
		end
				
		filename = "Apps/"..vars.appName.."/"..vars.model.."_config.jsn"
		local obj = json.encode({vars.config, senstxt, vars.switchInfo})
		local file = io.open(filename, "w+")
		
		if file then
			io.write(file,obj)
			io.close(file)
		end
		vars.changedConfig = 0
		collectgarbage()
end

local function loadConfig()
	local file
	local obj
	local senstxt 
	local device_id_list = {}
	
	for i,sensor in ipairs(system.getSensors()) do
		if (sensor.param == 0) then
			device_id_list[tostring(sensor.id)] = true
		end
	end

	file = io.readall("Apps/"..vars.appName.."/"..vars.configName, "r") 
	if file then 
		obj = json.decode(file)
		for i,senslbl in pairs(obj[2]) do
			if device_id_list[senslbl[1]] then
				vars.senslbl[i] = {}
				vars.senslbl[i][1] = tonumber(senslbl[1])
				vars.senslbl[i][2] = tonumber(senslbl[2])
				system.pSave(i,vars.senslbl[i])
			end
		end
		
		vars.senslbl["batC_sens"] = nil
		vars.senslbl["batCap_sens"] = nil
		vars.senslbl["batCells_sens"] = nil
		
		for i,config in pairs(obj[1]) do
			vars.config[i] = config
			system.pSave(i,config)
		end
		
		vars.switchInfo = obj[3]
		for i,switchInfo in pairs(obj[3]) do
			vars.switches[i] = system.createSwitch(switchInfo.name,switchInfo.mode,switchInfo.activeOn)
			system.pSave(i,vars.switches[i])
		end
		saveConfig()
	end
	vars.configName = ""
	dbdis_tank_volume = vars.config.tank_volume1
	
	if not vars.AkkusID[vars.config.Akku1ID] then
		vars.config.Akku1ID = 0
	end
	if not vars.AkkusID[vars.config.Akku2ID] then
		vars.config.Akku2ID = 0
	end
	vars.Akku1 = vars.AkkusID[vars.config.Akku1ID]
	vars.Akku2 = vars.AkkusID[vars.config.Akku2ID]
	collectgarbage()
end

local function checkNewBoxes(page)
	local exist ={}
	for _,m in ipairs(columns) do
		for _, v in ipairs(vars[page][m]) do
			exist[v] = true 
		end
	end
	for _,m in ipairs(columns) do
		for _, v in ipairs(vars[0][m]) do 
			if not exist[v] then 
				table.insert(vars[page].notused, v) 
				vars[page].cd[v] = json.decode(json.encode(vars[0].cd[v]))
			end
		end
	end
	collectgarbage()
end

-- switch to setup context
local function setupForm(ID)
	formID = ID
	local page = formID - 1
	--Screen = nil						-- comment out if closeForm not available
	--unrequire(appName.."/Screen")		-- comment out if closeForm not available
	system.unregisterTelemetry(1)		-- comment out if closeForm not available
	system.unregisterTelemetry(2)
	collectgarbage()
	form.setButton(1, "1", formID == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "2", formID == 2 and HIGHLIGHTED or ENABLED)
	form.setButton(3, "3", formID == 3 and HIGHLIGHTED or ENABLED)
	form.setButton(4, "BAT", formID == 4 and HIGHLIGHTED or ENABLED)
	if (formID == 1) then	
	---unrequire(vars.appName.."/Screen")
		---unrequire(vars.appName.."/Form2")
		if not Form then Form = require (vars.appName.."/Form") end
		vars = Form.setup(vars, senslbls) -- return modified data from user		
	else 
		-- if not Screen then Screen = require (vars.appName.."/Screen") end
		-- vars = Screen.init(vars)						
		---unrequire(vars.appName.."/Screen")
		---unrequire(vars.appName.."/Form")
		if not Form2 then Form2 = require (vars.appName.."/Form2") end
		if formID == 2 or formID == 3 then
			changed(page)
			if checkNewBox[page] then
				checkNewBoxes(page)
				checkNewBox[page] = false
			end
			vars = Form2.setup(vars, page)
			form.setButton(4, ":up", ENABLED)
			form.setButton(5, ":down", ENABLED)
		else
			vars = Form2.setupBat(vars)
			form.setButton(5, ":add", ENABLED)
		end
	end
	collectgarbage()
end

local function keyForm(key)
	if key == KEY_1 then
		if formID == 1 then
			if vars.changeSens == 2 then
				loadConfig()
				changed(1)
				changed(2)
			elseif vars.changeSens == 1 or vars.changedConfig == 1 then	
				saveConfig()
			else
				form.preventDefault()
				vars.deviceIndex = 0
			end	
		end	
		form.reinit(1)
	elseif (key == KEY_2 and formID ~= 2) then
		form.reinit(2)
	elseif key == KEY_2 and formID == 2 then
		if vars.change[1] == 3 then vars.change[1] = 4 end
		form.reinit(2)
	elseif (key == KEY_3 and formID ~= 3) then
		form.reinit(3)	
	elseif key == KEY_3 and formID == 3 then
		if vars.change[2] == 3 then vars.change[2] = 4 end
		form.reinit(3)
	elseif key == KEY_4 and (formID == 2 or formID == 3) then
		Form2.moveLine(true)
		form.reinit(formID)
	elseif (key == KEY_4 and formID ~= 4) then
		form.reinit(4)		
	elseif key == KEY_5 and formID == 4 then
		vars.addAkku = 1
		form.preventDefault()
		form.reinit(formID)	
	elseif key == KEY_ENTER and formID == 4 then
		Form2.scrollAkku()
		form.reinit(formID)
	elseif key == KEY_5 and (formID == 2 or formID == 3) then
		Form2.moveLine()
		form.preventDefault()
		form.reinit(formID)
	end
end

-- switch to telemetry context
local function closeForm()
	changed(1)
	changed(2)
	---unrequire(vars.appName.."/Form")
	---unrequire(vars.appName.."/Form2")
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
		-- Form2 = require (vars.appName.."/Form2")
		-- vars = Form2.init(vars,1)
		-- vars = Form2.init(vars,2)
		-- Form2 = nil
		-- unrequire(vars.appName.."/Form2")
		Screen = require(vars.appName.."/Screen")
		Screen.setvars(vars)
    
		system.registerTelemetry(1, Title1, 4, Window1)
		system.registerTelemetry(2, Title2, 4, Window2)
		goregisterTelemetry = nil
	end

	-- debug, memory usage
	--mem = math.modf(collectgarbage("count")) + 1
	--if ( maxmem < mem ) then
	--	maxmem = mem
	--	print (maxmem)
	--end
 
	--if CPU ~= system.getCPU() then CPU = system.getCPU() print(CPU) end
	collectgarbage()

end

-- init all
local function init(code1)
	local day
	local spaceLe, spaceRi = "", ""
	local lModel
	local lli
	local today, intToday
	local temp = {}
	local file
	local obj


	vars.addAkku = 0
	vars.AkkuPage = 1
	owner = system.getUserName()
	vars.model = system.getProperty("Model")

	vars.NameTemplate = nil
	vars.changeSens = 0   -- 0: keine Änderung, 1: Sensorzuweisung geändert (save) 2: load config
	vars.change = {0,0}     -- 0-keine Änderung, 1:sep oder dist bei unused hat sich geä., 2:moveLine ausgeführt, 3:template hat sich geändert
	
	vars.configG = {}
	vars.config = {}
	vars.senslbl = {}
	vars.switches = {}
	vars.switchInfo = {}
	vars.drawVal = {}
	
	
	vars.cat = {"eDrive", "fuelDrive", "Rx", "mixed", "Muli", "secondEngine"}
	vars.catName = {vars.trans["all"]}
	for i,catName in ipairs(vars.cat) do
		table.insert(vars.catName, vars.trans[catName])
	end
	
	--46 Sensoren
	senslbls.eDrive = {"battery_voltage_sens", "motor_current_sens", "used_capacity_sens", "bec_current_sens", "pwm_percent_sens", "throttle_sens", "batID_sens"} --7
	senslbls.fuelDrive = {"remaining_fuel_percent_sens", "pump_voltage_sens", "status_sens"} --3
	senslbls.Rx = {"U1_sens", "U2_sens", "I1_sens", "I2_sens", "UsedCap1_sens", "UsedCap2_sens", "fet_temp_sens", "OverI_sens"} --8
	senslbls.mixed = {"rotor_rpm_sens", "Temp_sens", "altitude_sens", "vario_sens", "speed_sens", "vibes_sens", "ax_sens", "ay_sens", "az_sens"} --9
	senslbls.Muli = {"checkedCells_sens", "deltaVoltage_sens"} --2
	senslbls.secondEngine = {"battery_voltage2_sens", "motor_current2_sens", "used_capacity2_sens", "remaining_fuel_percent2_sens", "rpm2_sens", "Temp2_sens", "batID2_sens", "status2_sens"} --5
	-- not used anymore:  "batCap_sens", "batCells_sens", "batC_sens"
	
	for i=1,6 do 
		table.insert(senslbls.Muli,"weakCell_sens"..i)
		table.insert(senslbls.Muli,"weakVoltage_sens"..i)
	end --12
	
	-- for i,sensCat in pairs(senslbls) do
		-- for j, senslbl in pairs(sensCat) do
			-- vars.config[senslbl] = system.pLoad(senslbl, { 0, 0 } )
		-- end
	-- end	
	
	for i,sensCat in pairs(senslbls) do
		for j, senslbl in pairs(sensCat) do
			temp = system.pLoad(senslbl, { 0, 0 } )
			if temp[2] ~= 0 then vars.senslbl[senslbl] = temp end
			vars.drawVal[senslbl] = {}
			vars.drawVal[senslbl].valid = true
		end
	end
		
	vars.deviceId = system.pLoad("deviceId", 0)	-- remember last selectet device
	vars.catsel = system.pLoad("catsel", 1) 		-- selection of sensor category
	
	vars.cd = {}
	vars.cd.TotalCount = {y = 9, sensors = {}} 		-- TotalTime
	vars.cd.FlightTime = {y = 17, sensors = {}}  	-- FlightTime
	vars.cd.EngineTime = {y = 12, sensors = {}}  	-- EngineTime
	vars.cd.EngineOff = {y = 12, sensors = {}}  	-- EngineOff
	vars.cd.Rx1Values = {y = 29, sensors = {}}	-- Rx1 values
    vars.cd.Rx2Values = {y = 29, sensors = {}}	-- Rx2 values
    vars.cd.RxBValues = {y = 29, sensors = {}}	-- RxB values  
	vars.cd.RPM = {y = 37, sensors = {"rotor_rpm_sens"}}    		-- rpm
	vars.cd.RPM_2 = {y = 37, sensors = {"rpm2_sens"}}    		-- rpm
	vars.cd.Altitude = {y = 17, sensors = {"altitude_sens"}}   		-- altitude
	vars.cd.Speed = {y = 17, sensors = {"speed_sens"}}   		-- speed
	vars.cd.Vario = {y = 18, sensors = {"vario_sens"}}   		-- vario
	vars.cd.Status = {y = 12, sensors = {"status_sens"}}    	-- Status1
	vars.cd.Status2 = {y = 12, sensors = {"status2_sens"}}    	-- Status1
	vars.cd.Volt_per_Cell = {y = 25, sensors = {"battery_voltage_sens"}} 			-- battery voltage
	vars.cd.Volt_per_Cell_2 = {y = 25, sensors = {"battery_voltage2_sens"}} 			-- battery voltage
	vars.cd.UsedCapacity = {y = 35, sensors = {"used_capacity_sens"}} 	-- used capacity
	vars.cd.UsedCapacity_2 = {y = 35, sensors = {"used_capacity2_sens"}} 	-- used capacity
	vars.cd.Current = {y = 17, sensors = {"motor_current_sens"}}   		-- Current
	vars.cd.Current_2 = {y = 17, sensors = {"motor_current2_sens"}}   		-- Current
	vars.cd.Pump_voltage = {y = 18, sensors = {"pump_voltage_sens"}}    -- Pump voltage
	vars.cd.I_BEC = {y = 17, sensors = {"bec_current_sens"}}     		-- IBEC
	vars.cd.Temp = {y = 17, sensors = {"Temp_sens"}}      		-- Temperature 1
	vars.cd.Temp_2 = {y = 17, sensors = {"Temp2_sens"}}      		-- Temperature 2
	vars.cd.FET_Temp = {y = 17, sensors = {"fet_temp_sens"}}      		-- FET-Temperature
	vars.cd.Throttle = {y = 17, sensors = {"throttle_sens"}}    	-- Throttle
	vars.cd.PWM = {y = 17, sensors = {"pwm_percent_sens"}}      	-- PWM
	vars.cd.C1_and_I1 = {y = 16, sensors = {"UsedCap1_sens", "I1_sens"}}      	-- CI1
	vars.cd.C2_and_I2 = {y = 16, sensors = {"UsedCap2_sens", "I2_sens"}}      	-- CI2
	vars.cd.U1_and_Temp = {y = 16, sensors = {"U1_sens"}}    -- U1 and Temp
	vars.cd.U2_and_OI = {y = 12, sensors = {"U2_sens", "OverI_sens"}}      -- U2 and OverI
	vars.cd.U1_and_I1 = {y = 16, sensors = {"U1_sens", "I1_sens"}}      -- U1 and I1
	vars.cd.U2_and_I2 = {y = 16, sensors = {"U2_sens", "I2_sens"}}      -- U2 and I2
	vars.cd.used_Cap1 = {y = 16, sensors = {"UsedCap1_sens"}}      -- used capacity 1
	vars.cd.used_Cap2 = {y = 16, sensors = {"UsedCap2_sens"}}      -- used capacity 1
	vars.cd.weakest_Cell = {y = 38, sensors = {"weakCell_sens1", "weakVoltage_sens1", "checkedCells_sens", "deltaVoltage_sens"}}    -- weakest Cell
	vars.cd.ax_ay_az = {y = 18, sensors = {"ax_sens", "ay_sens", "az_sens"}}      -- ax or ay or az
	vars.cd.Vibes = {y = 17, sensors = {"vibes_sens"}}      -- Vibes
		
	vars[0] = {}
	vars[0].cd = {}
	vars[0].cd.TotalCount = {sep = 0, dist = -9} 		-- TotalTime
	vars[0].cd.FlightTime = {sep = 0, dist = -9}  	-- FlightTime
	vars[0].cd.EngineTime = {sep = 2, dist = -9}  	-- EngineTime
	vars[0].cd.EngineOff = {sep = 1, dist = -9}    	-- EngineOff
	vars[0].cd.Rx1Values = {sep = 2, dist = -9}	-- Rx1 values
    vars[0].cd.Rx2Values = {sep = 2, dist = -9}	-- Rx2 values
    vars[0].cd.RxBValues = {sep = 2, dist = -9}	-- RxB values  
	vars[0].cd.RPM = {sep = 2, dist = -9}    		-- rpm
	vars[0].cd.RPM_2 = {sep = 2, dist = -9}    		-- rpm
	vars[0].cd.Altitude = {sep = 1, dist = -9}   		-- altitude
	vars[0].cd.Speed = {sep = 1, dist = -9}   		-- speed
	vars[0].cd.Vario = {sep = 2, dist = -9}   		-- vario
	vars[0].cd.Status = {sep = 1, dist = -9}    	-- Status1
	vars[0].cd.Status2 = {sep = 1, dist = -9}    	-- Status1
	vars[0].cd.Volt_per_Cell = {sep = 2, dist = -9} 			-- battery voltage
	vars[0].cd.Volt_per_Cell_2 = {sep = 2, dist = -9} 			-- battery voltage
	vars[0].cd.UsedCapacity = {sep = -1, dist = -9} 	-- used capacity
	vars[0].cd.UsedCapacity_2 = {sep = -1, dist = -9} 	-- used capacity
	vars[0].cd.Current = {sep = 2, dist = -9}   		-- Current
	vars[0].cd.Current_2 = {sep = 2, dist = -9}   		-- Current
	vars[0].cd.Pump_voltage = {sep = 1, dist = -9}    -- Pump voltage
	vars[0].cd.I_BEC = {sep = 1, dist = -9}     		-- IBEC
	vars[0].cd.Temp = {sep = 1 , dist = -9}      		-- Temperature 1
	vars[0].cd.Temp_2 = {sep = 1 , dist = -9}      		-- Temperature 2
	vars[0].cd.FET_Temp = {sep = 1 , dist = -9}      		-- FET-Temperature
	vars[0].cd.Throttle = {sep = 1, dist = -9}    	-- Throttle
	vars[0].cd.PWM = {sep = 1, dist = -9}      	-- PWM
	vars[0].cd.C1_and_I1 = {sep = 1, dist = -9}      	-- CI1
	vars[0].cd.C2_and_I2 = {sep = 1, dist = -9}      	-- CI2
	vars[0].cd.U1_and_Temp = {sep = 1, dist = -9}    -- U1 and Temp
	vars[0].cd.U2_and_OI = {sep = 1, dist = -9}      -- U2 and OverI
	vars[0].cd.U1_and_I1 = {sep = 0, dist = -9}      -- U1 and I1
	vars[0].cd.U2_and_I2 = {sep = 0, dist = -9}      -- U2 and I2
	vars[0].cd.used_Cap1 = {sep = 0, dist = -9}      -- used Capacity 1
	vars[0].cd.used_Cap2 = {sep = 0, dist = -9}      -- used Capacity 2
	vars[0].cd.weakest_Cell = {sep = 1, dist = -9}      -- used Capacity 2
	vars[0].cd.ax_ay_az = {sep = 1, dist = -9}      -- ax ay az
	vars[0].cd.Vibes = {sep = 1, dist = -9}      -- Vibes
	
	vars[0].leftcolumn = {"TotalCount", "FlightTime", "EngineTime", "Rx1Values", "RPM", "Altitude", "Vario", "EngineOff", "Status"} --9
	vars[0].rightcolumn = {"Volt_per_Cell", "UsedCapacity", "Current", "Pump_voltage", "I_BEC", "Temp", "FET_Temp", "Throttle", "PWM", "C1_and_I1", "C2_and_I2", "U1_and_Temp", "U2_and_OI", "Status2"} --14
	vars[0].notused = {"Speed", "Rx2Values", "RxBValues", "U1_and_I1", "U2_and_I2", "used_Cap1", "used_Cap2", "Temp_2", "RPM_2", "Volt_per_Cell_2","UsedCapacity_2", "Current_2", "weakest_Cell", "Vibes", "ax_ay_az"} --13
	
	for i,j in pairs(vars[0].cd) do
		j.col = 0
	end

	--Global config values:
	vars.configG.AkkuFull = 4.08  --bei einer Spannung über diesen Wert wird der Akku als voll erkannt
	vars.configG.AkkuUsed = 4.08  --bei einer Spannung unter diesem Wert wird der Akku als verwendet erkannt
	vars.configG.imaxPreAlarm = 2  -- maximale Anzahl Voralarm
	vars.configG.imaxMainAlarm = 4 -- maximale Anzahl Hauptalarm
	vars.configG.imaxVoltAlarm = 6 -- maximale Anzahl voltage Alarm
	vars.configG.CalcUsedCapacity = true  -- calculate remaining Capacity due to voltage
	vars.configG.color = {{255,150,0},{255,250,0},{210,255,0},{150,255,0},{0,220,0},{0,255,255},{110,190,250},{255,100,255},{255,70,110}}
	file = io.readall("Apps/"..vars.appName.."/dbdis_config.jsn", "r") 
	if file then 
		obj = json.decode(file)
		for i,k in pairs(obj) do
			if vars.trans[i] then 
				vars.trans[i] = k
			elseif string.sub(i,1,5) == "color" then
				vars.configG.color[tonumber(string.sub(i,-2,-1))] = k
			else	
				vars.configG[i] = k
			end
		end		
	end
	
	vars.col = {}
	vars.col[1] = {}   -- page = 1
	vars.col[2] = {}   -- page = 2
	vars.col[1][1] = {0,220,0} --grün
	vars.col[1][2] = {0,220,0} --grün
	vars.col[2][1] = {0,220,0} --grün
	vars.col[2][2] = {0,220,0} --grün
	vars.config.tank_volume1 = system.pLoad("tank_volume1",0)
	dbdis_tank_volume = vars.config.tank_volume1
	vars.config.tank_volume2 = system.pLoad("tank_volume2",0)
	vars.config.voltage_alarm_voice = system.pLoad("voltage_alarm_voice", "...")
	vars.config.capacity_alarm_voice = system.pLoad("capacity_alarm_voice", "...")
	vars.config.capacity_alarm_voice2 = system.pLoad("capacity_alarm_voice2", "...")
	vars.config.modelAnnounceVoice = system.pLoad("modelAnnounceVoice", "...")
	vars.config.capacity_alarm_thresh = system.pLoad("capacity_alarm_thresh", 20)
	vars.config.capacity_alarm_thresh2 = system.pLoad("capacity_alarm_thresh2", 30)
	vars.config.voltage_alarm_thresh = system.pLoad("voltage_alarm_thresh", 350)	
	vars.config.timeToCount = system.pLoad("timeToCount", 120)	
	vars.config.Akku1ID = system.pLoad("Akku1ID", 0)
	vars.config.Akku2ID = system.pLoad("Akku2ID", 0)
	vars.config.gyChannel = system.pLoad("gyChannel", 17) -- going to form only	
	vars.config.gyro_output = system.pLoad("gyro_output", 0) -- coming from form only	
	vars.config.rpm2_faktor = system.pLoad("rpm2_faktor", 100)
	
	-- Schalter:
	file = io.readall("Apps/"..vars.appName.."/"..vars.model.."_config.jsn", "r") 
	if file then 
		obj = json.decode(file)
		vars.switchInfo = obj[3]
	end
	vars.switches.anCapaSw = system.pLoad("anCapaSw")
	vars.switches.anCapaValSw = system.pLoad("anCapaValSw")
	vars.switches.anVoltSw = system.pLoad("anVoltSw")
	vars.switches.akkuSw = system.pLoad("akkuSw")	
	vars.switches.timeSw = system.pLoad("timeSw")
	vars.switches.engineSw = system.pLoad("engineSw")
	vars.switches.engineOffSw = system.pLoad("engineOffSw")
	vars.switches.resSw = system.pLoad("resSw")
	
	vars.todayCount = system.pLoad("todayCount", 0)
	vars.lastDay = system.pLoad("lastDay", 0)
	
	boxvisible()
	loadStartOrder()
	loadBat()

	
	today = system.getDateTime()	
	intToday = math.floor(system.getTime() / 86400)
	if vars.lastDay < intToday then
		vars.todayCount = 0
		system.pSave("lastDay", intToday)
		system.pSave("todayCount", 0)
	end
	
	day = string.format("%02d.%02d.%02d", today.day, today.mon, today.year)
	owner = system.getUserName()
	lModel = lcd.getTextWidth(FONT_MINI,string.format(vars.model))
	lli = 160 - lcd.getTextWidth(FONT_MINI,string.format(vars.appName.." - 2 - "..owner)) -  lModel / 2
	
	for i = 1, lli/3.2 do spaceLe = spaceLe.." " end
	for i = 1, (160 - lModel / 2 - lcd.getTextWidth(FONT_MINI,string.format(day)))/3.2 do spaceRi = spaceRi.." " end
	Title1 = vars.appName.." - 1 - "..owner..spaceLe.. vars.model..spaceRi..day
	Title2 = vars.appName.." - 2 - "..owner..spaceLe.. vars.model..spaceRi..day
	system.registerForm(1, MENU_MAIN, vars.appName, setupForm, keyForm, nil, closeForm)
	system.registerTelemetry(1,Title1, 4, Window1) -- registers a full size Window  
	system.registerTelemetry(2,Title2, 4, Window2)

	--unrequire("wifi")	-- there is no hardware present for this module
	--unrequire("io")	-- can be unloaded if no other App loaded uses file IO 

	Screen = require (vars.appName.."/Screen")
	vars = Screen.init(vars)
	
	if(vars.config.modelAnnounceVoice ~= "...") then system.playFile(vars.config.modelAnnounceVoice, AUDIO_QUEUE) end
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
return {init=init, loop=loop, author="dit71", version=vars.Version, name=vars.appName}
