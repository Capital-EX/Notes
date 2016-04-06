saveTextBoxes = function(textBoxList)
    local saved = {}
    for k, tb in ipairs(textBoxList) do
        local savePos, saveText, saveWrap, saveFontSize
        savePos  = "@pos{"..tb.x..","..tb.y.."}"
        saveText = "@text{"..tb.plainText.."}"
        saveWrap = "@wrap{"..tb.wrap.."}"
        saveFontSize = "@fontSize{"..tb.fontSize.."}"
        saved[#saved + 1]    = "@textBox{"..savePos..saveWrap..saveFontSize..saveText.."}"
    end
    return table.concat(saved, "\n")
end
save = function(dir, textBoxList, canvas)
    saveDir = love.filesystem.getSaveDirectory()
    dir = dir:gsub("[|\\*?:<>\"/]","-")
	if dir == ""  then
		local i = 0
		while love.filesystem.exists(app.activeFile..i) do
			i = i + 1
		end
		dir = app.activeFile..i
		app.activeFile = dir
	end
    
    if not love.filesystem.exists(dir) then
        suc = love.filesystem.createDirectory(dir)
        if not suc then
            error("failed to create save directory")
        end
    end
    canvas:newImageData():encode("png",dir.."/".."paper.png")
    textBoxFile, err = love.filesystem.newFile(dir.."/".."text.txt","w")
    if err then
        error(err.."; "..saveDir)
    end
    txt = saveTextBoxes(textBoxList)
    textBoxFile:write(txt)
    textBoxFile:flush()
    textBoxFile:close()
    --]]
end