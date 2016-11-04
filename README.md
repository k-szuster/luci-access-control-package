Internet Access Control for OpenWrt
===================================

This software is designed for OpwnWrt routers.
It allows you to restrict the internet access for specific hosts in your LAN.
You can block the internet access permanently or on schedule basis for any MAC address.
The schedule contains the  time of a day and the deys of the week.
New in version 4:
You can also issue a "ticket" for any blocked user. It gives him an extraordinary access to the internet for a given time.

The software is a Luci app extending system's firewall, so it runs on any platform with no need of recompiling.
Tested on OpenWrt BB and CC.
Note: due to a bug in CC, the times must be set in UTC, rather than local time.

After installation you'll find a new page in OpenWrt's GUI: Network/Access control.

Screen shot
-----------
![Internet Access Control](https://github.com/k-szuster/luci-access-control-package/blob/master/snapshot1.png?raw=true)

Source repository
-----------------
https://github.com/k-szuster/luci-access-control-package
    
See also: https://github.com/k-szuster/luci-access-control
for a luci-app version of the same software.

To install prebuilt package
----------------------------
Visit: https://github.com/k-szuster/luci-access-control-package/releases
Download ipk file to your device and install it with opkg.
Or:
copy contents of luci-app-access-control/files to / directory on target devicee.

To build the package for OpenWrt
--------------------------------
- In your openwrt source directory copy feeds.conf.default to feeds.conf.
- Edit feeds.conf. Add the following line:

	src-git custom https://github.com/k-szuster/luci-access-control-package.git

- In your openwrt source directory:
    ./scripts/feeds update custom
    ./scripts/feeds install -a

- Run:
make menuconfig

Here, you must include the following packages in your OpenWRT build for everything to work.

	LuCI -> applications -> luci-app-access-control

- Call make to compile OpenWRT with the selected package installed.
You'll find it in <openwrt>/bin/<target>/packages/custom/luci-app-access-control_....ipk file.
