-- #############################################################################
-- # Calculated Capacity Electro - Lua application for JETI DC/DS transmitters
-- #
-- # Copyright (c) 2020, Walter Loetscher
-- # All rights reserved.
-- #
-- # License: Share alike
-- # Can be used and changed non commercial
-- #
-- # Version E-4.1-dbdis Tested with DS16, .LC File Recommended
-- # Global Variables used for interchange with "Display" Lua App of Thorn
-- #############################################################################
-- dbdis Version to interact with the dbdis app Version 3.0 and following
-- #############################################################################
-- the original files you can find here: http://swiss-aerodesign.com/calculated-capacity.html
--------------------------------------------------------------------------------
-- Locals
local appName, version = "CalCa-Elec", "E-4.1-dbdis"
local sThrustControl, sCapacity, sAltCapacity, sThrust100, sThrust75, sThrust50, sThrust25, sThrust00,
      sKnockOff, sSafetySwitch, sResetSwitch, sAccuSwitch, sReport, actualFuel,
			vrs, vss, vgs, acs, idle, trans
local author, i, diff
local t = {}                             -- t = Throttle 0-40
local start, change, mandDatas = true, true, false
local alarm50, alarm25, alarm20, alarm15, alarm10, alarmknockoff, alarmbingo = true, true, true, true, true, true, true
local sMultFlight, sIntCap, actualTime = 2, 1000000, 0
local throttle, addThrottle, avgThrottle, LoopCount = nil, 0, 0, 0, 1
local cellDec, maxFuel, coe = 20, 1000000, 1                                                       
local sAltEn, delay, mem, debugmem = 0, 0, 0, 0
-- Globals
Calca_dispFuel, Calca_capacity, Calca_thrust, Calca_cRate, Calca_sBingo = 100, 0, 0, 0, 0
--------------------------------------------------------------------------------
-- Read translations
local function setLanguage()
		local lng = system.getLocale()
    local file = io.readall("Apps/CalCa-Elec/CalCa-Elec.jsn")
    local obj = json.decode(file)
    if(obj) then
        trans = obj[lng] or obj[obj.default]
    end
end
--------------------------------------------------------------------------------
-- Telemetry and Data Verification
local function printTelem()
	if mandDatas then
	lcd.drawText(10,0,string.format("%s%%",Calca_dispFuel),FONT_MAXI)
	lcd.drawNumber(5,34,Calca_capacity,FONT_NORMAL)
	lcd.drawText(45,34,"mAh")	
	lcd.drawNumber(15,50,Calca_thrust,FONT_NORMAL)
	lcd.drawText(45,50,trans.throttle)
		if Calca_cRate > 0 then
			lcd.drawText(80,34,string.format("%02dC",Calca_cRate, "C"),FONT_NORMAL)
		end
	else
	lcd.drawText(10,10, trans.missing,FONT_NORMAL)
	end
	collectgarbage()
end

--------------------------------------------------------------------------------
-- Save
local function tcChanged(value)
	sThrustControl=value
	system.pSave("sThrustControl",value)
	change = true
end
local function caChanged(value)
	sCapacity=value
	system.pSave("sCapacity",value)
	change = true
end
local function acChanged(value)
	sAltCapacity=value
	system.pSave("sAltCapacity",value)
	change = true
end
local function T100Changed(value)
	sThrust100=value
	system.pSave("sThrust100",value)
	change = true
end
local function T75Changed(value)
	sThrust75=value
	system.pSave("sThrust75",value)
	change = true
end
local function T50Changed(value)
	sThrust50=value
	system.pSave("sThrust50",value)
	change = true
end
local function T25Changed(value)
	sThrust25=value
	system.pSave("sThrust25",value)
	change = true
end
local function T00Changed(value)
	sThrust00=value
	system.pSave("sThrust00",value)
	change = true
end
local function koChanged(value)
	sKnockOff=value
	system.pSave("sKnockOff",value)
end
local function biChanged(value)
	Calca_sBingo=value
	system.pSave("Calca_sBingo",value)
end
local function swChanged(value) -- 1=Safe, -1=Disarmed, 0=not set
	sSafetySwitch=value
	system.pSave("sSafetySwitch",value)
	change = true
