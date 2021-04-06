-- #############################################################################
-- # Calculated Capacity Gas - Lua application for JETI DC/DS transmitters
-- #
-- # Copyright (c) 2020, Walter Loetscher
-- # All rights reserved.
-- #
-- # License: Share alike
-- # Can be used and changed non commercial
-- #
-- # Version G-4.2m mute without Alarms, Tested with DS16, .LC File Recommended
-- # Change: New Global Variable "Calca_sgKnockOff" instead off Local "sKnockOff"
-- # Global Variables used for interchange with "Display" Lua App of Thorn
-- #############################################################################
--------------------------------------------------------------------------------
-- Locals
local appName, version = "CalCa-Gas", "G-4.2m"
local sThrustControl, sCapacity, sAltCapacity, sThrust100, sThrust75, sThrust50, sThrust25, sThrust00  -- Saved Values
local sSafetySwitch, sResetSwitch, sAccuSwitch, sReport, sResetRem
local vrs, vss, vgs, acs, vrr, actualFuel, memFuel, trans		                                       	   -- reset, safety, report, accu, Reset Reminder 
local init, loop, author, i, diff
local t = {}                                                                                           -- t = Throttle 0-40
local state, change, resetCount, acName = 0, true, 0, 0, "Gas"         -- state: 0=Prog.Start 1=initialized 2=eng stop 3=eng forced idle(electro) 4=eng running
local sMultFlight, sIntCap, actualTime, resReminder = 2, 1000000, 0, 0
local throttle, addThrottle, avgThrottle, LoopCount = nil, 0, 0, 0
local maxFuel = 1000000
local sAltEn, delay, mem, debugmem = 0, 0, 0, 0
-- Globals
Calca_dispGas, Calca_selTank, Calca_throttle, Calca_sAcType, Calca_countdown = 100, 0, 0, 1, 0
--------------------------------------------------------------------------------
-- Read translations
local function setLanguage()
		local lng = system.getLocale()
    local file = io.readall("Apps/CalCa-Gas/CalCa-Gas.jsn")
    local obj = json.decode(file)
    if(obj) then
        trans = obj[lng] or obj[obj.default]
    end
end
--------------------------------------------------------------------------------
-- Telemetry and Data Verification
local function printTelem()
	if throttle then
	lcd.drawText(4,0,string.format("%s%%",Calca_dispGas),FONT_MAXI)
	lcd.drawNumber(5,34,Calca_selTank,FONT_NORMAL)
	lcd.drawText(110,0,acName,FONT_MINI)
	if acName ~= "Gas" then lcd.drawText(116,10,"- > " .. Calca_countdown,FONT_MINI) end
	lcd.drawText(45,34,"mL Fuel")	
	lcd.drawNumber(15,50,Calca_throttle,FONT_NORMAL)
	lcd.drawText(45,50,trans.throttle)		
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
local function atChanged(value)
	Calca_sAcType=value
	system.pSave("Calca_sAcType",value)
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
local function rrChanged(value)
	sResetRem=value
	system.pSave("sResetRem",value)
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
local function initSwitches()
	throttle = system.getInputsVal(sThrustControl)
	vss = system.getInputsVal(sSafetySwitch)
	vrs = system.getInputsVal(sResetSwitch)
	vrr = system.getInputsVal(sResetRem)
	vgs = system.getInputsVal(sReport)
	acs = system.getInputsVal(sAccuSwitch)
	if vss == nil then vss = 0 end
	if vrr == nil then vrr = 0 end
	if vrs == nil then vrs = 0 end
	if vgs == nil then vgs = 0 end
	if acs == nil then acs = 0 end
end
--------------------------------------------------------------------------------
local function resetCountdown()
	if Calca_sAcType == 1 then Calca_countdown = 0 end
	if Calca_sAcType == 2 then Calca_countdown = 2 end
	if Calca_sAcType == 3 then Calca_countdown = 4 end
end
--------------------------------------------------------------------------------
local function jetStart()
	if Calca_countdown == 4 and throttle > 0.9 then Calca_countdown = 3 end
	if Calca_countdown == 3 and throttle < -0.9 then Calca_countdown = 2 end
	if Calca_countdown == 2 and throttle > 0.9 then Calca_countdown = 1 end
	if Calca_countdown == 1 and throttle < -0.9 then Calca_countdown = 0 end
