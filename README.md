# Reticulum Transport Node - Alpine Linux Guide
This is a guide for installing a [Reticulum Transport Node](https://reticulum.network) on Alpine Linux.

This guide will:
* Provide a [OpenRC](https://en.wikipedia.org/wiki/OpenRC) daemon for [rnsd](https://reticulum.network/manual/using.html#the-rnsd-utility), that's configured to start on boot
* Provide a cronjob to handle unattended system updates

## What is a Reticulum Transport Node
Here is a quote from the [official documentation](https://reticulum.network/manual/networks.html#transport-nodes-and-instances):

> Transport nodes forward packets across hops, propagate announces, maintain path tables, and serve path requests on behalf of other nodes. When a destination sends an announce, Transport Nodes receive it, remember the path, and rebroadcast it to other interfaces. When a node needs to reach a destination it doesn’t have a path for, Transport Nodes help resolve the path through the network.

Transport nodes are more or less the equivalent of modems/routers in Reticulum networks. In practice, a network typically has a relatively small number of Transport Nodes strategically placed to provide coverage and connectivity. End-user devices run as Instances, connecting through nearby Transport Nodes to reach the wider network.

An example of a network would be like a small home network. Most end-user devices, such as phones, laptops, sensors, or any device that primarily consumes network services should connect through a single Transport Node. Even devices hosting services or serving content should be configured as instances, and themselves connect to wider networks via a Transport Node provided on the network.

As far as hardware provisioning, something like a Raspberry Pi should more than suffice as a hardware platform, as Reticulum is designed for low bandwidth and high latency.

## Installation Overview
First, this guide will walk you through the process of installing Alpine Linux. After Alpine Linux is installed and configured, there's a installation script that will handle the process of installing the rnsd daemon and a cron job to handle unattended system updates. This guide will cover configuring communication interfaces using Ethernet/WiFi. Configuring radio interfaces like LoRa is outside the scope of this installation guide.

## Installing Alpine Linux
The guide for installing Alpine Linux can be found [here](https://github.com/danlbarron/alpine-install-guide)

## Configuring Alpine Linux
Once Alpine Linux is installed and rebooted, you'll be greeted by the terminal prompting you to log-in. This time, choose the user account you created.  
Once logged in, type `doas -s`. This command will require your password, which in turn, will escalate your permissions to act as root.  
Let's disable the login for root by entering `passwd -l root`.  
Let's also add a standard user that will be used for running the rnsd daemon by entering `adduser rnsuser`. The reason we create another user is we want the user to adhere to the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) by not being able to escalate permissions to act as root. You can also disable the login for rnsuser if you'd like by entering `passwd -l rnsuser`.

Now for the star of the show, let's run the installation script:
```shell
cd ~
wget https://raw.githubusercontent.com/danlbarron/rns-transport-alpine/refs/heads/main/install_rnsd.sh
chmod +x install_rnsd.sh
./install_rnsd.sh
```

You'll need to configure the reticulum config file, first setting `enable_transport = true`, and then locating a public gateway off of https://rmap.world or https://directory.rns.recipes, and copying it's config to the bottom of the config file.
```shell
apk add nano
nano /home/rnsuser/.reticulum/config

# OR
vi /home/rnsuser/.reticulum/config
```

After updating the config, you'll want to restart the daemon via `rc-service rnsd restart`. Be sure to type `exit` or `reboot` to ensure you fully logout.

Congratulations, you now have a Reticulum Transport Node!