end
local function rsChanged(value) -- 0=Reset, -1=off
	sResetSwitch=value
	system.pSave("sResetSwitch",value)
	change = true
end
local function rfChanged(value)
	sReport=value
	system.pSave("sReport",value)
	change = true
end
local function mfChanged(value) -- 0=Reset, -1=off
	sMultFlight=value
	system.pSave("sMultFlight",value)
	change = true
end
local function icChanged(value)
	sIntCap=value
	system.pSave("sIntCap",value)
end
local function asChanged(value) -- 1=Safe, -1=Disarmed, 0=not set
	sAccuSwitch=value
	system.pSave("sAccuSwitch",value)
	change = true
end
collectgarbage()
--------------------------------------------------------------------------------
-- Functions
local function resetAlarm()
	alarm50 = true
	alarm25 = true
	alarm20 = true
	alarm15 = true
	alarm10 = true
	alarmknockoff = true
	alarmbingo = true
end
local function getValues()
	if sAltEn == 1 and sAltCapacity > 0 then Calca_capacity = sAltCapacity
	else Calca_capacity = sCapacity
	end	
	if dbdis_capacity and dbdis_capacity > 1 then Calca_capacity = dbdis_capacity end         -- diese Zeile hinzugefügt###########################
	print(sThrust00.."-"..sThrust25)
	t[0] = sThrust00 * 10000 / Calca_capacity / 3.6
	t[10] = sThrust25 * 100000 / Calca_capacity / 3.6
	t[20] = sThrust50 * 100000 / Calca_capacity / 3.6
	t[30] = sThrust75 * 100000 / Calca_capacity / 3.6
	t[40] = sThrust100 * 100000 / Calca_capacity / 3.6
end
local function initDatas()
	if sMultFlight == 1 then actualFuel = sIntCap	
	else
	actualFuel = maxFuel	
	end
	actualTime = system.getTimeCounter()
	start = false
end
local function checkSwitches()
	throttle = system.getInputsVal(sThrustControl)
	vss = system.getInputsVal(sSafetySwitch)
	vrs = system.getInputsVal(sResetSwitch)
	vgs = system.getInputsVal(sReport)
	acs = system.getInputsVal(sAccuSwitch)
		if vrs == 1 then 
		actualFuel = maxFuel 
		resetAlarm() 
		end
		if vgs == 1 then 
		delay = delay + 1
			if delay == 1 then system.playNumber(Calca_dispFuel, 0, "%") end
			if delay == 100 then delay = 0 end
		else
		delay = 0
		end
		if acs == 1 and sAltEn == 0 then sAltEn = 2 end
		if acs == -1 and sAltEn == 2 then sAltEn = 1 change = true system.pSave("sAltEn", sAltEn) end
		if acs == 1 and sAltEn == 1 then sAltEn = 3 end
		if acs == -1 and sAltEn == 3 then sAltEn = 0 change = true system.pSave("sAltEn", sAltEn) end
