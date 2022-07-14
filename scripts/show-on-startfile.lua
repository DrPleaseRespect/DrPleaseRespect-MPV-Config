

function set_ontop()
	ontop_boolean = mp.get_property_bool("ontop")
	if ontop_boolean ~= true then
		mp.set_property_bool("ontop", true)
	end
end

function stop_ontop()
	if ontop_boolean ~= true then
		mp.set_property_bool("ontop", false)
	end
end




mp.register_event("start-file", set_ontop)
mp.register_event("file-loaded", stop_ontop)