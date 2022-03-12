-- THIS LUA SCRIPT IS CREATED BY DRPLEASERESPECT --
-- FOR DISPLAYING IF FILE/STREAM IS LOADING/BUFFERING --
-- Pretty Jank Code. I suck at doing OOP in Lua --

mp = require 'mp'
utils = require 'mp.utils'

osd = mp.create_osd_overlay("ass-events")

loading_bool = false
seek_state_timer = nil




function loading()
	local ass_raw = "{\\an5}{\\fnBebasNeue}{\\fs80}{\\c&Hffafe5&}LOADING"
	osd.data = ass_raw
	loading_bool = true
	osd:update()
end

function buffering()
	loading_bool = true
	local ass_raw = "{\\an5}{\\fnBebasNeue}{\\fs80}{\\c&Hffafe5&}BUFFERING"
	osd.data = ass_raw
	osd:update()
end



function buffering_state_detection(property, output)
	if output ~= nil then
		if output == 'yes' then
			buffering()
		else
			remove_loading()
		end
	end
end

function seek_state_detection()
	seek_state_timer = mp.add_timeout(0.5, function()
		local demuxer_state = mp.get_property_native("demuxer-cache-state")
		if demuxer_state['underrun'] == true then
			buffering()
		else
			remove_loading()
		end
	end)
end

function remove_loading(event)
	loading_bool = false
	osd:remove()
end

mp.register_event("start-file", loading)
mp.register_event("playback-restart", remove_loading)
mp.observe_property("paused-for-cache", "string", buffering_state_detection)
mp.register_event("seek", seek_state_detection)