end
local function curve()
	if t[30] < 0 then
		if t[20] > -1 then t[30] = t[20]+((t[40]-t[20])//2)
			elseif t[10] > -1 then
				t[20] = ((t[40]-t[10])//3) + t[10]
				t[30] = t[40]-((t[40]-t[10])//3)
			else t[30] = t[40] - ((t[40] - t[0])//4)		
		end
	end
	if t[20] < 0 then
		if t[10] > -1 then t[20] = t[10]+((t[30]-t[10])//2)
			else t[20] = t[30] - ((t[30]-t[0])//3)
		end	
	end
	if t[10] < 0 then t[10] = t[0]+((t[20]-t[0])//2)	end
end
local function fill()
	diff = (t[10] - t[0]) / 10
	for i = 1, 9 do t[i] = t[i-1] + diff end
	diff = (t[20] - t[10]) / 10
	for i = 11, 19 do t[i] = t[i-1] + diff end
	diff = (t[30] - t[20]) / 10
	for i = 21, 29 do t[i] = t[i-1] + diff end
	diff = (t[40] - t[30]) / 10
	for i = 31, 39 do t[i] = t[i-1] + diff end
end
local function checkState()
	if (vss == nil) or (vss == 0) then vss = -1 end
end
local function alarm()
	if (Calca_sBingo ~= 0) or (sKnockOff ~= 0) then
		if Calca_dispFuel <= 50 and alarm50 then
		system.playNumber(50, 0, "%")
		alarm50 = false
		end
		if Calca_dispFuel <= (sKnockOff) and alarmknockoff then
		system.playFile("/Apps/CalCa-Elec/CalPreWarn.wav", AUDIO_QUEUE)
		alarmknockoff = false
		end
		if Calca_dispFuel <= (Calca_sBingo) and alarmbingo then
		system.playFile("/Apps/CalCa-Elec/CalWarn.wav", AUDIO_IMMEDIATE)
		alarmbingo = false
		end
	else
	if Calca_dispFuel <= 50 and alarm50 then
		system.playNumber(50, 0, "%")
		alarm50 = false
	end
	if Calca_dispFuel <= 25 and alarm25 then
		system.playNumber(25, 0, "%")
		alarm25 = false
	end
	if Calca_dispFuel <= 20 and alarm20 then
		system.playNumber(20, 0, "%")
		alarm20 = false
	end
	if Calca_dispFuel <= 15 and alarm15 then
		system.playNumber(15, 0, "%")
		alarm15 = false
	end
	if Calca_dispFuel <= 10 and alarm10 then
		system.playNumber(10, 0, "%")
		alarm10 = false
	end
	end
end
local function info()	
	Calca_cRate = math.floor(sThrust100 / Calca_capacity * 100 + 0.5)
end
--------------------------------------------------------------------------------
local function checkConditions()
	if (throttle and (sThrust100 > -1))
	then mandDatas = true 
	else mandDatas = false 
	end
	if dbdis_capacity and dbdis_capacity > 1 and dbdis_capacity ~= Calca_capacity then change = true end  -- diese Zeile hinzugefügt################################
	if change == true then 
		getValues() curve() fill() 
		idle = t[0]
		change = false 
	end
	if start then initDatas() end
	checkSwitches()
end
--------------------------------------------------------------------------------
-- print Infos
local function printInfos()
end
--------------------------------------------------------------------------------
-- Loop
local function loop()
	checkConditions()		
	if mandDatas then
		checkState()
		Calca_thrust = math.floor((throttle * 100 + 100) / 2 + 0.5)
		if system.getTimeCounter() >= (actualTime + 1000) 
		then				
			actualTime = (actualTime + 1000)
				if LoopCount == 0 then LoopCount = 1 end								-- Error Trap
			avgThrottle = math.floor(addThrottle / LoopCount * 0.4 + 0.5)
				if maxFuel == 0 then maxFuel = 1 print("maxFuelError") end				-- Error Trap
			coe = (100 - cellDec + (cellDec * actualFuel / maxFuel)) / 100
			if vss == -1  then actualFuel = math.floor((actualFuel - coe * t[avgThrottle]) + 0.5)
			elseif vss == 1 then actualFuel = math.floor((actualFuel - coe * idle) + 0.5)			
			end
			if actualFuel < 0 then actualFuel = 0 end
			Calca_dispFuel = (actualFuel // 1000) / 10
				if Calca_capacity == 0 then Calca_capacity = 1 print("capacityError") end			-- Error Trap
			info()
			alarm()
			LoopCount = 0
			addThrottle = 0
			if sMultFlight == 1 then icChanged(actualFuel) end
		else
			addThrottle = addThrottle + Calca_thrust
			LoopCount = LoopCount + 1
			if LoopCount == 10 then collectgarbage() end
		end	
	end
	--printInfos()
end
--------------------------------------------------------------------------------
-- Form Initialization
local function initForm(subform)
	local mfOptions = {trans.yes, trans.no}
	form.addLabel({label= trans.mand, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttleControl, font=FONT_BOLD})
	form.addInputbox(sThrustControl,true,tcChanged, {font=FONT_BOLD})
	form.addLabel({label=trans.prop, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.capa, font=FONT_BOLD})
	form.addIntbox(sCapacity,25,10000,0,0,25,caChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle100, font=FONT_BOLD})
	form.addIntbox(sThrust100,0,10000,0,1,1,T100Changed, {font=FONT_BOLD})
	form.addLabel({label="  --> Ampère ", font=FONT_MINI})
	form.addLabel({label="___________________________________________________________"})
	form.addLabel({label= trans.optional, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttle75, font=FONT_BOLD})
	form.addIntbox(sThrust75,-1,10000,0,1,1,T75Changed, {font=FONT_BOLD})
	form.addLabel({label= trans.auto, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttle50, font=FONT_BOLD})
	form.addIntbox(sThrust50,-1,10000,0,1,1,T50Changed, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle25, font=FONT_BOLD})
	form.addIntbox(sThrust25,-1,10000,0,1,1,T25Changed, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle0, font=FONT_BOLD})
	form.addIntbox(sThrust00,0,32767,0,2,1,T00Changed, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.preWarn, font=FONT_BOLD})
	form.addIntbox(sKnockOff,0,100,0,0,1,koChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.warn, font=FONT_BOLD})
	form.addIntbox(Calca_sBingo,0,100,0,0,1,biChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.safety, font=FONT_BOLD})
	form.addInputbox(sSafetySwitch,true,swChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.reset, font=FONT_BOLD})
	form.addInputbox(sResetSwitch,true,rsChanged, {font=FONT_BOLD})
	form.addLabel({label= trans.toggle, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.report, font=FONT_BOLD})
	form.addInputbox(sReport,true,rfChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.multi, font=FONT_BOLD})
	form.addSelectbox(mfOptions, sMultFlight, 2, mfChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.other, font=FONT_BOLD})
	form.addIntbox(sAltCapacity,0,10000,0,0,25,acChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.otherToggle, font=FONT_BOLD})
	form.addInputbox(sAccuSwitch,true,asChanged, {font=FONT_BOLD})
	collectgarbage()
