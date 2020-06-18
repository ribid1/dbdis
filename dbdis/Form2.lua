local vars

local function saveOrder()
		local filename 
		if vars.template then filename = "Apps/"..vars.appName.."/template_O.txt"
			else filename = "Apps/"..vars.appName.."/"..vars.model.."_O.txt"
		end
		local file = io.open(filename, "w+")
		local i, line
		if file then
			for i, line in ipairs(vars.leftcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars.param[line].sep,"   ", vars.param[line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars.rightcolumn) do 
				io.write(file, line, "\n") 
				io.write(file, vars.param[line].sep,"   ", vars.param[line].dist, "\n")  
			end
			io.write(file, "---\n")
			for i, line in ipairs(vars.notused) do 
				io.write(file, line, "\n") 
				io.write(file, vars.param[line].sep,"   ", vars.param[line].dist, "\n")  
			end
			io.close(file)
		end
		collectgarbage()
end


local function setup(varstemp)
	local i, j
	local value
	local template
	
	vars = varstemp
  	form.setTitle(vars.trans.Layout)
	
	form.addSpacer(320,5)
	
	form.addRow(2)
	form.addLabel({label = "Template:", width = 270})
	template = form.addCheckbox(vars.template, 
				function(value)
					vars.template = not value
					system.pSave("template", not value and 1 or 0)
					form.setValue(template, not value)	
				end)

	form.addSpacer(320,10)
	form.addRow(2)
	form.addLabel({label = vars.trans.Leftrow, font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

			
	for i,j in ipairs(vars.leftcolumn) do	
		if vars.param[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars.param[j].y..")",font = FONT_NORMAL, width = 210})
			form.addIntbox(vars.param[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars.param[j].sep = value
								saveOrder()
							end, {font = fontLabel, width = 50})
			form.addIntbox(vars.param[j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars.param[j].dist = value
								saveOrder()
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
	form.addLabel({label = vars.trans.Rightrow, font = FONT_BOLD, alignRight = false, enabled = true})
	form.addLabel({label = "Sep.:   Dist.:", font = FONT_BOLD, alignRight = true, enabled = true})

	for i,j in ipairs(vars.rightcolumn) do
		if vars.param[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars.param[j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars.param[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars.param[j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars.param[j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars.param[j].dist = value
								saveOrder()
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
	
	for i,j in ipairs(vars.notused) do
		if vars.param[j].visible then
			form.addRow(3)
			form.addLabel({label = j.." ("..vars.param[j].y..")",font = FONT_NORMAL, width = 210})
			
			form.addIntbox(vars.param[j].sep, -1, 5, 2, 0, 1,
							function (value)
								vars.param[j].sep = value
								saveOrder()
							end, {width = 50})
			form.addIntbox(vars.param[j].dist, -9, 100, -9, 0, 1,
							function (value)
								vars.param[j].dist = value
								saveOrder()
							end, {width = 60})
		else 
			form.addRow(1)
			form.addLabel({label = j,font = FONT_MINI, width = 210})				
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

return {

	setup = setup
  
}
