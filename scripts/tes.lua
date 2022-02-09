osd = mp.create_osd_overlay("ass-events")
osd_raw = "{\\an3}{\\fnUbuntu}{\\fs20}{\\c&Hffafe5&}MPV Player{\\c&H0000ff&} - {\\c&Haee5ff&}TESFIA Configuration"
osd.data = osd_raw

osd:update()

mp.add_timeout(5, function () Fader:run(osd_raw, 0, 255, 1) end)
osd_raw_2 = "{\\an3}{\\fnUbuntu}{\\fs20}{\\c&Hffafe5&}TESFIA Configuration{\\c&H0000ff&} - {\\c&Haee5ff&}Created By DrPleaseRespect"
mp.add_timeout(6, function () Fader:run(osd_raw_2, 255, 0, 1) end)
mp.add_timeout(9, function () Fader:run(osd_raw_2, 0, 255, 1) end)

Fader = {
    linear_interpolation = function (v0, v1, t)
        return (1 - t) * v0 + t * v1
    end,
    run = function (self, raw_string, start_num, end_num, duration)
        self.alpha = 0
        self.progress = 0
        self.fade = true
        self.raw_string = raw_string
        self.start_num = start_num
        self.end_num = end_num
        self.duration = duration
        self.start_time = os.clock()
        self.fader = mp.add_periodic_timer(0.01, function()
            if self.fade == true then
                if self.progress >= 1 then
                    self.progress = 1
                    self.fade = false
                    self.fader:kill()
                else
                    self.progress = (os.clock() - self.start_time) / self.duration
                end
                self.alpha = self.linear_interpolation(self.start_num, self.end_num, self.progress)
                
                if self.progress >= 1 then
                    self.alpha = self.end_num
                end
                local hex = string.format("%X", tostring(self.alpha)) 
                local osd_opacity = "{\\alpha&H" .. hex .. "}"
                osd.data = osd_opacity .. self.raw_string
                osd:update()
            end
        end)
    end
}

