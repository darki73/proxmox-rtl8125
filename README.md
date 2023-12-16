# Realtek 8125 Ethernet Driver manager for Proxmox VE
This script simply pulls the specified driver version from the Realtek website and then installs it as DKMS module.

# Why
There are many repositories which provide already precompiled binaries for the Realtek 8125 driver. 
There are also repositories which provide the driver as DKMS module, however, they are too bulky for such a simple task.  
I wanted to have a solution which is easy to maintain and undertand.  

The issue with the Realtek 8125 driver is that it is not included in the Linux kernel. So you have to compile it yourself. This is where DKMS comes into play. DKMS is a framework which allows you to automatically recompile kernel modules when a new kernel is installed. This script simply pulls the specified driver version from the Realtek website and then installs it as DKMS module.

Also, since it is written in bash, it should be pretty easy for anyone to understand/modify and verify that it is not doing anything malicious.

# Proxmox VE 8 and Realtek note
As of time of publishing this script, Proxmox VE 8 is running the `Linux 6.5.11-7-pve (2023-12-05T09:44Z)` kernel.  
As you might have noticed, on the main website of Realtek, they mention that the driver is only compatible with kernels up to 6.4.  

This is not an issue, as the driver is able to compile on newer kernels.

Here is the output of the `ethtool` command on my Proxmox VE 8 server:
```
        Supported ports: [ TP    MII ]
        Supported link modes:   10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
                                1000baseT/Full
                                2500baseT/Full
        Supported pause frame use: Symmetric Receive-only
        Supports auto-negotiation: Yes
        Supported FEC modes: Not reported
        Advertised link modes:  10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
                                1000baseT/Full
                                2500baseT/Full
        Advertised pause frame use: Symmetric Receive-only
        Advertised auto-negotiation: Yes
        Advertised FEC modes: Not reported
        Link partner advertised link modes:  100baseT/Half 100baseT/Full
                                             1000baseT/Full
                                             2500baseT/Full
        Link partner advertised pause frame use: Symmetric
        Link partner advertised auto-negotiation: Yes
        Link partner advertised FEC modes: Not reported
        Speed: 2500Mb/s
        Duplex: Full
        Auto-negotiation: on
        master-slave cfg: preferred slave
        master-slave status: slave
        Port: Twisted Pair
        PHYAD: 0
        Transceiver: external
        MDI-X: Unknown
        Supports Wake-on: pumbg
        Wake-on: d
        Link detected: yes
```

And output from `modinfo` (some lines removed for brevity):
```
filename:       /lib/modules/6.5.11-7-pve/updates/dkms/r8125.ko
version:        9.012.03-NAPI
license:        GPL
description:    Realtek r8125 Ethernet controller driver
author:         Realtek and the Linux r8125 crew <netdev@vger.kernel.org>
srcversion:     80AA932EEAEA9E2392B4B5E
alias:          pci:v000010ECd00005000sv*sd*bc*sc*i*
alias:          pci:v000010ECd00008126sv*sd*bc*sc*i*
alias:          pci:v000010ECd00003000sv*sd*bc*sc*i*
alias:          pci:v000010ECd00008162sv*sd*bc*sc*i*
alias:          pci:v000010ECd00008125sv*sd*bc*sc*i*
depends:
retpoline:      Y
name:           r8125
vermagic:       6.5.11-7-pve SMP preempt mod_unload modversions
sig_id:         PKCS#7
signer:         DKMS module signing key
```