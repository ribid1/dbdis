local vars, page
	
local function moveLine(back)
	local startleft = 5
	local rowsleft = #vars[page].leftcolumn
	local startright = startleft + rowsleft + 2
	local rowsright = #vars[page].rightcolumn
	local startnotused = startright + rowsright + 2
	local rowsnotused = #vars[page].notused
	local row = form.getFocusedRow()
	if back then
		if row < startleft then
			form.setFocusedRow(row - 1)
		elseif row == startleft then
			table.insert(vars[page].notused, vars[page].leftcolumn[1])
			table.remove(vars[page].leftcolumn, 1)
			form.setFocusedRow(startnotused + rowsnotused - 1)
		elseif row < startleft + rowsleft then
			vars[page].leftcolumn[row - startleft],vars[page].leftcolumn[row - startleft + 1]  = vars[page].leftcolumn[row - startleft + 1], vars[page].leftcolumn[row - startleft]
			form.setFocusedRow(row - 1)
		elseif row < startright then
			form.setFocusedRow(row -1)
		elseif row == startright then
			table.insert(vars[page].leftcolumn, vars[page].rightcolumn[1])
			table.remove(vars[page].rightcolumn, 1)
			form.setFocusedRow(startleft + rowsleft)
		elseif row < startright + rowsright then
			vars[page].rightcolumn[row - startright],vars[page].rightcolumn[row - startright + 1]  = vars[page].rightcolumn[row - startright + 1], vars[page].rightcolumn[row - startright]
			form.setFocusedRow(row - 1)
		elseif row < startnotused then
			form.setFocusedRow(row - 1)
		elseif row < startnotused + rowsnotused then
			table.insert(vars[page].rightcolumn, vars[page].notused[row - startnotused + 1])
			table.remove(vars[page].notused, row - startnotused + 1)
			form.setFocusedRow(startright + rowsright)
		else
			form.setFocusedRow(row -1)
		end
	else
		if row < startleft then
			form.setFocusedRow(row + 1)
		elseif row < startleft + rowsleft - 1 then
			vars[page].leftcolumn[row - startleft + 2],vars[page].leftcolumn[row - startleft + 1]  = vars[page].leftcolumn[row - startleft + 1], vars[page].leftcolumn[row - startleft + 2]
			form.setFocusedRow(row + 1)
		elseif row == startleft + rowsleft - 1 then
			table.insert(vars[page].rightcolumn,1, vars[page].leftcolumn[rowsleft])
			table.remove(vars[page].leftcolumn, rowsleft)
			form.setFocusedRow(startright - 1)
		elseif row < startright then
			form.setFocusedRow(row + 1)
		elseif row < startright + rowsright - 1 then
			vars[page].rightcolumn[row - startright + 2],vars[page].rightcolumn[row - startright + 1]  = vars[page].rightcolumn[row - startright + 1], vars[page].rightcolumn[row - startright + 2]
			form.setFocusedRow(row + 1)
		elseif row == startright + rowsright -1 then
			table.insert(vars[page].notused,1, vars[page].rightcolumn[rowsright])
			table.remove(vars[page].rightcolumn, rowsright)
			form.setFocusedRow(startnotused - 1)
		elseif row < startnotused then
			form.setFocusedRow(row + 1)
		elseif row < startnotused + rowsnotused then
			table.insert(vars[page].leftcolumn, 1, vars[page].notused[row - startnotused + 1])
			table.remove(vars[page].notused, row - startnotused + 1)
			form.setFocusedRow(startleft)
		else
			form.setFocusedRow(row + 1)
		end
	end
	vars.change[page] = 2
	
	collectgarbage()
end

