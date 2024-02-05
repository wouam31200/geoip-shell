# Considerations for answering the questions asked by the `-install` script.

**'Please enter your country code':**

If you answer this question, the `-manage` script will check that the changes in ip lists which you request to make will not block your own country. This applies both to the installation process, and to any subsequent changes to the ip lists which you may want to make in the future. The idea behind this is to make this tool as fool-proof as possible.

**'Is this device a (r)outer or a (h)ost?':**

Answering this question is mandatory because the firewall is configured differently for each case. Answering it incorrectly may cause unexpected results, including having no geoip blocking or losing remote access to your machine.

If you do not know what is a router or a host then I suggest you to read up before using this project.

For a router, geoip rules are applied to traffic arriving from the WAN interface(s). For a host, geoip rules are applied to traffic arriving from anywhere. When the suite is installed in whitelist mode, additional rules are created for a host which add LAN subnets to the whitelist in order to avoid blocking them.

**'Autodetected ipv4 LAN subnets: ... (c)onfirm, c(h)ange, (s)kip or (a)bort installation?'**

You will see this question if installing the suite in whitelist mode and you chose 'host' in the previous question. The reason why under these conditions this question is asked is explained above, in short - to avoid blocking your LAN from accessing your machine.
If you are absolutely sure that you will not need to access the machine from the LAN then you can type in 's' to skip.
Otherwise I recommend to add LAN subnets to the whitelist.
The autodetection code should, in most cases, detect correct LAN subnets. However, it is up to you to verify that it's done its job correctly.
One way to do that is by typing in 'c' to confirm and once installation completes, verifying that you can still access said device from LAN (note that if you have an active connection to that machine, for example through SSH, it will most likely continue to work until disconnection even if whitelisting of LAN subnets did not work out correctly).
Of course, this is risky in cases where you do not have physical access to the machine.
Another way to do that is by examining your network configuration (which is generally configured on your router) and making sure that the autodetected subnets match those in the configuration.
If you find out that the subnets were detected incorrectly, you can type in 'h' and manually enter the correct subnets which you want to whitelist. I would also appreciate if you let me know about that so I can improve the autodetection code (I will need some details about your network).

**'(A)uto-detect local subnets when autoupdating and at launch or keep this config (c)onstant?'**

As the above question, you will see this one if installing the suite in whitelist mode and you chose 'host'.
The rationale for this question is that network configuration may change, and if it does then previously correctly auto-detected subnets may become irrelevant.
If you type in 'a', each time geoip firewall rules are initialized or updated, LAN subnets will be re-detected.
If you type in 'c' then whatever subnets have been detected during installation will be kept forever (until you re-install the suite).
Generally if autodetection worked as expected during installation, most likely it will work correctly every time, so it is a good idea to allow auto-detection with each update. If not then, well, not.