--[[
LuCI - Lua Configuration Interface - Internet access control

Copyright 2015,2016 Krzysztof Szuster.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local CONFIG_FILE_RULES = "firewall"  
local CONFIG_FILE_AC    = "access_control"
local ma, mr, s, o

local function time_elapsed (tend) 
    local now = math.floor (os.time() / 60)  --  [min]
    return now > math.floor (tonumber (tend) / 60) 
end


ma = Map(CONFIG_FILE_AC, translate("Internet Access Control"),
    translate("Access Control allows you to manage internet access for specific local hosts.<br/>\
       Each rule defines which user has blocked access to the internet. The rules may be active permanently or in certain time of day.<br/>\
       The rules may also be restricted to specific days of the week.<br/>\
       Any host which is subject to the restrictions may obtain a ticket suspending the restriction for a specified time."))
if CONFIG_FILE_AC==CONFIG_FILE_RULES then
    mr = ma
else
    mr = Map(CONFIG_FILE_RULES)
end


--[[
function mr.on_after_commit (m)  -- on_before_apply
    local tickets
    m.uci:foreach (CONFIG_FILE_RULES, "rule",
        function (s)
            if s.ac_suspend then
                tickets = true
                return false
            end
        end)
    if tickets then  
        luci.sys.call("exec /etc/init.d/inetac restart > /dev/null 2> /dev/null")
    else
        luci.sys.call("exec /etc/init.d/inetac stop > /dev/null 2> /dev/null")
    end        
end
]]--

--=============================================================================================
--  General section

s = ma:section(NamedSection, "general", "access_control", translate("General settings"))
    local o_global_enable = s:option(Flag, "enabled", translate("Enabled"),
        translate ("Must be set to enable the internet access blocking"))
        o_global_enable.rmempty = false
    local o_ticket = s:option(Value, "ticket", translate("Ticket time [min]"), 
	      translate("Time granted when a ticket is issued"))
        o_ticket.datatype = "uinteger"
        o_ticket.default = 60
        
--=============================================================================================
-- Rule table section

s = mr:section(TypedSection, "rule", translate("Client Rules"))
    s.addremove = true
    s.anonymous = true
--    s.sortable  = true
    s.template = "cbi/tblsection"
    -- hidden option
    s.defaults.ac_suspend = nil
    -- hidden, constant options
    s.defaults.enabled = "0"
    s.defaults.src     = "*" --"lan", "guest" or enything on local side
    s.defaults.dest    = "wan"
    s.defaults.target  = "REJECT"
    s.defaults.proto    = "0"
    s.defaults.extra = "--kerneltz"
    
    -- only AC-related rules
    s.filter = function(self, section)
	      return self.map:get (section, "ac_enabled") ~= nil
    end

-----------------------------------------------------------        
    o = s:option(Flag, "ac_enabled", translate("Enabled"))
        o.default = '1'
        o.rmempty  = false

        -- ammend "enabled" option and set weekdays  
        function o.write(self, section, value)
            wd_write (self, section, value)
            
            local key = o_global_enable:cbid (o_global_enable.section.section)
            --  "cbid.access_control.general.enabled"
            local enable = (o_global_enable.map:formvalue (key)=='1') and (value=='1')
            if not enable then  --  disabled rule => clear ticket, if any
                self.map:del(section, "ac_suspend")
            else  -- check ticket  
                local ac_susp = self.map:get(section, "ac_suspend")
                if ac_susp then  
                    if time_elapsed (ac_susp) then
                        self.map:del (section, "ac_suspend")
                        ac_susp = nil
                    end
                end
                if ac_susp then  --  ticked issued => temporarily disable rule
                    enable = false
                end
            end
            	
            self.map:set(section, "enabled", enable and '1' or '0')
--            self.map:set(section, "src",  "*")
--            self.map:set(section, "dest", "wan")
--            self.map:set(section, "target", "REJECT")
--            self.map:set(section, "proto", "0")
--            self.map:set(section, "extra", "--kerneltz")
            return Flag.write(self, section, value)
        end
      
-----------------------------------------------------------        
    o = s:option(Value, "name", translate("Description"))
--        o.rmempty = false  -- force validate
--        -- better validate, then: o.datatype = "minlength(1)"
--        o.validate = function(self, val, sid)
--            if type(val) ~= "string" or #val == 0 then
--                return nil, translate("Name must be specified!")
--            end
--            return val
--        end
        
-----------------------------------------------------------        
     o = s:option(Value, "src_mac", translate("MAC address")) 
        o.rmempty = false
        o.datatype = "macaddr"
        luci.sys.net.mac_hints(function(mac, name)
            o:value(mac, "%s (%s)" %{ mac, name })
        end)

-----------------------------------------------------------        
    function validate_time(self, value, section)
        local hh, mm
        hh,mm = string.match (value, "^(%d?%d):(%d%d)$")
        hh = tonumber (hh)
        mm = tonumber (mm)
        if hh and mm and hh <= 23 and mm <= 59 then
            return value
        else
            return nil, translate("Time value must be HH:MM or empty")
        end
    end
    o = s:option(Value, "start_time", translate("Start time"))
        o.rmempty = true  -- do not validae blank
        o.validate = validate_time 
        o.size = 5
    o = s:option(Value, "stop_time", translate("End time"))
        o.rmempty = true  -- do not validae blank
        o.validate = validate_time
        o.size = 5
--[[     
        o.template = "cbi_timeval"            -- Template name from above
        o.formvalue = function(self, section) -- This will assemble the parts
            local hour = self.map:formvalue(self:cbid(section) .. ".hour")
            local min  = self.map:formvalue(self:cbid(section) .. ".min")
            if hour and min and #hour > 0 and #min > 0 then
                return hour .. ":" .. min
            else
                return nil
            end
        end        
]]--
-----------------------------------------------------------        
    local Days = {'mon','tue','wed','thu','fri','sat','sun'}
    local Days1 = translate('MTWTFSS')
    
    function make_day (nday)
        local day = Days[nday]
        local label = Days1:sub (nday,nday)
        if nday==7 then
            label = '<font color="red">'..label..'</font>'
        end         
        local o = s:option(Flag, day, label)
        o.default = '1'
        o.rmempty = false  --  always call write
        
        -- read from weekdays actually
        function o.cfgvalue(self, s)
            local days = self.map:get (s, "weekdays")
            if days==nil then
                return '1'
            end
            return string.find (days, day) and '1' or '0'
        end
     
        --  prevent saveing option in config file   
        function o.write(self, section, value)
--            self.map:set(section, self.option, '')
            self.map:del (section, self.option)
        end
    end
  
    for i=1,7 do   
        make_day (i)
    end   
    
    function wd_write(self, section, value)
        value=''
        local cnt=0
        for _,day in ipairs (Days) do
            local key = "cbid."..self.map.config.."."..section.."."..day
--io.stderr:write (tostring(key)..'='..tostring(mr:formvalue(key))..'\n')
            if mr:formvalue(key) then
                value = value..' '..day
                cnt = cnt+1
            end
        end
        if cnt==7  then  --all days means no filtering 
            value = ''
        end
        self.map:set(section, "weekdays", value)
    end

-----------------------------------------------------------        
    o = s:option(Button, "_ticket", translate("Ticket")) 
        o:depends ("ac_enabled", "1")

        function o.cfgvalue(self, section)
            local ac_susp = self.map:get(section, "ac_suspend")
            if ac_susp then
                if time_elapsed (ac_susp) then
                    self.map:del (section, "ac_suspend")
                    ac_susp = nil
                else
                    local tend = os.date ("%H:%M", ac_susp)
                    self.inputtitle = tend.."\n"
                    self.inputtitle = self.inputtitle..translate("Cancel")
                    self.inputstyle = 'remove'
                end
            end
            if not ac_susp then
                self.inputtitle = translate("Issue")
                self.inputstyle = 'add'
            end
        end
                
        function o.write(self, section, value)
            local ac_susp = self.map:get(section, "ac_suspend")
--io.stderr:write ("ac_suspend="..tostring(ac_susp)..'\n')
            local key = o_ticket:cbid (o_ticket.section.section)
            local t = o_ticket.map:formvalue (key)
            t =  tonumber (t) * 60  --  to seconds
            if ac_susp then
--                ac_susp = ac_susp + t
                ac_susp = ""
            else
                ac_susp = os.time() + t
            end
            self.map:set(section, "ac_suspend", ac_susp)
--io.stderr:write ("ac_suspend="..tostring(ac_susp)..'\n')
        end

--========================================================================================================

if CONFIG_FILE_AC==CONFIG_FILE_RULES then
  return ma
else
  return ma, mr
end