local function setup(varstemp, pagetemp)
	local dateinamen = {}
	local confignames = {["_d1.jsn"]=true, ["_d2.jsn"]=true, ["_c1.txt"]=true, ["_c2.txt"]=true}
	
	vars = varstemp
	page = pagetemp
	
  	form.setTitle(vars.trans.Layout.." "..vars.trans.Page.." "..page)
	
	form.addSpacer(320,5)
	
	dateinamen[1]=""
	for name, filetype, size in dir("Apps/"..vars.appName) do
		if filetype == "file" and confignames[string.sub(name,-7,-1)] then table.insert(dateinamen, name) end
	end
	table.sort(dateinamen)

	form.addRow(2)
	form.addLabel({label = vars.trans.loadLayout, width=102})

	form.addSelectbox(dateinamen,1,false, function(value)
		vars.NameTemplate = dateinamen[value]
		form.setButton(page+1, vars.NameTemplate:len() > 0 and "Load" or (page+1), vars.NameTemplate:len() > 0 and ENABLED or DISABLED)
		vars.change[page] = 3
	end, {width = 210})	


	form.addSpacer(320,10)
	form.addRow(2)
	form.addLabel({label = (vars.trans.Leftrow.." ("..string.format("%.f",vars[page].ycalcLeft)..")"), font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

			
	for i,j in ipairs(vars[page].leftcolumn) do	
		if vars.cd[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars.cd[j].y..")",font = FONT_NORMAL, width = 210})
			form.addIntbox(vars[page].cd[j].sep, -8, 5, 2, 0, 1,
							function (value)
								vars[page].cd[j].sep = value
								vars.change[page] = 2
								form.setButton(page+1, "save",ENABLED)
							end, {font = fontLabel, width = 50})
			form.addIntbox(vars[page].cd[j].dist, -9, 160, -9, 0, 1,
							function (value)
								vars[page].cd[j].dist = value
								vars.change[page] = 2
								form.setButton(page+1, "save",ENABLED)
							end, {font = fontLabel, width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
		end
	end
	
	--form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = "----------------------------------------------------------"})
	form.addRow(2)
	form.addLabel({label = (vars.trans.Rightrow.." ("..string.format("%.f",vars[page].ycalcRight)..")"), font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

	for i,j in ipairs(vars[page].rightcolumn) do
		if vars.cd[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars.cd[j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars[page].cd[j].sep, -8, 5, 2, 0, 1,
							function (value)
								vars[page].cd[j].sep = value
								vars.change[page] = 2
								form.setButton(page+1, "save",ENABLED)
							end, {width = 50})
			form.addIntbox(vars[page].cd[j].dist, -9, 160, -9, 0, 1,
							function (value)
								vars[page].cd[j].dist = value
								vars.change[page] = 2
								form.setButton(page+1, "save",ENABLED)
							end, {width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
		end
	end
	
	--form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = "----------------------------------------------------------", enabled = false})
	form.addRow(2)
	form.addLabel({label = vars.trans.notused, font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})
	
	for i,j in ipairs(vars[page].notused) do
		if vars.cd[j] then 
			if vars.cd[j].visible then
				form.addRow(3)
				form.addLabel({label = j.." ("..vars.cd[j].y..")",font = FONT_NORMAL, width = 210})
				
				form.addIntbox(vars[page].cd[j].sep, -1, 5, 2, 0, 1,
								function (value)
									vars[page].cd[j].sep = value
									if vars.change[page] ~= 2 then vars.change[page] = 1 end
									form.setButton(page+1, "save",ENABLED)
								end, {width = 50})
				form.addIntbox(vars[page].cd[j].dist, -9, 100, -9, 0, 1,
								function (value)
									vars[page].cd[j].dist = value
									if vars.change[page] ~= 2 then vars.change[page] = 1 end
									form.setButton(page+1, "save",ENABLED)
								end, {width = 60})
			else 
				form.addRow(1)
				form.addLabel({label = j,font = FONT_MINI, width = 210})				
			end
		else
			table.remove(vars[page].notused,i)
		end
	end
	
	form.addSpacer(320,12)
	form.addRow(1)
	form.addLabel({label = vars.trans.explDist, font = FONT_MINI, enabled = false})
	form.addRow(1)
	form.addLabel({label = vars.trans.explSep, font = FONT_MINI, enabled = false})   
	collectgarbage()

	return (vars)
end

local function saveAkkus()
	local j = 1
	for i = 1, #vars.Akkus do
		if vars.Akkus[i].ID ~= -1.0 then
			if i ~= j then
				vars.Akkus[j] = vars.Akkus[i]
				vars.Akkus[i] = nil
			end
			j = j + 1
		else
			vars.Akkus[i] = nil
		end
	end
	
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

local function setupBat(varstemp)
	local i
	local IDmax
	local strValue
	vars = varstemp
	
	form.setTitle(vars.trans.Layout.." Akku")
	form.setTitle("ID       Name         S      mAh     C")
	form.addRow(1)
	form.addLabel({label =vars.trans.headerAkku, font = FONT_MINI, enabled=false})
	
	--form.addLabel({label=vars.trans.capacitymAh, width=210})
	--form.addLabel({label=vars.trans.cellcnt, width=210})
	if vars.addAkku == 1 then
		vars.addAkku = 0
		IDmax = 0
		for i in ipairs(vars.Akkus)  do
			if vars.Akkus[i].ID > IDmax then IDmax = vars.Akkus[i].ID end
		end
		IDmax = IDmax + 1
		i = #vars.Akkus + 1
		vars.Akkus[i] = {} 
		vars.Akkus[i].ID = IDmax
		vars.Akkus[i].batC = 0
		vars.Akkus[i].Name = ""
		vars.Akkus[i].Capacity = 0
		vars.Akkus[i].iCells = 1
		vars.Akkus[i].Cycl = 0
		vars.Akkus[i].Ah = 0
		vars.Akkus[i].lastVoltage = 0
		vars.Akkus[i].usedCapacity = 0
		saveAkkus()
	end
	
	
	-- if #vars.Akkus > 0 then 
		-- form.addSpacer(320,5)
		-- --form.addRow(1)
		-- --form.addLabel({label = "----------------------------------------------------------", enabled = false})
	-- end
	
	for i, j in ipairs(vars.Akkus) do
		form.addSpacer(320,4)	
		form.addRow(5)
		form.addIntbox(j.ID, -1, 999, -1, 0, 1,
								function (value)
									j.ID = value		
									saveAkkus()
								end, {width = 52, font = FONT_BOLD})
		form.addTextbox(j.Name, 9,
								function (value)
									j.Name = value
									saveAkkus()
								end, {width = 105})	
								
		form.addIntbox(j.iCells, 1, 14, 1, 0, 1,
								function (value)
									j.iCells = value
									saveAkkus()
								end, {width = 50} )

		form.addIntbox(j.Capacity, 0, 32767, 0, 0, 10,
								function (value)
									j.Capacity = value
									saveAkkus()
								end, {width = 60} )
		form.addIntbox(j.batC, 0, 90, 0, 0, 5,
								function (value)
									j.batC = value
									saveAkkus()
								end, {width = 50})
								
		form.addRow(3)			
	
		form.addIntbox(j.Cycl, 0, 9999, 0, 0, 1,
								function (value)
									j.Cycl = value
									saveAkkus()
								end, {width = 95, label = vars.trans.cycles, font = FONT_MINI})	
		form.addIntbox(math.floor(j.usedCapacity), 0, 9999, 0, 0, 10,
										function (value)
											j.usedCapacity = value
											saveAkkus()
										end, {label=" mAh", width = 112, font = FONT_MINI})					
		form.addIntbox(math.floor(j.Ah), 0, 9999, 0, 0, 1,
								function (value)
									j.Ah = value
									saveAkkus()
								end, {label=" Ah", width = 115, font = FONT_MINI})
				
	end
	form.addSpacer(320,5)
	form.addRow(1)
	form.addLabel({label =vars.trans.delete_Akku, font = FONT_MINI, alignRight=true, enabled=false})
	
	collectgarbage()
	return (vars)
end


return {

	setup = setup,
	moveLine = moveLine,
	setupBat = setupBat
}