end
--------------------------------------------------------------------------------
local function checkReset() 
	if resetCount > 30 and resetCount < 100 then
		actualFuel = memFuel
		system.playFile("/Apps/CalCa-Gas/CalLongReset.wav", AUDIO_IMMEDIATE)
		resReminder = 0
	end
	if resetCount > 0 and resetCount < 31 then
		actualFuel = maxFuel
		system.playFile("/Apps/CalCa-Gas/CalShortReset.wav", AUDIO_IMMEDIATE)
		resReminder = 0
	end
	if resetCount == 100 then
		actualFuel = memFuel
		system.playFile("/Apps/CalCa-Gas/CalLongReset.wav", AUDIO_IMMEDIATE)
		resReminder = 0
	end
end
--------------------------------------------------------------------------------
local function getValues()
	if sAltEn == 1 and sAltCapacity > 0 then Calca_selTank = sAltCapacity
	else Calca_selTank = sCapacity
	end
	if dbdis_tank_volume and dbdis_tank_volume > 0 then Calca_selTank = dbdis_tank_volume end         -- Zeile für dbdis
	t[0] = sThrust00 * 100000 / Calca_selTank / 6
	t[10] = sThrust25 * 100000 / Calca_selTank / 6
	t[20] = sThrust50 * 100000 / Calca_selTank / 6
	t[30] = sThrust75 * 100000 / Calca_selTank / 6
	t[40] = sThrust100 * 100000 / Calca_selTank / 6
end
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
local function checkSwitches()
		if vrs == 1 then resetCount = resetCount + 1 
			else checkReset()
			resetCount = 0	
		end
		if resetCount == 100 then 
			checkReset()
			elseif resetCount == 102 then resetCount = 101	
		end
		if vgs == 1 then 
		delay = delay + 1
			if delay == 1 then system.playNumber(Calca_dispGas, 0, "%") end
			if delay == 100 then delay = 0 end
		else
		delay = 0
		end
		if acs == 1 and sAltEn == 0 then sAltEn = 2 end
		if acs == -1 and sAltEn == 2 then sAltEn = 1 change = true system.pSave("sAltEn", sAltEn) end
		if acs == 1 and sAltEn == 1 then sAltEn = 3 end
		if acs == -1 and sAltEn == 3 then sAltEn = 0 change = true system.pSave("sAltEn", sAltEn) end
end
--------------------------------------------------------------------------------
local function initialize()
	if sMultFlight == 1 then actualFuel = sIntCap	
	else
	actualFuel = maxFuel	
	end
	actualTime = system.getTimeCounter()
	memFuel = sIntCap															-- store value for short reset
	resetCountdown()
	state = 1
end
--------------------------------------------------------------------------------
local function newValues()
	getValues() curve() fill()
	if Calca_sAcType == 1 then acName = "Gas" end
	if Calca_sAcType == 2 then acName = "Jetcat" end
	if Calca_sAcType == 3 then acName = "Frank" end
	change = false
end
--------------------------------------------------------------------------------
local function checkState()
	if vss == 1 then
		state = 2																-- Eng stop
		resetCountdown()
		if Calca_sAcType == 1 then resReminder = 1 end
	end
	if vss < 1 and Calca_sAcType == 1 then Calca_countdown = 0 end
	if vss < 1 and Calca_countdown == 0 then state = 4 end							-- Eng running
	if vss < 1 and Calca_countdown > 0 then jetStart() end							-- Eng starting
	if state == 4 and Calca_sAcType == 1 then
		if resReminder == 1 then
			if (vrr < -0.3 and vrr > -0.9) or vrr > 0.3 then
			system.playFile("/Apps/CalCa-Gas/CalCheckReset.wav", AUDIO_IMMEDIATE)
			resReminder = 0
			end
		end
	end
