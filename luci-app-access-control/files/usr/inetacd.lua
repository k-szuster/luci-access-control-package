#!/usr/bin/lua

require "uci"


function check ()
    local x = uci.cursor()
    local tnow = os.time()
    local nexttime 
    local changed = false
    
    x:foreach ("firewall", "rule", 
        function(s) 
            if s.ac_enabled=='1' and s.ac_suspend then
                local tend = math.ceil (tonumber (s.ac_suspend) / 60) * 60 
                local jeszcze = tend - tnow
                if jeszcze <= 0 then
print (s.name..": koniec")
                    x:set ("firewall", s[".name"], "enabled", '1')
                    x:delete ("firewall", s[".name"], "ac_suspend")
                    changed = true
                else
print (s.name..": zostało "..jeszcze)
                    if not nexttime or nexttime > jeszcze then
                        nexttime = jeszcze
                    end
                end
            end
        end)
    if changed then
        x:commit("firewall")
        os.execute ("/etc/init.d/firewall restart")
    end
    return nexttime    
end

while true do
    local next = check()
--    next = 60
    if not next then
        break
    end
print ("sleep for "..next)
    os.execute ("exec sleep "..next)
end    

