loadNotes = function(dir, paper, app)
	local textFile, err = love.filesystem.newFile(dir.."/text.txt",'r')
	if err then
        gooi.get("alert_label").text = err
        popups:setState("alert")
	else
        local textData, imgFile
        local tn = tonumber
		textData = textFile:read()
        textFile:close()
		imgFile = love.graphics.newImage(dir.."/paper.png")
        app.textBoxes    = {}
        app.textBoxes.id = 1
		for tb in textData:gmatch("@textBox%b{}") do
            local _, _, x, y     = tb:find("@pos{(.*),(.-)}")
            local _, _, wrap     = tb:find("@wrap{(.-)}")
            local _, _, fontSize = tb:find("@fontSize{(.-)}")
            local _, _, text     = tb:find("@text{(.-)}")
            --print(x, y, wrap, fontSize, text)
            app.textBoxes[#app.textBoxes + 1] = textBox:new(app.textBoxes.id, text, tn(x), tn(y), tn(wrap), "left", love.graphics.newFont(tn(fontSize)), fontSize)
            app.textBoxes.id = app.textBoxes.id + 1
		end
		love.graphics.setCanvas(paper)
            love.graphics.clear()
			love.graphics.draw(imgFile,0,0)
		love.graphics.setCanvas()
	end
end