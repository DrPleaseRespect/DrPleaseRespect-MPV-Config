-- Copyright (c) 2022, DrPleaseRespect
-- License: MIT License
-- Creator: Julian Nayr
-- Version 1.0

mp = require 'mp'
utils = require 'mp.utils'

nvdec_not_found = false

function low_power()
	hw_api = mp.get_property_native("hwdec-current")
	if hw_api ~= "nvdec" then
		nvdec_not_found = true
		mp.command(
			'apply-profile powersavingmode; show-text "NVIDIA Decoder Not Found!\nLow Power Profile Applied" 3000'
		)
	elseif hw_api == "dxva2-copy" then
		if nvdec_not_found == true then
			nvdec_not_found = false
			mp.command(
				'apply-profile powersavingmode restore; apply-profile Default_Shaders; apply-profile Default_Settings; show-text "NVIDIA Decoder Found!\nResetting to Default Values!!" 3000'
			)
		end
	end
end

mp.register_event("file-loaded", low_power)