end
--------------------------------------------------------------------------------
-- Init
local function init()
	for i = 1, 40 do t[i] = 0 end
	system.registerForm(1,MENU_MAIN,appName .." Version ".. version,initForm , nil,printForm)
	system.registerTelemetry(1,appName .." Version ".. version,2,printTelem)
	-- Saved Items
	sThrustControl = system.pLoad("sThrustControl",nil)	-- Throttle (P4 for Mode 2), use Proportional!
	sCapacity = system.pLoad("sCapacity",1000)			-- Capacity mAh or mL
	sThrust100 = system.pLoad("sThrust100",200)			-- Current Throttle 100%
	sThrust75 = system.pLoad("sThrust75",100)			-- Current Throttle 75%
	sThrust50 = system.pLoad("sThrust50",50)			-- Current Throttle 50%
	sThrust25 = system.pLoad("sThrust25",-1)			-- Current Throttle 25%
	sThrust00 = system.pLoad("sThrust00",5)				-- Current Throttle 0%
	sKnockOff = system.pLoad("sKnockOff",35)         	-- Prewarning
	Calca_sBingo = system.pLoad("Calca_sBingo",30)               	-- Final Warning
	sSafetySwitch = system.pLoad("sSafetySwitch")		-- Engine Safety Switch
	sResetSwitch = system.pLoad("sResetSwitch")			-- Reset capacity to 100%
	sMultFlight = system.pLoad("sMultFlight",2)			-- Value Stored for next Flight	
	sReport = system.pLoad("sReport")               	-- Report actual Capacity
	sIntCap = system.pLoad("sIntCap",1000000)			-- Store Value for multiple Flights
	sAltCapacity = system.pLoad("sAltCapacity",0)		-- Capacity mAh or mL
	sAccuSwitch = system.pLoad("sAccuSwitch")			-- Switch to Alternate Accu 	
	sAltEn = system.pLoad("sAltEn",0)					-- 0 = primary Accu, 1 = alternate Accu
	collectgarbage()
end
--------------------------------------------------------------------------------
setLanguage()
collectgarbage()
return {init=init, loop=loop, author="Walter Loetscher", version=version, name=appName}
--------------------------------------------------------------------------------
