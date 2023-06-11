-- Copyright (c) 2022, DrPleaseRespect
-- License: MIT License
-- Creator: Julian Nayr
-- Version 1.0

-- WINDOWS ONLY! --


local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local pid = utils.getpid()


local separator = "\\"
local folder_path = os.getenv("TEMP")..separator.."mpv_subsconversion" .. separator .. pid
local executable_prefix = ".exe"

local path = folder_path .. separator


local cookies_from = "firefox"
local yt_dlp_path = mp.command_native({"expand-path", "~~/executables/yt-dlp" .. executable_prefix})
local ytsubconverter_path = mp.command_native({"expand-path", "~~/executables/YTSubConverter" .. executable_prefix})

local last_url = nil

function check_if_url(url)
	return url:find('[a-z]*://[^ >,;]*')
end

function check_if_playlist(url)
	return url:find('/playlist')

end

function get_slang(item_name)
	return item_name:match("%.(.-)%.ass")
end

function delete_folder(folder_path)
	utils.subprocess_detached({args = {"cmd", "/c", "rd", "/Q" , folder_path.."\\"}})
end

function download_srv3_subtitles(path)
	local args = {yt_dl, "--no-config", "--no-playlist", "--write-sub", "--sub-langs", "all,-live_chat",
		"--no-download", "--sub-format=srv3","--retries", "infinite","--cookies-from-browser", cookies_from, "--output", path .. "%(language)s.%(ext)s", url}
	local subproc = mp.command_native(
				{
					name = "subprocess",
					playback_only=false,
					args=args
				})
end

function get_subtitles_names()
	local sub_names = {}
	local args = {yt_dl, "--no-config","--no-playlist","--simulate", "-J", url}
	local subproc = mp.command_native(
				{
					name = "subprocess",
					playback_only=false,
					args=args,
					capture_stdout=true
				})
	--print(subproc.stdout)
	local videometadata = utils.parse_json(subproc.stdout)
	for k,v in pairs(videometadata["subtitles"]) do
		sub_names[k] = utils.to_string(v[1]["name"]):gsub('"', '')
		--print(k .. " " .. sub_names[k])
	end
	return sub_names
end


function convert_srv3_to_ass(path)
	local subs = utils.readdir(path, "files")
	if subs ~= nil then
		for _, item in ipairs(subs) do
			local item_path = utils.join_path(path, item)
			local subproc_args = {ytsubconverter_path, item_path, "--visual"}
			local subproc = mp.command_native(
				{
					name = "subprocess",
					playback_only=false,
					args=subproc_args
				})
			print(utils.format_json(subproc_args))
			print(item_path)
			local returncode = os.remove(item_path)
			if returncode then
				print("DELETED ".. item)
			end
		end
	end
end

function add_subtitles(path, mode_of_operation)
	local subs = utils.readdir(path, "files")
	if subs ~= nil then
		local sub_names = get_subtitles_names()
		for _, item in ipairs(subs) do
			local item_path = utils.join_path(path, item)
			if item:find(".ass") then
				local slang = get_slang(item)
				local sub_name = sub_names[slang]
				print("ADDING! ".. item .. " " .. slang .. ":" .. sub_name)
				mp.commandv("sub-add" , item_path, mode_of_operation, sub_name, slang)
			end
		end
	end
end

function subtitle_loader()
	yt_dl = yt_dlp_path
	url = mp.get_property("stream-open-filename", nil)
	title = mp.get_property("media-title", nil)
	filepath = mp.get_property("path", nil)

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

	if last_url == url then
		add_subtitles(path, "auto")
		print("URL Matches Last URL. Exiting!")
		return
	else
		clean_unregistered()
	end

	last_url = url

	download_srv3_subtitles(path)

	convert_srv3_to_ass(path)

	add_subtitles(path, "auto")

end

function clean_unregistered()
	local subs = utils.readdir(path, "files")
	if subs then
		print("CLEANING!")
		for _, item in ipairs(subs) do
			print("REMOVING: " .. item)
			item_path = utils.join_path(path, item)
			os.remove(item_path)
		end
		delete_folder(folder_path)
	end
end

function clean(event)
	clean_unregistered()
end


function remove_webvtt_tracks()
	local tracks = mp.get_property_native("track-list")
	for index, item in ipairs(tracks) do
		if (item["codec"] == "webvtt" and item["type"] == "sub") then
			print("REMOVED: ".. "ID: " .. item['id'] .. " LANG:" .. item["lang"])
			mp.commandv("sub-remove", item['id'])
		end
	end
end

mp.add_hook("on_load", 50, subtitle_loader)
mp.add_hook("on_preloaded", 50, remove_webvtt_tracks)
mp.register_event("shutdown", clean)