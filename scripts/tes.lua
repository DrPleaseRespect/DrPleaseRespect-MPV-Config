osd = mp.create_osd_overlay("ass-events")
osd_raw = "{\\an3}{\\fnUbuntu}{\\fs20}{\\c&Hffafe5&}MPV Player{\\c&H0000ff&} - {\\c&Haee5ff&}TESFIA Configuration"
osd.data = osd_raw

osd:update()

fade = false
mp.add_periodic_timer(6, function() fade = true end)

alpha = 0
fade_timer = mp.add_periodic_timer(0.01, function() 
    if fade == true then
        alpha = alpha + 5
        if alpha > 255 then
            alpha = 255
            fade = false
            fade_timer:kill()
        end
        local hex = string.format("%X", tostring(alpha)) 
        local osd_opacity = "{\\alpha&H" .. hex .. "}"
        osd.data = osd_opacity .. osd_raw
        osd:update()
    end
end)

--mp.osd_message(ass_start .. "{\\an3}{\\fnUbuntu}{\\fs10}{\\c&Hffafe5&}MPV Player{\\c&H0000ff&} - {\\c&Haee5ff&}TESFIA Configuration" .. ass_stop,3)
