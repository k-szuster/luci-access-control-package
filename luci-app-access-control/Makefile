#    Copyright (C) 2014 Nikos Mavrogiannopoulos
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-access-control
PKG_RELEASE:=0.4.1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-access-control
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:= Internet access control module
  DEPENDS:=+luci-lib-nixio +luci-mod-admin-full
  PKGARCH:=all
endef

define Package/luci-app-access-control/description
#	Internet access control for LuCi web interface
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-access-control/install
	$(CP) ./files/* $(1)/
endef

define Package/luci-app-access-control/postinst
#!/bin/sh
/etc/init.d/inetac enable
/etc/init.d/inetac start
exit 0
endef

define Package/luci-app-access-control/prerm
#!/usr/bin/lua
require "uci"
os.execute ("exec /etc/init.d/inetac stop")
os.execute ("exec /etc/init.d/inetac disable")
local x = uci.cursor()
local commit = false
x:foreach ("firewall", "rule", 
    function(s) 
        if s.ac_enabled~=nil  then
            x:delete ("firewall", s[".name"])
            commit = true
        end
    end)
if commit then    
    x:commit("firewall")
end
endef

$(eval $(call BuildPackage,luci-app-access-control))
