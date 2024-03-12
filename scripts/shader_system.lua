-- Copyright (c) 2023, DrPleaseRespect
-- License: GPL3 License
-- Creator: Julian Nayr
-- Version 1.0

-- This script requires uosc https://github.com/tomasklaen/uosc

mp = require 'mp'
utils = require 'mp.utils'
local opt = require('mp.options')

local script_name = mp.get_script_name()

local opts = {
    -- do not use duplicates on different profiles
    -- the same shader can be used multiple times in one profile,
    -- but once a shader has been used in a profile,
    -- do not use it in another profile

    -- if a shader is found in another profile both profiles will be
    -- automatically added to their incompatability lists

    shaderlist = [[
        [
            {"SSimSuperRes": [
                "~~/shaders/SSimSuperRes.glsl"
            ]},
            {"KrigBilateral": [
                "~~/shaders/KrigBilateral.glsl"
            ]},
            {"Anime4K: Mode A (HQ)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Restore_CNN_VL.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"Anime4K: Mode B (HQ)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"Anime4K: Mode C (HQ)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"Anime4K: Mode A (Fast)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Restore_CNN_M.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"Anime4K: Mode B (Fast)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"Anime4K: Mode C (Fast)" : [
                "~~/shaders/Anime4K_Clamp_Highlights.glsl",
                "~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_M.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl",
                "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl",
                "~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl",
                {
                    "dependencies" : ["SSimSuperRes", "KrigBilateral"],
                    "incompatability": [],
                    "folder": "Anime4K"
                }
            ]},
            {"NNEDI3 Scaler" : [
                "~~/shaders/nnedi3-nns32-win8x6.hook"
            ]},
            {"RAVU-Zoom-R4 Pre-Scaler" : [
                "~~/shaders/ravu-zoom-r4.hook"
            ]},
            {"FSRCNNX Pre-Scaler" : [
                "~~/shaders/FSRCNNX_x2_8-0-4-1.glsl"
            ]}
        ]
    ]]
}
opt.read_options(opts, 'shader_system')


-- initialize shader_states and shader_names
local profile_states = {}
local profile_names = {}

-- cache of active glsl-shaders
local cached_shaderlist = {}
local cached_normalized_shaderlist = {}


function mpv_normalize_path(path)
    return mp.command_native({"expand-path", path})
end

function string_in_array(object, in_array)
	for i=1, #in_array, 1 do
		if in_array[i] == object then
			return true
		end
	end
	return false
end

function array_in_array(array, in_array)
    for index, value in ipairs(array) do
        if string_in_array(value, in_array) == false then
            return false
        end
    end
    return true
end

function string_in_arraypos(string,array)
	for i=1, #array, 1 do
		if array[i] == string then
			return i
		end
	end
	return nil
end

