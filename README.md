# PyDash_OS - Information
This readme covers the operating system or "OS" portion of the PyDash. For the PCB design and python application design, see the below repositories
- PyDash_PCB
- [PyDash_App](https://github.com/JungleGim/PyDash_App)
- PyDash_Enclosure

## Introduction
PyDash_OS is a Linux kernel based OS used to provide an environment for the "PyDash" program. Key features of PyDash_OS for maintainence and future development (in order of importance) include:
- fast-booting
- graphical interface
- supports python
- stable/non-corruptible
- lightweight

Additional details on the design considerations, required packages, and key features are included in the "Methodology" section of this readme.

# Project Status
## Revlog
- Rev0 - 5/16/2025
	- Initial release based on internal testing and development
- Rev0a - 6/5/2024
	- Updated PyDash_App in root FS overlay
	- Initial functional release
- Rev1a - 5/19/2025
	- added python-rpi-gpio package for button interface
- Rev2a - 10/12/2025: WIP - not yet uploaded
  	- (finishing local testing before final upload)
  	- Added overlay for SDIO interface to mount/use SD cards
  	- Updated FStab for auto-mounting of any inserted SD card at specified location
  	- Added Fontconfig package to allow for new system fonts
  	- Added new PyDash specific root overlay for common files - including system fonts

## Future Development
### Critical items for immediate development
- Implement writeable partition
	- currently is "Read only" to help with the constant power cycling nature of an automotive dash.
 	- add a writeable partition for user files, a configuration XML, log files, etc.
- USB device support
- Implement secure boot

### Additional future development
- Add a graphical splash screen to hide the typical pi bootup garble. This is a "fit and finish" item and is not critical to operation of the display.
	- already had an attempt using the framebuffer startup service and it...kind of worked. It did display but wouldn't effectively hide all the garble. Also, the overall impact to startup time wasn't something i wanted to add to the mess. With refinement it should work but just haven't gotten there yet.
- Review/cleanup un-needed drivers to help speed up boot. Usings systemd-analyze blame to identify contributors and reduce/remove where able
  - Looking at the list, "systemd-udev-trigger.service" seems to be the top offender at just over 800ms. Looking around at other distros, this doesn't seem to take that long (usually sub 100ms).
	- Purpose of this is to trigger different devices on startup. The OS doesn't use a whole lot on startup. How much could be deferred to later and handled in post-boot?
	- [Information 1](https://github.com/systemd/systemd/issues/17264) and [Information 2](https://github.com/profusion/demystifying-systemd-for-embedded-systems/blob/b1c10727729d888c6429b90e181c2f26d55e9354/systemd-minimal-strip.sh#L143)
- Organize buildroot environment better. Match closer to the "approved" file structure for configuration files, etc.
- Better/wider range of font support.
	- One noted current issue is that using a tab-space displays a "NL" char instead of inserting a tab
- Look into additional app support
	- One popular use would be a program called "tuner studio". This is typically used already for making custom dashes.

# Requirements
## Build Environment
PyDash_OS is developed using the "buildroot" environment. The information included in the Readme highlights some of the required packages and configuration options needed to compile the output image.

## Physical Hardware
While the PyDash_OS is configurable for any hardware (depending on the buildroot options) there are some key pieces that either require additional changes or would require a re-design of the supporting PCB and/or application. The current hardware configuration consists of:
- Compute Module 4 (CM4) processor board
- Custom designed PCB (PyDash_PCB)
- Wavshare 7inch 1024x600 display
	- [link for display](https://www.waveshare.com/product/raspberry-pi/displays/lcd-oled/70h-1024600.htm?sku=22676)

# Methodology
## Key Considerations and Constraints
Several considerations or constrains were in place when building this OS. Many of these center around the intended implementation of using this as an automative display / dashboard.

- fast-booting
	- must be fast booting to display gauge information as soon as possible.
	- understood that a nearly "instant" display is not possible with the chosen hardware configuration. However, for an aftermarket "race car" application any of the "start up" time for the display will be absorbed by letting the car warm up, buckling in, putting on safety equipment like helmet and gloves, etc.
	- optimizing start time should still take priority to enhance user experience
	- current boot time is approximately 25s
- graphical interface
	- A graphical interface to display information is REQUIRED. The end goal is to have a display server that is available to users for running scripts or displaying whatever kind of information they desire.
		- Currently, X11 is used as the display server. Other options like wayland may require additional configuration changes
	- Ultimately, the data display and configuration is handled by a python app (PyDash_App)
	- Feasibly, with some extra configuration to the OS, support for other apps like tuner studio could also be implemented for a wider range of use and user preference/customization
- supports python
	- the chosen hardware of a CM4 revolves around the Raspberry Pi environment. This is widely supported and while other programming options exist, it is largely used by the community at large through python.
	- For ease of integration with other community knowledge, python is used as the chosen language of the actual dash program. For this reason, the OS must support python.
- stable/non-corruptible
	- The automotive environment has frequent un-planned power off events or also can be susceptible to a power-off event during startup.
	- Many options to combat this both in hardware and software were examined; strategies like on-board batteries and supercapacitors were considered.
	- however, the most simple and repeatable implementation to combat any corruption concerns was simply to make the OS and anything installed on the CM4 "read only". This poses some additional challenges but ensures that any un-planned power-off events will not corrupt the program or the OS.
- lightweight
	- While the CM4 comes in various configurations, some of which are highly capable, this is still an rPi. Ensuring that the overall OS and supporting packages are only installed if needed promotes a lightweight installation.
	- Additionally, this ensures that less total power and overhead computations are used (for potentially un-necessary apps) so that the overall available resources are maximized and heat generated is minimized.

## Kernel Config Options
The below contains notes/information on the various kernel configuration options that I've chosen. For instructions on specifically HOW to enable or track kernel configuration options, see the "Compiling" section under the "Creating PyDash_OS" section.

# Creating PyDash_OS
For the base configuration of the OS, I'd recommend following one of any tutorials on compiling an image for the Raspberry Pi. This will ensure that for the chosen hardware, everything is working correctly and compiles as intended. The following sections detail some of the PyDash SPECIFIC updates/changes.

## Buildroot Configuration
Buildroot must first be installed locally on the machine that will compile the OS. This readme does not cover that process, recommend following any of the available guides to install/localize buildroot.

The current buildroot version used to compile is 2024.02-573.

### Kernel Configuration
Many options are required to be configured to set up the PyDash_OS. The complete configuration is contained in the `.config` file in the buildroot external folder GIT directory. A summary of the key configurations is given here. Loading the contained config should set up the appropriate parameters to successfully compile and function.

- Use “raspberrypicm4io_64_defonfig” as a starting point
- system configuration
	- update options like the hostname, banner, and other configuration changes if desired
	~/dev management option should be “dynamic using devtmpfs + eudev”
	~Uncheck "remount root FS read-write during boot to make the OS "read only"
- Kernel Tools
	- include GPIO
- Filesystem Images
	- Usually choosing 512M as a start is appropriate
- Packages
	- Hardware handling
		- pigpio
	- firmware
		- update path to the custom config.txt used
		- update path to the custom cmdline.txt used
	- python3
		- under interpreter language and script > external modules there are several packages:
		- Python-can
		- Python-pillow
		- Python-spidev
   		- Python-rpi-gpio
	- Graphical Interface
		- X.org X window system
			- X11R7 servers should be "modular X.org"
			- X11R7 applications:
				- Twm
				- Xinit
				- Xinput
				- Xconsole
				- Xdm
			- X11R7 drivers
				- input-eudev
				- video-fbdev
		- Xterm
	- Fonts
		- Liberation
	- System Tools
		- Systemd
			- Systemd-analyze
			- network manager
				- needed for CANbus
	- Networking
		- iproute2
			- needed for CANbus

### User Patches
Any applied user patches are specific to options required to modify or update the packages pulled during compilation. There are no current applied user patches for PhyDashOS

There ARE however some patches applied to phython3 in order for it to work sufficiently with Tkinter. These have been submitted to the buildroot hive mind for approval but may change in future python revisions. Please review the files under the `packages_python3_chagnes` directory for the associated updates required to the python package for inclusion of tkiner.

### Post Build Scripts
Post-build scripts are scripts used to modify the target filesystem after its generation. See the `pydash_postbuild_script.sh` file for the full list. REMINDER: this must be configured in buildroot as well.

A summary of the modifications in the post build script are listed below:
- Update config.txt for SPI and CANbus related changes
- Update config.txt for boot characteristics
- Update cmdline.txt for login/silent boot characteristics
- Update root OS files related to Xorg (graphical display) performance
- Update root OS files related to Xorg to launch PyDash app on startup
- Update system.conf to shorten stop/timeout limits

## Root FS Overlays
Using the root FS overlay allows buildroot to place files into the root filesystem it generates as an image during compilation.

Users need to configure an external directory that will be populated with the root FS overlay files. Within buildroot, If a relative path is given, it will correspond to the buildroot base directory. For example, if buildroot is in `/home/user/desktop/buildroot-2023.11/` and the given relative path is `/my_boards/rpi/cm4/cm4_rootFS_ovrly/` then anything in the folder `home/user/desktop/buildroot-2023.11/my_boards/rpi/cm4/cm4_rootFS_ovrly/` will be applied to the root files and folder structure during compilation of the image.

If a folder in the external FS overlay directory exists in the base OS image, any included files and/or folders will be merged. For example, if the “root FS overlay” folder contains a “root” folder, then those files/directories will be placed into the “root” directory of the OS.

Currently, the PyDash_app and requisite files is contained in an overlay folder `/root/pydash`

## Compiling
After loading the associated configuration file and/or configuring buildroot with the desired options, running a `make clean all` command will start the process of compiling the OS.

## Installing
After performing the `make all` or `make clean all` command, Buildroot will compile the OS. When complete, the system image is located at  `/<buildroot dir>/output/images/sdcard.img`. This image can then be flashed to the Pi device using any of the typical means. Typically, for most people, this will be the "Raspberry Pi Imager" software available for download on their site.

# Known bugs and bug fixes
No current known bugs

# FAQ section
No current FAQ

# Copyright and licensing information
All of the end products of Buildroot (toolchain, root filesystem, kernel,bootloaders) contain open source software, released under various licenses. Using open source software gives you the freedom to build rich embedded systems, choosing from a wide range of packages, but also imposes some obligations that you must know and honour. Some licenses require you to publish the license text in the documentation of your product. Others require you to redistribute the source code of the software to those that receive your product. The exact requirements of each license are documented in each package, and it is your responsibility (or that of your legal office) to comply with those requirements.

The output of the buildroot "make legal-info" output is contained in the "legal-info" GIT directory and contains relevant licensing information for the current configuration.
 
The information included in this repository is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software or tools included in this repository.

# General Notes
While I am an engineer by trade, my area of focus is not computer architecture or system engineering. Likely some people have already looked at various aspects of the codebase and just shook their heads. This has largely been a self-taught endeavor and I'm constantly improving; The compiled list of considerations and notes for the project that have helped me along the way, as i hope they may also help others. These are listed below, in no particular order.

## Buildroot Notes
- To reset buildroot for a new target use the “$ make distclean” command
- A full rebuild can be done using the “$ make clean all” command
- A list of the enabled packages and other data in the current configuration can be done using “$ make show-info”
- For temporary modifications, you can modify the target filesystem files directly and rebuild the image.
	- The target filesystem is available under “output/target/”. 
		- Can make changes to the various files here as a temporary test of making it into the build.
		- the proper way to integrate this into buildroot is to modify these files using post-scripts.
		- After making your changes, run “$make” to rebuild the target filesystem image.
	- Additionally, “config.txt” is under “output/images/rpi-firmware”
		- Can modify to change things that need to be put into the device tree.
	- REMINDER: ANY CHANGES MADE TO THE TARGET FILESYSTEM THIS WAY DO NOT SURVIVE A “make clean”
	
- When making a new config, saving the current config occurs in the parent directory and is stored in a “.config” file.
	- Remember that you can save the config as a separate named config, however when using the “make” command it will pull from the default “.config” information that was assigned when using the “make <defconfig>” command. As a result, any of the saved config information will not be compiled.
	- Before exiting, save as the default “/.config” file. OR make sure the correct config file is pointed to in the makemenu

- My chosen nomenclature for backup config files is:
	- (rev)_(device type)_(program)_(date)
		- Rev: revision, usually “test” for trying things out or “r0”, “r1.0”, “r1.1”, etc. for revisions
		- Device type: for my case, usually is “CM4”
		- Program: usually the specific hardware program that’s being configured. Less of a “script” program and more the development program (product) being configured.

# References
Throughout the project, I have used many references, related to various aspects/items of the project. These are all compiled in the list below, in no particular order

- [Buildroot for rPi](https://medium.com/@hungryspider/building-custom-linux-for-raspberry-pi-using-buildroot-f81efc7aa817)
- [Buildroot Setup Info](https://rickcarlino.com/2021/building-tiny-raspberry-pi-linux-images-with-buildroot.html)
- [Xorg setup in Buildroot](https://agentoss.wordpress.com/2011/03/06/building-a-tiny-x-org-linux-system-using-buildroot/)
- [X11 setup in Buildroot](https://unix.stackexchange.com/questions/70931/how-to-install-x11-on-my-own-linux-buildroot-system)
- [Generating and Applying Patches in Buildroot](https://stackoverflow.com/questions/6382986/how-to-apply-patches-to-a-package-in-buildroot?rq=1)
- [Buildroot manual - FS overlays](https://buildroot.org/downloads/manual/manual.html#rootfs-custom)
- [Using FS overlay in Buildroot](https://otm.my.id/2019/06/02/using-rootfs-overlay-in-buildroot/)
- [Long shutdown time in Linux](https://itsfoss.com/long-shutdown-linux/)
- [SED command in scripts](https://itsfoss.com/long-shutdown-linux/)
- [Change File and Save](https://stackoverflow.com/questions/56899947/shell-command-to-change-file-and-save)
- [File Editing with Scripts](https://stackoverflow.com/questions/52323732/text-file-edit-using-shell-scripting-in-linux)
- [Changing file contents with Scripts](https://stackoverflow.com/questions/14643531/changing-contents-of-a-file-through-shell-script)
- [Applying patches in Buildroot](https://stackoverflow.com/questions/6382986/how-to-apply-patches-to-a-package-in-buildroot?rq=1)
- [Systemd Target Levels](https://opensource.com/article/20/5/systemd-startup)
- [Linux Command Line Connecting to WiFi](https://www.baeldung.com/linux/connect-network-cli)
