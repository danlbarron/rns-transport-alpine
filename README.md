# Reticulum Transport Node - Alpine Linux Installation Guide
This is a guide for installing a [Reticulum Transport Node](https://reticulum.network) on Alpine Linux.

This guide will:
* Provide a [OpenRC](https://en.wikipedia.org/wiki/OpenRC) daemon for [rnsd](https://reticulum.network/manual/using.html#the-rnsd-utility), that's configured to start on boot
* Provide a cronjob to handle unattended system updates

## What is a Reticulum Transport Node
Here is a quote from the [official documentation](https://reticulum.network/manual/networks.html#transport-nodes-and-instances):

*Transport nodes forward packets across hops, propagate announces, maintain path tables, and serve path requests on behalf of other nodes. When a destination sends an announce, Transport Nodes receive it, remember the path, and rebroadcast it to other interfaces. When a node needs to reach a destination it doesn’t have a path for, Transport Nodes help resolve the path through the network.*

~

Transport nodes are more or less the equivalent of modems/routers in Reticulum networks. In practice, a network typically has a relatively small number of Transport Nodes strategically placed to provide coverage and connectivity. End-user devices run as Instances, connecting through nearby Transport Nodes to reach the wider network.

An example of a network would be like a small home network. Most end-user devices, such as phones, laptops, sensors, or any device that primarily consumes network services should connect through a single Transport Node. Even devices hosting services or serving content should be configured as instances, and themselves connect to wider networks via a Transport Node provided on the network.

As far as hardware provisioning, something like a Raspberry Pi should more than suffice as a hardware platform, as Reticulum is designed for low bandwidth and high latency.

## Installation Overview
First, this guide will walk you through the process of installing Alpine Linux. After Alpine Linux is installed and configured. There's a installation script that will handle the process of installing the rnsd daemon and a cron job to handle unattended system updates. This guide will cover configuring communication interfaces using Ethernet/WiFi. Configuring radio interfaces like LoRa is outside the scope of this installation guide.

## Installing Alpine Linux
Download the [Alpine Linux image](https://alpinelinux.org/downloads) that suites the device you intend to install on. You want an image that ends in .iso or .img.gz.
Download [balenaEtcher](https://etcher.balena.io) and use it to flash the chosen image to either a USB drive or an SD card, depending on your needs (PC/Laptop or Raspberry Pi).
Boot your device with either the flashed USB drive or SD card. You might need to get instructions from the device's manufacturer on how to boot from a USB drive / SD card.

Once Alpine Linux boots, you'll be greeted by a terminal prompting you to log-in. The user name is `root` and there's no password. Once logged in, run `setup-alpine`.

### Steps for the Alpine Linux Installer (see also: [Alpine Linux Wiki Installation page](https://wiki.alpinelinux.org/wiki/Installation#Base_configuration))
**Keyboard Layout**: Choose the keyboard layout and variant that best suites your keyboard. If you live in the United States, it'll likely be `us` for both.  
**Hostname**: This will be the name of your computer. Come up with a cool hacker name (or don't, the choice is yours).  
**Network Interface**: Available interfaces are `eth0` and `wlan0`, however, these options might change based on your hardware. I recommend using ethernet if at all possible. You'll be prompted a few additional questions on setting up the chosen network interface. Defaults are probably fine, but use your own discretion.  
**Root Password**: Root will be the admin account, so you'll want to choose a strong password.  
**Timezone**: Choose your local timezone. If you live in the US Central Timezone, you'd choose `US/` followed by `Central`.  
**HTTP/FTP Proxy URL**: Choose `none`.  
**Network Time Protocol**: Choose `chrony`, unless you know what you're doing.  
**APK Mirror**: Choose the default, `1`, unless you know that you'll need to choose another mirror due to your region.  
**Setup a user**: Enter a memoriable username (technically this is optional, but we're disabling root logins later).  
**Enter ssh key or URL for user**: Choose `none`, unless you intend to use SSH.  
**Which ssh server**: Choose `none`, unless you intend to use SSH. As a side note, you could also setup [rnsh](https://reticulum.network/manual/using.html#the-rnsh-utility) on your own later, but that's outside the scope of this guide.  
**Which disk(s) would you like to use**: This is the disk/ssd drive you want to install to. Choose the relevant option that's shown as available. Typically this would be `sda`.  
**How would you like to use it**: This is how you would like the disk/ssd drive to be configured. The options are `sys`, `data`, `crypt`, `cryptsys`, `lvm`, `lvmsys`, and `lvmdata`. Choose `lvmsys`, unless you know what you're doing. You can also enter `?` to learn more.  
**WARNING: Erase the above disk(s) and continue (y/n)**: This is the point of no return. Unless you think you need to go back to choose a different option in a prior step, choose `y`.

Once the installation is complete, type `reboot`. Congratulations on your fresh install of Alpine Linux!

## Configuring Alpine Linux
Once rebooted, you'll be greeted by a terminal prompting you to log-in. This time, choose the user account you created.  
Once in, type `doas -s`. This command will require your password, which in turn, will escalate your permissions to act as root.  
Let's disable the login for root by entering `passwd -l root`.  
Let's also add a standard user that will be used for running the rnsd daemon by entering `adduser rnsuser`. The reason we create another user is we want the user to adhere to the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) by not being able to escalate permissions to act as root. You can also disable the login for rnsuser if you'd like by entering `passwd -l rnsuser`.

Now the star of the show, let's run the installation script:
```shell
cd ~
wget https://raw.githubusercontent.com/danlbarron/rns-transport-alpine/refs/heads/main/install.sh
chmod +x install.sh
./install.sh
```

You'll need to configure the reticulum config file, by setting `enable_transport = true` and locating a public gateway off of https://rmap.world or https://directory.rns.recipes and copying it's config to the bottom of the config file.
```shell
apk add nano
nano /home/rnsuser/.reticulum/config

# OR
vi /home/rnsuser/.reticulum/config
```

After updating the config, you'll want to restart the daemon via `rc-service rnsd restart`
Congratulations, you now have a Reticulum Transport Node!