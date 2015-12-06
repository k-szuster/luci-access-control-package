Internet Access Control for OpenWrt
===================================

This software is designed for OpwnWrt routers.
It allows you to restrict the internet access for specific hosts in your LAN.
You can block the internet access permanently or on schedule basis for any MAC address.
After installation you'll find a new page in OpenWrt's GUI: Network/Access control.

The software is a Luci app extending system's firewall, so it runs on any platform with no need of recompiling.
Tested on OpenWrt BB and CC.

Screen shot
-----------
![Internet Access Control](https://github.com/k-szuster/luci-access-control-package/blob/master/snapshot1.png?raw=true)

Source repository
-----------------
https://github.com/k-szuster/luci-access-control-package
    
See also: https://github.com/k-szuster/luci-access-control
for a luci-app version of the same software.

To install without building ipk package
---------------------------------------
Copy contents of luci-app-access-control/files to / directory on target machine.

To build the package for OpenWrt
--------------------------------
- In your openwrt source directory copy feeds.conf.default to feeds.conf.
- Edit feeds.conf: the line containing "src-link custom" should point to this directory (containing luci-app-access-control/).
- In your openwrt source directory:
    ./scripts/feeds update custom
    ./scripts/feeds install -a

- Run:
make menuconfig

Here, you must include the following packages in your OpenWRT build for everything to work.

	LuCI -> applications -> luci-app-access-control

- Call make to compile OpenWRT with the selected package installed.
You'll find it in <openwrt>/bin/<target>/packages/custom/luci-app-access-control_....ipk file.

- Install luci-app-access-control package on the OpenWrt router.
