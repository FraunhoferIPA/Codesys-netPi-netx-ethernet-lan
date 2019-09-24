
### Secured netPI Docker

netPI features a restricted Docker protecting the system software's integrity by maximum. The restrictions are 

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

## CODESYS Control

This container is based on hilschernetpi/netpi-codesys-basis and hilschernetpi/netpi-netx-ethernet-lan and combines both to make the netx interface available in the CODESYS environment. This image can be used to run an EtherCAT master on the eth0 port and connect to CODESYS via the cifx0 (RTE) ports. Thereby the higher speed capable eth0 is used for the EtherCAT master and the slower cifx0 (RTE) port is used for programming and control of the CODESYS soft PLC via the Windows IDE. 

Made for [netPI](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Debian with SSH server, user pi and basic settings to run CODESYS Control for Raspberry Pi SL or Pi MC SL including activation of netx RTE interface

The image provided hereunder deploys a container with a basic setup of Linux tools, utilities and user needed for a flawless installation of the CODESYS Control for Raspberry Pi (SL and MC SL) packages across the Windows® based [CODESYS Development System V3](https://store.codesys.com/codesys.html?___store=en&___from_store=en).

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell) and created user 'pi'(sudo). This setup is equivalent to a stripped down Raspbian OS with least capabilities.

Once the container is started it needs to be upgraded first with the Raspberry runtime packages [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) or [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html). We do not offer these packages preinstalled within the container since the End User License Agreement for these packages have to be accepted by each user individually.

By default the runtime is time limited to run 1 hour until it stops. It needs an upgrade in a separate [licensing procedure](https://www.codesys.com/the-system/licensing.html).

#### Container prerequisites

##### Bridge network (Alternative A) not recommended

Use bridge network mode in case the container shall run isolated and requires no further control of the host network interface `eth0` (or other) required for Modbus TCP, PROFINET or similar communications.

Bridge mode works like a firewall where all container network ports are closed by default. For incoming network traffic ports need to be opened explicitly.

To allow the CODESYS Development System installing the CODESYS Runtime into the container the container TCP port `22` needs to be exposed to the host.

To allow the CODESYS Development System communicating with the deployed CODESYS Runtime the container TCP port `1217` needs to be exposed to the host.

The CODESYS runtime starts an OPC UA server. To access the OPC UA server from an OPC UA client the container TCP port `4840` needs to be exposed to the host.

##### Host network (Alternative B) recommended for EtherCAT Master on eth0

Use host network mode in case the container requires control of the host network interface `eth0` (or other) required for Modbus TCP, PROFINET or similar communications.
Using this mode makes port mapping unnecessary since all the container's used ports are exposed to the host automatically.
To grant access to the netX from inside the container the `/dev/spidev0.0` host device needs to be exposed to the container.
To allow the container creating an additional network device for the netX network controller the `/dev/net/tun` host device needs to be expose to the container.

##### Environment Variables

The assignment of the Ethernet network interface's IP address is configured through the following variables

* **IP_ADDRESS** with a value in the format `x.x.x.x` e.g. 192.168.0.1 configures the interface's IP address. A value `dhcp` instead enables the dhcp mode and the interface waits to receive its IP address through a DCHP server.
* **SUBNET_MASK** with a value in the format `x.x.x.x` e.g. 255.255.255.0 configures the interface's subnet mask. It is not necessary to configure in dhcp mode.
* **GATEWAY** with a value in the format `x.x.x.x` e.g. 192.168.0.10 configures the interface's gateway address. It is not necessary to configure in dhcp mode.

##### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly. 

netPI's secure reference software architecture prohibits root access to the Host system always. Even if priviledged mode is activated the intrinsic security of the Host Linux Kernel can not be compromised.

##### Host device

The CODESYS runtime perfoms a license/serial number check when started. To grant access to the VideoCore GPU chip the `/dev/vcio` host device needs to be exposed to the container. In case the device is not exposed the CODESYS runtime will stop after 30 seconds without any message.

#### Getting started

STEP 1. Open netPI's website in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **fokkersim/netpi-codesys-netx-nodered**
*Network > Network* | **bridge** or **host** | use alternatively (host mode for EtherCAT master on eth0)
*Port mapping* | *host* **22** -> *container* **22** | in bridge mode
*Port mapping* | *host* **1217** -> *container* **1217** | in bridge mode
*Port mapping* | *host* **4840** -> *container* **4840** | in bridge mode
*Restart policy* | **always**
*Runtime > Devices > +add device* | *Host path* **/dev/vcio** -> *Container path* **/dev/vcio** |
*Runtime > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** |
*Runtime > Devices > +add device* | *Host path* **/dev/net/tun** -> *Container path* **/dev/net/tun** |
*Runtime > Env* | *name* **IP_ADDRESS** -> *value* **e.g.192.168.0.1** | value `dhcp` enables dhcp mode
*Runtime > Env* | *name* **SUBNET_MASK** -> *value* **e.g.255.255.255.0** | not needed in `dhcp` mode
*Runtime > Env* | *name* **GATEWAY** -> *value* **e.g.192.168.0.10** | not needed in `dhcp` mode
*Runtime > Env* | *name* **PASSWD** -> *value* **e.g.raspberry** | pwd for ssh & co
*Runtime > Env* | *name* **USER** -> *value* **e.g.pi** | user for ssh & co
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

Pulling the image may take a while (5-10mins). Sometimes it may take too long and a time out is indicated. In this case repeat STEP 4.

#### Accessing

A started container is immediately ready to receive the initial load of the "CODESYS Control Runtime for Raspberry" in the versions "Pi SL" or "Pi MC SL" packages. This is done via the IP specified in the IP_ADDRESS environment variable and a connection to the RTE Ethernet ports of the NetPI RTE.

STEP 1: Upgrade your CODESYS development system with support for Raspberry compatible platforms by using the function `Tools -> Package Manager -> Install` and choose the package `CODESYS Control for Raspberry Pi 3.5.xx.xx.package` you downloaded before.

STEP 2: Restart CODESYS development system to activate the installed package.

STEP 3: Use the new function `Tools -> Update Raspberry Pi` to deploy your "CODESYS Control for Raspberry" package to the container. Enter the user `pi` and the password `raspberry` as `Login credentials`. Enter your netPI's IP address in`Select target -> IP address` , choose the version under `Package` you want to get installed and press `Install`. The installation may take up to 1 minute. You will see some message outputs during the installation. (the error "tar: Removing leading / from member names" can be ignored).

STEP 4: Press `Runtime -> Start` to activate the CODESYS runtime in the container. This will also activate an automatic start of the runtime during power cycles.

STEP 5: Setup a communication path to netPI using the software gateway running in netPI's runtime. Create a new gateway with netPI's IP address at port 1217. Then use the `Scan network` option and click on the device found. e.g. host mode: NTB827EBEA02D0 [0000.0539]. 

#### IMPORTANT INFORMATION: BACKUP YOUR LICENSE

Usually an email with a ticket number (e.g A78HY-TBVMD-8SVC7-P8BHX-4LED6) is granting you a license. Together with the CODESYS development system the ticket number is transformed in a license deployed to the device to activate the unlimited runtime. 

Since the ticket number gets invalid during the licensing procedure and cannot be reused again the only license copy is stored on the device **in the container** worth it to backup. If the container gets lost or is deleted your license copy is **gone forever**.

To backup the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&start=15#p10689).

To restore the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&p=10690#p10690).

#### Versions tested
The container has been successfully tested against the [CODESYS Development System V3](https://store.codesys.com/codesys.html) in the version V3.5.14.0 and the [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) and [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html) both in the version V3.5.14.0.

#### Youtube

HINT: The video does not show the mapping of the `/dev/vcio` host device

[![Tutorial](https://img.youtube.com/vi/cXIHu3-4-eg/0.jpg)](https://youtu.be/cXIHu3-4-eg)

#### Automated build

The project complies with the scripting based [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build the image output file. Using this method is a precondition for an [automated](https://docs.docker.com/docker-hub/builds/) web based build process on DockerHub platform.

DockerHub web platform is x86 CPU based, but an ARM CPU coded output file is needed for Raspberry systems. This is why the Dockerfile includes the [balena.io](https://balena.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/) steps.

#### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
