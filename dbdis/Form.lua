local device_label_list = {}
local device_id_list = {}
local sensor_lists = {}
local deviceIndex = 0
local show
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
	local i
	show = true
	if ( sens[1] ~= deviceId and sens[2] ~= 0 ) then	-- sensor selectet from another device 
		for i in next, device_id_list do
			if ( sens[1] == device_id_list[i] ) then	-- this other device is still present
				show = false
			end	
		end	
	end
end


local function setup(vars, Version, senslbls)
	local i,j
	local sensCat = {}
	local senslbl

	local function saveFlights()
		local file = io.open("Apps/"..vars.appName.."/"..vars.model..".txt", "w+")
		if file then
		  io.write(file, vars.totalCount.."\n")
		  io.write(file, vars.totalFlighttime.."\n")
		  io.close(file)
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
		form.addSelectbox(senslbls.catName,vars.catsel,true, function(value)
			vars.catsel = value
			system.pSave("catsel", vars.catsel)
			form.reinit()
		end)
		
		for i, sensCat in ipairs(senslbls.cat) do
			if sensCat == senslbls.cat[vars.catsel-1] or vars.catsel == 1 then
				form.addSpacer(318,7)
				for j, senslbl in pairs(senslbls[sensCat]) do
					form.addRow(2) 	
					form.addLabel({label = vars.trans[senslbl]})
					check_other_device(vars[senslbl], vars.deviceId)
					form.addSelectbox(sensor_lists[deviceIndex], vars[senslbl][2], true,
									function (value)
										if sensor_lists[deviceIndex][value] == "..." then value = 0 end
										vars[senslbl][1] = vars.deviceId
										vars[senslbl][2] = value
										system.pSave(senslbl, vars[senslbl])
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

	form.addRow(2)
	form.addLabel({label=vars.trans.anCapaSw, width=220})
	form.addInputbox(vars.anCapaSw,true,
						function (value)
							vars.anCapaSw = value
							system.pSave("anCapaSw", vars.anCapaSw)
						end )

	form.addRow(2)
	form.addLabel({label=vars.trans.anVoltSw, width=220})
	form.addInputbox(vars.anVoltSw,true,
						function (value)
							vars.anVoltSw = value
							system.pSave("anVoltSw", vars.anVoltSw)
						end )
        
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label3,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmVoice, width=140})
	form.addAudioFilebox(vars.voltage_alarm_voice,
						function (value)
							vars.voltage_alarm_voice=value
							system.pSave("voltage_alarm_voice", vars.voltage_alarm_voice)
						end )
        
	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmVoice, width=140})
	form.addAudioFilebox(vars.capacity_alarm_voice,
						function (value)
							vars.capacity_alarm_voice = value
							system.pSave("capacity_alarm_voice", vars.capacity_alarm_voice)
						end )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label2,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.capacitymAh, width=210})
	form.addIntbox(vars.capacity1, 0, 32767, 0, 0, 10,
						function (value)
							vars.capacity1 = value
							system.pSave("capacity1", vars.capacity1)
						end, {label=" mAh"} )
	
	form.addRow(2)
	form.addLabel({label=vars.trans.capacity2mAh, width=210})
	form.addIntbox(vars.capacity2, 0, 32767, 0, 0, 10,
						function (value)
							vars.capacity2 = value
							system.pSave("capacity2", vars.capacity2)
						end, {label=" mAh"} )
						
	form.addRow(2)
	form.addLabel({label=vars.trans.akkuSW, width=210})-- Switch for 2nd Battery
	form.addInputbox(vars.akkuSw,true,
						function (value)
              vars.akkuSw = value
              system.pSave("akkuSw", vars.akkuSw)
						end)						
						

	form.addRow(2)
	form.addLabel({label=vars.trans.cellcnt, width=210})
	form.addIntbox(vars.cell_count, 1, 14, 1, 0, 1,
						function (value)
							vars.cell_count = value
							system.pSave("cell_count", vars.cell_count)
						end, {label=" S"} )

	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmThresh, width=210 })
	form.addIntbox(vars.capacity_alarm_thresh, 0, 100, 0, 0, 1,
						function (value)
							vars.capacity_alarm_thresh = value
							system.pSave("capacity_alarm_thresh", vars.capacity_alarm_thresh)
						end, {label=" %"} )
    
	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmThresh, width=210})
	form.addIntbox(vars.voltage_alarm_thresh,0,10000,0,2,5,
						function (value)
							vars.voltage_alarm_thresh=value
							system.pSave("voltage_alarm_thresh", vars.voltage_alarm_thresh)
						end, {label=" V"} )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label4,font=FONT_BOLD})  

	form.addRow(2)
	form.addLabel({label=vars.trans.timeSw, width=210})-- Schalter für Flugzeit
	form.addInputbox(vars.timeSw,true,
						function (value)
              vars.timeSw = value
              system.pSave("timeSw", vars.timeSw)
						end)

	form.addRow(2)
	form.addLabel({label=vars.trans.engineSw, width=210})-- Schalter für Motorlaufzeit
	form.addInputbox(vars.engineSw,true,
						function (value)
              vars.engineSw = value
							system.pSave("engineSw", vars.engineSw)
						end)
						
	form.addRow(2)
	form.addLabel({label=vars.trans.timeToCount, width=210})-- Zeitdauer für Flugerkennung
	form.addIntbox(vars.timeToCount, 0, 999, 0, 0, 1, 
						function (value)
							vars.timeToCount = value
							system.pSave("timeToCount", vars.timeToCount)
						end, {label=" s"} )
	form.addRow(2)
	form.addLabel({label=vars.trans.resSw, width=210})
	form.addInputbox(vars.resSw,true,
						function (value)
							vars.resSw = value
							system.pSave("resSw", vars.resSw)
						end )
						

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label5,font=FONT_BOLD}) -- Gyrokanal

	form.addRow(2)
	form.addLabel({label=vars.trans.channel, width=210})
	form.addIntbox(vars.gyChannel, 1, 17, 17, 0, 1,
						function (value)
							vars.gyChannel = value
							vars.gyro_output = output_list[vars.gyChannel]
							system.pSave("gyChannel", vars.gyChannel)
							system.pSave("gyro_output", vars.gyro_output)
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

	form.addRow(1)
	form.addLabel({label=vars.trans.appName .. " " .. Version .. " ", font=FONT_MINI, alignRight=true})
    
	collectgarbage()

	return (vars)
end

return {

	setup = setup
  

}
