-- Copyright (c) 2022-2024, DrPleaseRespect
-- License: MIT License
-- Creator: Julian Nayr
-- Version 2.0.3

-- UNTESTED ON LINUX --


local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'


-- OS Detection
local vo_profile = {}
if mp.get_property_native('options/vo-mmcss-profile', vo_profile) ~= vo_profile then
  executable_suffix = ".exe"
else
  executable_suffix = ""
end


local cookies_from = "firefox"
local yt_dlp_path = mp.command_native({"expand-path", "~~/executables/yt-dlp" .. executable_suffix})
local ytsubconverter_path = mp.command_native({"expand-path", "~~/executables/YTSubConverter.MPVHelper" .. executable_suffix})

url = nil

function check_if_url(url)
	return url:find('[a-z]*://[^ >,;]*')
end

function check_if_playlist(url)
	return url:find('/playlist')
end

function convert_subs(url)
	local args = {ytsubconverter_path, url}
	---@type Subprocess | nil
	---@diagnostic disable-next-line: assign-type-mismatch
	local subproc = mp.command_native(
				{
					name = "subprocess",
					playback_only=false,
					args=args,
					capture_stdout=true
				})
	if subproc == nil then
		print("Error converting subtitles!")
		return "memory://WEBVTT"
	else
		return "memory://" .. subproc.stdout
	end
end

function obtain_url()
	url = mp.get_property("stream-open-filename")
end

function download_srv3_subtitles()
	local args = {yt_dlp_path, url , "--no-config", "--no-playlist", "--write-sub", "--sub-langs", "all,-live_chat", "-J",
		"--no-download", "--sub-format=srv3","--retries", "infinite","--cookies-from-browser", cookies_from,}
	---@type Subprocess | nil
	---@diagnostic disable-next-line: assign-type-mismatch
	local subproc = mp.command_native(
				{
					name = "subprocess",
					playback_only=false,
					args=args,
					capture_stdout=true,
					capture_stderr=true
				})
	--print(subproc.stdout)
	if subproc == nil then
		print("Error obtaining subtitles!")
		return
	end
	local json = utils.parse_json(subproc.stdout)
	if json.requested_subtitles ~= nil then
        local subs = {}
        for lang, info in pairs(json.requested_subtitles) do
            subs[#subs + 1] = {lang = lang or "-", info = info}
        end
        table.sort(subs, function(a, b) return a.lang < b.lang end)
		for _, subItem in ipairs(subs) do
			local sub_lang = subItem.lang
			local sub_info = subItem.info
			subfile_url = json.requested_subtitles[sub_lang].url
			local converted_sub = convert_subs(subfile_url)
			print("adding ".. sub_lang .. " subtitles")
			mp.commandv('sub-add', converted_sub, "auto", sub_info.name, sub_lang)
		end
	end
end

function remove_webvtt_tracks()
	if check_if_url(url) then
		if ( not(url:find("www.youtube.com") or url:find("youtu.be"))) then
			print("Not Youtube!")
			return
		end
	else
		print("NOT A URL! EXITING!")
		return
	end

	if check_if_playlist(url) then
		print("PLAYLIST LINK! EXITING")
		return
	end
	local tracks = mp.get_property_native("track-list")
	for index, item in ipairs(tracks) do
		if (item["codec"] == "webvtt" and item["type"] == "sub") then
			print("REMOVED: ".. "ID: " .. item['id'] .. " LANG:" .. item["lang"])
			mp.commandv("sub-remove", item['id'])
		end
	end
	download_srv3_subtitles()
end

mp.add_hook("on_load", 50, obtain_url) -- obtain URL before ytdl_hook takes over
mp.add_hook("on_preloaded", 50, remove_webvtt_tracks) -- start payload