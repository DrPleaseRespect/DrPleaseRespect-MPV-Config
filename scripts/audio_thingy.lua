-- Copyright (c) 2022, DrPleaseRespect
-- License: MIT License
-- Creator: Julian Nayr
-- Version 1.0

-- THIS LUA SCRIPT IS CREATED BY DRPLEASERESPECT --
-- FOR DISPLAYING AUDIO METADATA --

mp = require 'mp'
utils = require 'mp.utils'

osd = mp.create_osd_overlay("ass-events")

function get_tracks()
	-- Taken from visualizer.lua
    local count = mp.get_property_number("track-list/count", -1)
    local atrack = 0
    local vtrack = 0
    local albumart = 0
    local output = {
    	audio_tracks = atrack,
     	video_tracks = vtrack,
      	album_art = albumart
  	}
    if count <= 0 then
        return output
    end
    for tr = 0,count-1 do
        if mp.get_property("track-list/" .. tr .. "/type") == "audio" then
            atrack = atrack + 1
        else
            if mp.get_property("track-list/" .. tr .. "/type") == "video" then
                if mp.get_property("track-list/" .. tr .. "/albumart") == "yes" then
                    albumart = albumart + 1
                else
                    vtrack = vtrack + 1
                end
            end
        end
    end
    output['audio_tracks'] = atrack
    output['video_tracks'] = vtrack
    output['album_art'] = albumart
    return output
end

function string_in_table(string,filter)
	for i=1, #filter, 1 do
		if filter[i] == string then
			return true
		end
	end
	return false
end

profile_applied = false

function audio_only (name, value)
	local exception_list = {"Title", "Comment"}
	local tracks = get_tracks()
	if tracks["video_tracks"] <= 0 then
		profile_applied = true
		print("Applying audio-only profile")
		mp.commandv("apply-profile", "audio-only")
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
				-- replace underscores with blank spaces
				metadata_name = metadata_name:gsub("_", " ")
				if not string_in_table(metadata_name, exception_list) then
					osd_raw = osd_raw .. "\n" .. string.format("{\\an9}{\\fnUbuntu}{\\fs25}{\\c&Haee5ff&}%s: %s", metadata_name, value)
				end
			end
		end
		osd.data = osd_raw
		osd:update()
	else
		if profile_applied == true then
			mp.commandv("apply-profile", "audio-only", "restore")
			profile_applied = false
		end
		osd:remove()
	end
end

mp.register_event("file-loaded", audio_only)