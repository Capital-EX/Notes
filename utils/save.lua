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
    return saved
end
save = function(dir, textBoxList, canvas)
    saveDir = love.filesystem.getSaveDirectory()
    dir = dir:gsub("[|\\*?:<>\"/]","")
	if dir == "" then
		local i = 0
		while love.filesystem.exists("unnamed"..i) do
			i = i + 1
		end
		dir = "unnamed"..i
		app.activeFile = dir
	end
    if not love.filesystem.exists(dir) then
        --print"Making dir!"
        love.filesystem.createDirectory(dir)
    end
    
    textBoxFile, err = love.filesystem.newFile(dir.."/".."text.txt","w")
    txt = saveTextBoxes(textBoxList)
	
    if #txt == 0 then
       textBoxFile:write("") 
    end
    for k, textbox in ipairs(txt) do
        textBoxFile:write(textbox..'\n')
        textBoxFile:flush()
    end
	
    textBoxFile:close()
    paperData = canvas:newImageData():encode("png",dir.."/".."paper.png")
    --print(saveDir, dir)
end