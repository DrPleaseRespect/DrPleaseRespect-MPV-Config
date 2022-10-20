-- Copyright (c) 2022, DrPleaseRespect
-- License: MIT License
-- Creator: Julian Nayr
-- Version 1.0

-- FOR DISPLAYING IF FILE/STREAM IS LOADING/BUFFERING --
-- Pretty Jank Code. Coding in Lua --

mp = require 'mp'
utils = require 'mp.utils'

osd = mp.create_osd_overlay("ass-events")

loading_bool = false
seek_state_timer = nil

debug_flag = false



function loading()
	local ass_raw = "{\\an5}{\\fnBebasNeue}{\\fs80}{\\c&Hffafe5&}LOADING"
	osd.data = ass_raw
	loading_bool = true
	osd:update()
	if debug_flag == true then
		print("Loading OSD Loaded")
	end
end

function remove_loading(event)
	if loading_bool == true then
		loading_bool = false
		osd:remove()
		if debug_flag == true then
			print("OSD Removed")
		end
	end
end

mp.register_event("start-file",loading)
mp.register_event("playback-restart", remove_loading)