do
    -- generate name entries and parse dependencies and incompatability lists
    local shaderjson = utils.parse_json(opts.shaderlist)
    local tempshaderlist = {}
    local tempdependencylist = {}
    local tempincompatabilitylist = {}
    local tempfolderlist = {}
    for index, value in ipairs(shaderjson) do
        local name, shaderlist = next(value)
        local options_exist = type(shaderlist[#shaderlist]) == "table" and true or false
        tempshaderlist[name] = shaderlist
        if options_exist then
            -- dependencies
            if shaderlist[#shaderlist]["dependencies"] ~= nil then
                tempdependencylist[name] = shaderlist[#shaderlist]["dependencies"]
            else
                tempdependencylist[name] = {}
            end
            -- incompatability
            if shaderlist[#shaderlist]["incompatability"] ~= nil then
                tempincompatabilitylist[name] = shaderlist[#shaderlist]["incompatability"]
            else
                tempincompatabilitylist[name] = {}
            end
            if shaderlist[#shaderlist]["folder"] ~= nil then
                tempfolderlist[name] = shaderlist[#shaderlist]["folder"]
            end
            table.remove(shaderlist, #shaderlist)
        else
            tempdependencylist[name] = {}
            tempincompatabilitylist[name] = {}
            tempfolderlist[name] = nil
        end
        profile_names[#profile_names+1] = name
    end

    -- normalize paths and generate shader_states entries
    for name, _ in pairs(tempshaderlist) do

        local normalized_shaderlist = {}
        for _, pathvalue in ipairs(tempshaderlist[name]) do
            normalized_shaderlist[#normalized_shaderlist+1] = mpv_normalize_path(pathvalue)
        end
        profile_states[name] = {
            active = false,
            folder = tempfolderlist[name],
            shaderlist = normalized_shaderlist,
            dependencies = tempdependencylist[name],
            incompatability = tempincompatabilitylist[name]
        }
    end
    -- generate automated incompatability table
    for index, profilename in ipairs(profile_names) do
        local incompatability_table = profile_states[profilename]["incompatability"]
        local shaderlist = profile_states[profilename]["shaderlist"]
        -- checking of duplicate shaders
        for name, profiletable in pairs(profile_states) do
            if not string_in_array(name, incompatability_table) and profilename ~= name then
                for _, value in ipairs(profiletable["shaderlist"]) do
                    if string_in_array(value, shaderlist) then
                        table.insert(incompatability_table, name)
                        break
                    end
                end
            end
        end
        profile_states[profilename]["incompatability"] = incompatability_table
    end
end

function get_normalized_shaderlist()
    local active_shaderlist = mp.get_property_native("glsl-shaders")

    if table.concat(active_shaderlist) == table.concat(cached_shaderlist) then
        return cached_normalized_shaderlist
    end

    local normalized_activeshaderlist = {}

    for index, value in ipairs(active_shaderlist) do
        normalized_activeshaderlist[#normalized_activeshaderlist+1] = mpv_normalize_path(value)
    end

    cached_shaderlist = active_shaderlist
    cached_normalized_shaderlist = normalized_activeshaderlist

    return normalized_activeshaderlist

end


function set_shader(shadername, boolean, added_dependecy_shaders)
    if boolean then
        added_dependecy_shaders = added_dependecy_shaders or {}
        for _, dep_shadername in ipairs(profile_states[shadername]["dependencies"]) do
            -- hopefully this prevents circular dependencies turning into an infinite loop
            if not profile_states[dep_shadername]["active"] then
                if not string_in_array(dep_shadername, added_dependecy_shaders) then
                    table.insert(added_dependecy_shaders, dep_shadername)
                    set_shader(dep_shadername, true, added_dependecy_shaders)
                end
            end
        end
        for _, incomp_shadername in ipairs(profile_states[shadername]["incompatability"]) do
            set_shader(incomp_shadername, false)
        end
    end
    local active_shaderlist = get_normalized_shaderlist()
    local shaders = profile_states[shadername]["shaderlist"]
    local shadername_active = array_in_array(shaders, active_shaderlist)

    for index, value in ipairs(shaders) do
        if shadername_active then
            while string_in_array(value, active_shaderlist) do
                shader_pos_in_array = string_in_arraypos(value, active_shaderlist)
                table.remove(active_shaderlist, shader_pos_in_array)
            end
        end
        if boolean then
            active_shaderlist[#active_shaderlist+1] = value
        end
    end
    for index, pairs_shadername in ipairs(profile_names) do
        profile_states[pairs_shadername]["active"] = array_in_array(profile_states[pairs_shadername]["shaderlist"], active_shaderlist)
    end
    mp.set_property_native("glsl-shaders", active_shaderlist)
end


function shaderprofile_is_active(shadername)
    local active_shaderlist = get_normalized_shaderlist()
    return array_in_array(profile_states[shadername]["shaderlist"], active_shaderlist)

end

function update_shader_states()
    for index, shadername in ipairs(profile_names) do
        profile_states[shadername]["active"] = shaderprofile_is_active(shadername)
    end

end

function command(str)
    return string.format('script-message-to %s %s', script_name, str)
  end


function create_profile_menu()
    local menu = {
        type = 'shader_menu',
        title = 'Shader Select',
        keep_open = true,
        items = {}
    }

    for index, name in ipairs(profile_names) do
        local item = {
            title = name,
            icon = profile_states[name]["active"] == true and 'check_box' or 'check_box_outline_blank',
            value = command("toggle_shader_ui " .. '"' .. name .. '"')
        }
        if profile_states[name]["folder"] == nil then
            menu.items[#menu.items+1] = item
        else -- folder handler
            local found_folder = false
            local foldername = profile_states[name]["folder"]
            for _, iter_foldername in ipairs(menu.items) do
                if iter_foldername.title == foldername then
                    iter_foldername.items[#iter_foldername.items+1] = item
                    found_folder = true
                end
            end
            if not found_folder then
                menu.items[#menu.items+1] = {title = foldername, items = {item}, keep_open = true}
            end
        end
    end
    return menu
end

function create_profile_menu_waiting(shader_key)
    local menu = create_profile_menu()
    for i, v in ipairs(menu.items) do
        if v.title == shader_key then
           v["icon"] = "spinner"
        elseif v.items ~= nil then
            for index, value in ipairs(v.items) do
                if value.title == shader_key then
                    value["icon"] = "spinner"
                end
            end
        end
    end
    return menu

end

mp.observe_property("glsl-shaders", nil, function ()
    update_shader_states()
end)

mp.register_script_message('toggle_shader_ui', function(shader_key)
    -- Update currently opened menu
    local json = utils.format_json(create_profile_menu_waiting(shader_key))
    mp.commandv('script-message-to', 'uosc', 'update-menu', json)
    set_shader(shader_key, (not profile_states[shader_key]["active"]))
    local json_updated = utils.format_json(create_profile_menu())
    mp.commandv('script-message-to', 'uosc', 'update-menu', json_updated)
  end)

mp.add_key_binding(nil, 'toggle_shader', function(shader_key)
    set_shader(shader_key, (not profile_states[shader_key]["active"]))
   end)

mp.register_script_message('set_shader', function(shader_key, boolean)
    set_shader(shader_key, boolean)
    end)


mp.add_forced_key_binding(nil, 'open-menu', function()
    local json = utils.format_json(create_profile_menu())
    mp.commandv('script-message-to', 'uosc', 'open-menu', json)
   end)