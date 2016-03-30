loadNotes = function(dir,paper)
   local textBoxValues = {
        "pos",
        "wrap",
        "fontSize",
        "text",
    }
	textFile, err = love.filesystem.newFile(dir.."text.txt",'r')
	if err then
		app.failedToLoad = true	
	else
		textData = textFile:read()
		imgFile = love.graphics.newImage(dir.."paper.png")
		for textBox in textData:gmatch("@textbox{(.*)}") do
			print(textBox)
		end
		love.graphics.setCanvas(paper)
			love.graphics.draw(imgFile,0,0)
		love.graphics.setCanvas()
	end
end