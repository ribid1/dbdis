local device_label_list = {}
local device_id_list = {}
local sensor_lists = {}
local deviceIndex = 0
local show
local switchItem
local output_list = { "O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8", "O9", "O10", "O11", "O12",
							"O13", "O14", "O15", "O16", "OO"}


local function make_lists (deviceId)
	local sensor, i
	if ( not device_id_list[1] ) then	-- sensors not yet checked or rebooted
		deviceIndex = 0
		for i,sensor in ipairs(system.getSensors()) do
			if (sensor.param == 0) then	-- new multisensor/device
				device_label_list[#device_label_list + 1] = sensor.label	-- list presented in sensor select box
				device_id_list[#device_id_list + 1] = sensor.id				-- to get id from if sensor changed, same numeric indexing
				if (sensor.id == deviceId) then
					deviceIndex = #device_id_list
				end
				sensor_lists[#sensor_lists + 1] = {}			-- start new param list only containing label and unit as string
			else															-- subscript is number of param for current multisensor/device
				sensor_lists[#sensor_lists][sensor.param] = sensor.label .. "  " .. sensor.unit	-- list presented in param select box
				sensor_lists[#sensor_lists][sensor.param + 1] = "..."
			end
		end
    device_label_list[#device_label_list + 1] = "..."
	end	
end

local function check_other_device(sens, deviceId)
	
	if sens[1] ~= deviceId and sens[2] ~= 0  then	-- sensor selectet from another device 
		for i in next, device_id_list do
			if ( sens[1] == device_id_list[i] ) then	-- this other device is still present
				show = false
			end	
		end	
	end
end



local function setup(vars, senslbls)
	local switch ={}
	local temp
	local dateinamen = {}
	local confignames = {["_config.jsn"]=true}
	
	
	local function saveFlights()
		local file = io.open("Apps/"..vars.appName.."/"..vars.model..".txt", "w+")
		if file then
			io.write(file, vars.totalCount.."\n")
			io.write(file, vars.totalFlighttime.."\n")
			io.close(file)
		end
		collectgarbage()
	end 

	local function configChanged(configName, value)
		vars.config[configName] = value
		system.pSave(configName, value)
		form.setButton(1, "save",ENABLED)
		vars.changedConfig = 1
		collectgarbage()
	end
	
	
	local function switchChanged(switchName, value)
		local Invert = 1.0
		local swInfo = system.getSwitchInfo(value)
		local swTyp = string.sub(swInfo.label,1,1)
		if swInfo.assigned then
			if string.sub(swInfo.mode,-1,-1) == "I" then Invert = -1.0 end
			if swInfo.value == Invert or swTyp == "L" or swTyp =="M"  then
				vars.switches[switchName] = value
				system.pSave(switchName, value)
				form.setButton(1, "save",ENABLED)
				vars.changedConfig = 1
				vars.switchInfo[switchName] = {}
				vars.switchInfo[switchName].name = swInfo.label
				vars.switchInfo[switchName].mode = swInfo.mode
				if swTyp == "L" or swTyp =="M" then
					vars.switchInfo[switchName].activeOn = 0
				else
					vars.switchInfo[switchName].activeOn = system.getInputs(string.upper(swInfo.label))
				end
			else  					
				system.messageBox(vars.trans.switchError, 3)
				if vars.switches[switchName] then 
					form.setValue(switch[switchName],vars.switches[switchName])
				else
					form.setValue(switch[switchName],nil)
				end
			end
		else
			if vars.switchInfo[switchName] then
				vars.switches[switchName] = nil
				vars.switchInfo[switchName] = nil
				form.setButton(1, "save",ENABLED)
				system.pSave(switchName, nil)
				vars.changedConfig = 1
			end	
		end
		collectgarbage()
	end


	make_lists(vars.deviceId)

	form.setTitle(vars.trans.title)

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label0,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label = vars.trans.labelp0, width=200})

	form.addSelectbox( device_label_list, deviceIndex, true,
						function (value)
							if ( not device_id_list[1] ) then	-- no device found
								return
							end
							if (device_label_list[value] == "...") then
								vars.deviceId = 0
								deviceIndex = 0
							else
								vars.deviceId  = device_id_list[value]
								deviceIndex = value
							end
							system.pSave("deviceId", vars.deviceId)
														
							form.reinit()
						end )

	if ( device_id_list and deviceIndex > 0 ) then
		form.addRow(2)
		form.addLabel({label = vars.trans["sensCat"]})
		form.addSelectbox(vars.catName,vars.catsel,true, function(value)
			vars.catsel = value
			system.pSave("catsel", vars.catsel)
			form.reinit()
		end)
		
		for i, sensCat in ipairs(vars.cat) do
			if sensCat == vars.cat[vars.catsel-1] or vars.catsel == 1 then
				form.addSpacer(318,7)
				for j, senslbl in pairs(senslbls[sensCat]) do
					form.addRow(2) 	
					form.addLabel({label = vars.trans[senslbl]})
					show = true	
					if vars.senslbl[senslbl] then
						check_other_device(vars.senslbl[senslbl], vars.deviceId)
						temp = vars.senslbl[senslbl][2]
					else
						temp = 0
					end
					
					form.addSelectbox(sensor_lists[deviceIndex], temp, true,
									function (value)
										vars.senslbl[senslbl] = {}
										if sensor_lists[deviceIndex][value] == "..." then 
											value = 0
											vars.senslbl[senslbl] = nil
										else 
											vars.senslbl[senslbl][1] = vars.deviceId
											vars.senslbl[senslbl][2] = value									
										end
										system.pSave(senslbl, vars.senslbl[senslbl])
										vars.changeSens = 1
										form.setButton(1, "save",ENABLED)
									end,
									{enabled=show, visible=show} )	
				end
				form.addSpacer(318,7)	
			end
		end
										
	end

	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=vars.trans.label1,font=FONT_BOLD})

	form.addRow(2) -- Switch for % announcement
	form.addLabel({label=vars.trans.anCapaSw, width=220})
	switch.anCapaSw = form.addInputbox(vars.switches.anCapaSw,false,
						function (value)
							switchChanged("anCapaSw", value)
						end )
						
	form.addRow(2) -- Switch for value announcement
	form.addLabel({label=vars.trans.anValueSw, width=220})
	switch.anCapaValSw = form.addInputbox(vars.switches.anCapaValSw,false,
						function (value)
							switchChanged("anCapaValSw", value)
						end )					
						

	form.addRow(2)
	form.addLabel({label=vars.trans.anVoltSw, width=220})
	switch.anVoltSw = form.addInputbox(vars.switches.anVoltSw,false,
						function (value)
							switchChanged("anVoltSw", value)
						end )
        
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.voicefiles,font=FONT_BOLD})
	
	form.addRow(2)
	form.addLabel({label=vars.trans.modelAnnounce, width=220})
	form.addAudioFilebox(vars.config.modelAnnounceVoice,
						function (value)
							configChanged("modelAnnounceVoice", value)
						end, {width=100} )

	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmVoice, width=220})
	form.addAudioFilebox(vars.config.voltage_alarm_voice,
						function (value)
							configChanged("voltage_alarm_voice", value)
						end,{width=100} )
        

	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmVoice2, width=220})
	form.addAudioFilebox(vars.config.capacity_alarm_voice2,
						function (value)
							configChanged("capacity_alarm_voice2", value)
						end,{width=100} )
						
	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmVoice, width=220})
	form.addAudioFilebox(vars.config.capacity_alarm_voice,
						function (value)
							configChanged("capacity_alarm_voice", value)
						end,{width=100} )					
						
						

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label2,font=FONT_BOLD})
	
							
	form.addRow(2)
	form.addLabel({label="Akku 1 ID:", width=210})
	form.addIntbox(vars.config.Akku1ID, 0, 999, 0, 0, 1,
						function (value)
							configChanged("Akku1ID", value)
						end)
	
	form.addRow(2)
	form.addLabel({label="Akku 2 ID:", width=210})
	form.addIntbox(vars.config.Akku2ID, 0, 999, 0, 0, 1,
						function (value)
							configChanged("Akku2ID", value)
						end)
						
	form.addRow(2)
	form.addLabel({label=vars.trans.akkuSW, width=210})-- Switch for 2nd Battery
	switch.akkuSw = form.addInputbox(vars.switches.akkuSw,false,
						function (value)
							switchChanged("akkuSw", value)
						end)
					
	--if not Calca_dispGas then
		form.addRow(2)
		form.addLabel({label=vars.trans.tank_volume, width=210})
		form.addIntbox(vars.config.tank_volume, 0, 9900, 0, 0, 10,
							function (value)
								dbdis_tank_volume = value
								configChanged("tank_volume", value)
							end, {label=" ml"} )
	--end

							
	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmThres2, width=230 })
	form.addIntbox(vars.config.capacity_alarm_thresh2, 0, 100, 0, 0, 1,
						function (value)
							configChanged("capacity_alarm_thresh2", value)
						end, {label=" %"} )	
						
	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmThresh, width=240 })
	form.addIntbox(vars.config.capacity_alarm_thresh, 0, 100, 0, 0, 1,
						function (value)
							configChanged("capacity_alarm_thresh", value)
						end, {label=" %"} )					

    
	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmThresh, width=210})
	form.addIntbox(vars.config.voltage_alarm_thresh,0,10000,0,2,5,
						function (value)
								configChanged("voltage_alarm_thresh", value)
						end, {label=" V"} )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label4,font=FONT_BOLD})  
	-- Schalter für Flugzeit
	form.addRow(2)
	form.addLabel({label=vars.trans.timeSw, width=210})
	switch.timeSw = form.addInputbox(vars.switches.timeSw,false,
						function (value)
								vars.changeSens = 1
								switchChanged("timeSw", value)
						end)
	-- Schalter für Motorlaufzeit
	form.addRow(2)
	form.addLabel({label=vars.trans.engineSw, width=210})
	switch.engineSw = form.addInputbox(vars.switches.engineSw,false,
						function (value)
							vars.changeSens = 1
							switchChanged("engineSw", value)
						end)
	-- Schalter Motor an
	form.addRow(2)
	form.addLabel({label=vars.trans.engineOffSw, width=210})
	switch.engineOffSw = form.addInputbox(vars.switches.engineOffSw,false,
						function (value)
							vars.changeSens = 1
							switchChanged("engineOffSw", value)
						end)					
	-- Zeitdauer für Flugerkennung					
	form.addRow(2)
	form.addLabel({label=vars.trans.timeToCount, width=210})
	form.addIntbox(vars.config.timeToCount, 0, 999, 0, 0, 1, 
						function (value)
							configChanged("timeToCount", value)
						end, {label=" s"} )
	-- Resetschalter					
	form.addRow(2)
	form.addLabel({label=vars.trans.resSw, width=210})
	switch.resSw = form.addInputbox(vars.switches.resSw,false,
						function (value)
							switchChanged("resSw", value)
						end )
						

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label5,font=FONT_BOLD}) -- Gyrokanal

	form.addRow(2)
	form.addLabel({label=vars.trans.channel, width=210})
	form.addIntbox(vars.config.gyChannel, 1, 17, 17, 0, 1,
						function (value)
							configChanged("gyChannel", value)
							configChanged("gyro_output", output_list[vars.config.gyChannel])									
						end )

	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=vars.trans.history,font=FONT_BOLD}) -- History
	
	
	-- bisherige Fluganzahl setzen
	form.addRow(2)
    form.addLabel({label=vars.trans.totalCount, width=210})
    form.addIntbox(vars.totalCount, 0, 9999, 0, 0, 1, 
						function (value)
							vars.totalCount = value
							saveFlights()
						end)
	
	-- bisherige Flugzeit setzen
	
	form.addRow(2)
    form.addLabel({label=vars.trans.totalFlighttime, width=210})
	local totalFlighttimemin = math.floor(vars.totalFlighttime / 60)
    form.addIntbox(totalFlighttimemin, 0, 99999, 0, 0, 1,
						function (value)
							vars.totalFlighttime = value * 60
							saveFlights()
						end, {label=" min"} )
						
	form.addSpacer(320,10)

	
	dateinamen[1]=""
	for name, filetype, size in dir("Apps/"..vars.appName) do
		if filetype == "file" and confignames[string.sub(name,-11,-1)] then table.insert(dateinamen, name) end
	end
	table.sort(dateinamen)

	form.addRow(2)
	form.addLabel({label = vars.trans.loadConfig, width=105})
	form.addSelectbox(dateinamen,1,false, function(value)
		vars.configName = dateinamen[value]
		if vars.configName:len() > 0 then vars.changeSens = 2 end
		form.setButton(1, vars.configName:len() > 0 and "Load" or 1, vars.configName:len() > 0 and ENABLED or DISABLED)
	end, {width = 210})						

	form.addRow(1)
	form.addLabel({label=vars.trans.appName .. " " .. vars.Version .. " ", font=FONT_MINI, alignRight=true})
	

	collectgarbage()

	return (vars)
end

return {

	setup = setup
  

}