end
--------------------------------------------------------------------------------
local function printInfos()
end
--------------------------------------------------------------------------------
-- Loop
local function loop()
	if state == 0 then initialize() end
	if change == true then newValues() end
	initSwitches()
	if throttle then
		checkState()
		checkSwitches()		
		Calca_throttle = math.floor((throttle * 100 + 100) / 2 + 0.5)
		if system.getTimeCounter() >= (actualTime + 1000) 
		then				
			actualTime = (actualTime + 1000)
				if LoopCount == 0 then LoopCount = 1 end								-- Error Trap
			avgThrottle = math.floor(addThrottle / LoopCount * 0.4 + 0.5)
				if maxFuel == 0 then maxFuel = 1 print("maxFuelError") end				-- Error Trap
			if state == 4 then actualFuel = actualFuel - t[avgThrottle] end								-- Fuel
			if actualFuel < 0 then actualFuel = 0 end
			Calca_dispGas = (actualFuel // 1000) / 10
				if Calca_selTank == 0 then Calca_selTank = 1 print("capacityError") end				-- Error Trap																					-- Electro
			LoopCount = 0
			addThrottle = 0
			icChanged(actualFuel)																		-- Fuel
		else
			addThrottle = addThrottle + Calca_throttle
			LoopCount = LoopCount + 1
			if LoopCount == 10 then collectgarbage() end
		end	
	end
	printInfos()
end
--------------------------------------------------------------------------------
-- Form Initialization
local function initForm(subform)
	local acOptions = {trans.gas, trans.jetcat, trans.frank}
	local mfOptions = {trans.yes, trans.no}
	form.addLabel({label= trans.mand, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttleControl, font=FONT_BOLD})
	form.addInputbox(sThrustControl,true,tcChanged, {font=FONT_BOLD})
	form.addLabel({label=trans.prop, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label=trans.type, font=FONT_BOLD})
	form.addSelectbox(acOptions, Calca_sAcType, false, atChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.capa, font=FONT_BOLD})
	form.addIntbox(sCapacity,25,20000,0,0,25,caChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle100, font=FONT_BOLD})
	form.addIntbox(sThrust100,0,10000,0,0,1,T100Changed, {font=FONT_BOLD})
	form.addLabel({label= trans.mL, font=FONT_MINI})
	form.addLabel({label="___________________________________________________________"})
	form.addLabel({label= trans.optional, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttle75, font=FONT_BOLD})
	form.addIntbox(sThrust75,-1,10000,0,0,1,T75Changed, {font=FONT_BOLD})
	form.addLabel({label= trans.auto, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.throttle50, font=FONT_BOLD})
	form.addIntbox(sThrust50,-1,10000,0,0,1,T50Changed, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle25, font=FONT_BOLD})
	form.addIntbox(sThrust25,-1,10000,0,0,1,T25Changed, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.throttle0, font=FONT_BOLD})
	form.addIntbox(sThrust00,0,32767,0,0,1,T00Changed, {font=FONT_BOLD})
	form.addLabel({label= trans.remark, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.safety, font=FONT_BOLD})
	form.addInputbox(sSafetySwitch,true,swChanged, {font=FONT_BOLD})
	form.addRow(2)
	form.addLabel({label= trans.reset, font=FONT_BOLD})
	form.addInputbox(sResetSwitch,true,rsChanged, {font=FONT_BOLD})
	form.addLabel({label= trans.toggle, font=FONT_MINI})
	form.addRow(2)
	form.addLabel({label= trans.reminder, font=FONT_BOLD})
	form.addInputbox(sResetRem,true,rrChanged, {font=FONT_BOLD})
	form.addLabel({label= trans.prop2, font=FONT_MINI})
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
	Calca_sAcType = system.pLoad("Calca_sAcType",1 )				-- Which AC Type
	sCapacity = system.pLoad("sCapacity",2000)			-- Capacity mAh or mL
	sThrust100 = system.pLoad("sThrust100",500)			-- Current Throttle 100%
	sThrust75 = system.pLoad("sThrust75",-1)			-- Current Throttle 75%
	sThrust50 = system.pLoad("sThrust50",-1)			-- Current Throttle 50%
	sThrust25 = system.pLoad("sThrust25",-1)			-- Current Throttle 25%
	sThrust00 = system.pLoad("sThrust00",100)			-- Current Throttle 0%
	sSafetySwitch = system.pLoad("sSafetySwitch")		-- Engine Safety Switch
	sResetSwitch = system.pLoad("sResetSwitch")			-- Reset capacity to 100%
	sResetRem = system.pLoad("sResetRem")				-- Reset Reminder	
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
