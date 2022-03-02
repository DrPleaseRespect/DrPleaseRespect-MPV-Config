-- THIS LUA SCRIPT IS CREATED BY DRPLEASERESPECT --
-- FOR DISPLAYING AUDIO METADATA --

mp = require 'mp'
utils = require 'mp.utils'

osd = mp.create_osd_overlay("ass-events")

function string_in_table(string,filter)
	for i=1, #filter, 1 do
		if filter[i] == string then
			return true
		end
	end
	return false
end

function audio_only (name, value) 
	local exception_list = {"Title", "Comment"}
	local video_codec = mp.get_property("video-codec")
	local file_path = mp.get_property('path')
	if video_codec == nil and file_path ~= nil then 
		local metadata = mp.get_property('filtered-metadata')
		local title = mp.get_property_osd("media-title")
		local line_string = ''
		for init=0,#title, 1 do
			line_string = line_string .. '-'
		end
		local osd_raw = "{\\an9}{\\fnBebasNeue}{\\fs50}{\\c&Hffafe5&}AUDIO MODE\n{\\an9}{\\fnUbuntu}{\\fs30}{\\c&Hffafe5&}" .. line_string
		osd_raw = osd_raw .. "\n" .. "{\\an9}{\\fnUbuntu}{\\fs30}{\\c&Haee5ff&}Title: " .. title .. ""
		if metadata ~= "{}" then
			metadata_table = utils.parse_json(metadata)
			for metadata_name, value in pairs(metadata_table) do
				if not string_in_table(metadata_name, exception_list) then
					osd_raw = osd_raw .. "\n" .. string.format("{\\an9}{\\fnUbuntu}{\\fs25}{\\c&Haee5ff&}%s: %s", metadata_name, value) 
				end
			end
		end
		osd.data = osd_raw
		osd:update()
	else
		osd:remove()
	end
end

mp.register_event("file-loaded", audio_only)