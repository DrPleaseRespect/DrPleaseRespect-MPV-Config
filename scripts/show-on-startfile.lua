ontop_finished = false
ontop_boolean = mp.get_property_bool("ontop")


function set_ontop()
	ontop_finished = false
	ontop_boolean = mp.get_property_bool("ontop")
	if ontop_boolean ~= true then
		mp.set_property_bool("ontop", true)
	end
end

function stop_ontop()
	if ontop_finished ~= true then
		if ontop_boolean ~= true then
			mp.set_property_bool("ontop", false)
		end
	end
	ontop_finished = true
end




mp.register_event("file-loaded", set_ontop)
mp.register_event("playback-restart", stop_ontop)