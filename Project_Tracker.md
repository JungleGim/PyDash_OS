# PyDash OS - Project Tracker
project tracker for WIP issues, what's currently being worked on, and anything that may need to move to the actual README file

## Version
Version: 2.0 - final TBD: See testing config file revlog
Build Date: N/A

## Testing config file revlog
* Pydash_r2a_test_20250921
	- Read/Write FS + xterm access + mouse visibility
	- First image with a new partition
	- Seems to have worked from the buildroot output and image size
	- Also have other root FS files for fonts, etc.
	- TBD improvements:
		+ Made a 1Gb partition for the users. Seems a bit large? At the same time not for lots of logs and potentially images, etc for dash resources. The CM4 board I’m using has LOTS of storage so it’s just a bit of a pain when making the image that it’s extra large is all
	- Test results
		+ Actually made the partition and auto-mounted it!
		+ Fonts were recognized in python, albeit with some interesting results to work through
		+ No OTG systemd file was set up though so the USB gadget functionality didn’t work
* Pydash_r2a_test_20250922
	- genimage appropriately made a fat32 type image and mounted it
	- Using  “srcpath” with vFAT genimage config worked and copied all the files I wanted.
	- Cleaning up the “open sans” font files worked. Limiting to just the “normal” ones (like removing OpenSans-Light, which had its name in the data as “OpenSans” worked.
	- Verified the fonts actually render as intended in a tkitner window!
* Pydash_r2a_test_20250925
	- Verified that all the USB gadget changes got backed out
	- Verified the specific “fonts” root FS overlay
	- Verified the “test program” file is included in the image
* cm4_pydash_r2a_20251005
	- Actually works
	- Uses the modified fstab entry that creates an automount unit through x-systemd.automount and options
	- Verified buildroot image
* cm4_pydash_r2a_20251005
	- added “/mnt/uSD” to overlay fs and tested
	- changed “/root” fs overlay to just “/PyDash/” and kept everything there
	- included modified fstab to overlay fs from testing
	- verified SD card access
	- used the “rev2a_testprog” to successfully detect the card plug/unplug and read files
* cm4_pydash_r2a_20251012
	- slight refinements and updates
* cm4_pydash_r2a_20251005
	- compiled using buildroot ver 2025.11 on new VM
	- tested OK with SD card and tkinter – basic testing on bench, not full testing. Still a good version to settling into 2.0a testing for the other parts of the project

# TODO
## WIP Version TODO list
any changes required for the ongoing development and pushing towards the final version
* perform some additional checks with the uSD card and hardware
	- Would a “Device timeout” in the fstab entry to un-mount the drive be appropriate?
		+ If it’s fast enough to re-mount when accessing a file, the automount trap will always re-mount the directory when accessed and then if idle, the unmount will flush the buffer and put it in a much more “safe” state for removal. Thinkaboutit.
		+ Most use cases (like when logging) would access the card every ~1s max (usually much-much faster) so this shouldn't be an issue. When not logging there's really no need to have it mounted.
		+ Potential downside would be that if it un-mounts and then you try to start logging, the program would have to see if its currently mounted or not and handle re-mounting it.
	- Test multiple different SD cards
		+ Make sure the fsstab works for all sorts of different types and sizes of uSD cards.
		+ Ultimately need to test/replicate what it might be like for users to try a bunch of different SD cards. Need to figure out what does and doesn't work for a future user guide
		+ Also then, try it with the “test program” with different files in it and just make sure the program can see everything appropriately.

* Test with existing HW
	- use the new OS with existing dash hardware as a test
	- current version passes bench-test on CM4IO board and benchtop configuration
		+ Need to test using the other various options typical to the final pydash OS like a fully hooked up CANbus, etc.
	- Test final “next revision” of pydash program and make sure it loads/works with the new setup
* Test with new Rev 2.0 package
	- after testing with eixsting hardware and before signing off final ver 2.0, test with all rev2 components (PCB, enclosure, app, etc.)

## Development Finishing
Any temp changes needed to revert back before creating the release - not nesc code/config changes but more "debug" changes
* Update config to be read-only on boot (don't re-mount as RW)
* Remember to update the post-build script to launch compiled PYC file

# High Level notes and change tracking
This section contains the various changes needed to implement the updates in planned ver 2.0a
## Kernel/Other Changes
* Buildroot packages
	- Added util-linux (lsblk, lshw, etc.) to help troubleshoot/look for devices
		+ This is done by enabling “basic_set” under <target_packages>/system_tools/util-linux

## uSD Card - SDIO
### References
* https://forums.raspberrypi.com/viewtopic.php?t=392261
* https://wiki.archlinux.org/title/Fstab
* https://unix.stackexchange.com/a/800185/601305
* https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html

### Version Changes
This section contains the various changes needed to implement the uSD card through SDIO
* Add the “SDIO” hardware handling package for the RPI.
	- <target_packages>/<hardware_handling>/<firmware>/<brcmfmac-sdio-firmware-rpi>.
* Modify config.txt
	- Add the below to the end of config.txt
		* #Enable SDIO interface on GPIO22-27
		* #periodic polling, 25MHz, 4bit width (default)
		* dtoverlay=sdio,poll_once=off,sdio_overclock=25
* Make the mount directory in the FS overlay
	- Using “/mnt/uSD” for my mount point
	- Since the FS is mounted as read only, it’s not a problem but for read/write FS, should make this dir “read only” as kind of a protection against writing here when the device isn’t mounted.
* Fstab
	- Updated fstab to make an automount unit
	- /dev/mmcblk1p1 /mnt/uSD vfat nofail,x-systemd.automount,x-systemd.mount-timeout=1s,umask=000 0 0
	- This actually does EXACTLY what I originally wanted, and does not need an additional udev rule or any other shenanigans

### Additional Notes
This section doesn't necesarily include final changes but was more of a running tally of thigns I tried and was a point to keep notes on ongoing issues

* Tried using an automount unit to handle mounting the uSD card
	- The reason for this was because at its core, it sets up the ability/hook to mount the files but only once the need to access that point is demanded, like someone trying to navigate to that location.
	- The idea was then that if the card was present at start or not wouldn’t matter and the automount unit would catch it
	- Tried testing and was getting issues so, just reverted back to having an fstab entry AND a udev rule 
* The SD/MMC card standard interface is “/dev/mmcblk1” for the “1st” device (not the 0th which is the OS). And then “xxxx1p1” is the first partition. So the full device in the rule likely should be “/dev/mmcblk1p1”. Confirmed this is what worked in fstab.
* Calling “bin/mount -a” in a udev rule doesn’t work because udev runs in a different environment, so it can’t access folders/files in the same way that running the same command from the CLI does.
* Testing fstab + udev
	- Ultimate goal: Determine if having both the fstab entry and udev rule result in the drive correctly mounting on boot, and then also for ever subsequent remove/insert?
	- 1) test just fstab
		+ What happens on startup with card inserted/not?
			* With the card inserted on boot, fstab correctly recognizes and mounts the device. It does this because of the “auto” specification which is DIFFERENT than the “automount” terminology. Would have to use “noauto” to function similar to an automount unit.
			* With the car not inserted on boot: no errors reported
		+ What happens when system is running and card is inserted?
			* With the card not present at boot, no errors are reported and the automount trap is created. On the first card insert, the device is correctly identified and mounted
			* Performing the above, and then un-inserting and re-inserting shows the drive is not recognized again and is not re-mounted
			* Interesting: unlike the systemd.mount rule, if the drive is mounted (via the fstab entry) and then unmounted (via the umount command), re-requesting access to the file location does not re-mount the drive. Why?
	- 2) test just udev rule
		+ What happens on startup with card inserted/not?
			* With card inserted, lsblk shows that the block memory exists and also that an automount trap was created. Correctly mounts and allows access when requested.
			* Starting with drive uninserted performs as expected. journalctl does not show any anomalies and lsblk shows as expected.
		+ What happens when system is running and card is inserted?
			* With the system started, inserting the card triggers the automount trap. Correctly mounts and allows access when requested.
			* Additionally, if manually unmounted (through the umount command on CLI) and then access (to that mount point) is requested again, it will re-mount and function appropriately.
			* Performing the same steps above when card is not inserted on boot has the same results.
	- 3) test with both fstab and udev
		+ What happens on startup with card inserted/not?
			* Card present at boot seems to function similar to just the fstab entry
			* ERROR: Card not present at boot does not mount under any conditions (initial or repeated). This is at least in conflict to using just an fstab entry which would catch the first plug, but not subsequent.
			* ERROR: Card present at boot does not handle multiple insert/removes with the fstab entry as wrote.
		+ Is this a systemd thing? Maybe try updating the fstab entry to use systemd.mount instead (with the udev rule) and see if it plays nice then. I’m wondering if it’s not some “order of importance” thing.
	- 4) updated fstab entry
		+ Try using x-systemd-automount in the fstab entry. This should also create the automount entry (like the udev rule).
			* Changed the options to “nofail,x-systemd.automount,x-systemd.mount-timeout=1s,umask=000”
		+ TBD ONLY the modified fstab entry
			* with drive present at startup
	- operates like the normal fstab entry, however because an automount unit is generated, it is not mounted until accessed, as expected.
	- Confirmed, then, that this too functions similar to the udev rule, where manually un-mounting and then re-requesting the directory causes the drive to be re-mounted
	- Confirmed, surprisingly then too, this persists across remove/plug events and will re-mount the device when its re-accessed after a removal.
			* Testing with drive absent at startup results in the same behavior
* Test program
	- Confirmed working
	- Make a test program to have a listbox of all the files on the uSD card. For some additional hints, look at how the xml file is currently being referenced/loaded in PyDash. Should be able to do the exact same thing.
	- Test program should indicate if the uSD card is plugged in (via the DET pin on a GPIO) and then also list out the files on the card.
	- Use this as a functional HW test to see how the DET pin works with a py program (and interrupts) and then use that for the final PyDash program.

## Fonts
### Version Changes
This section contains the various changes needed to implement custom fonts
* verified freetype installed
* verified Fontconfig installed
* Added a fonts folder in the root FS overlay
	- Made (/root/fonts)
	- This will be the spot that fontconfig points to for the pydash fonts
* added fontconfig configuraiton file to the FS overlay
	- google says use a file at (<rootfs-overlay>/etc/fonts/local.conf)
	- found a similar file in (<buildroot>/output/target/etc/fonts/fonts.conf)
		+ that is the default config file and has some great guides/formats on how to configure. This should NOT be modified but is a good source for syntax
	- example local.conf for fontconfig:
		<?xml version="1.0"?>
		<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
		<fontconfig>
				<dir>/usr/share/fonts/custom</dir>
		</fontconfig>
	- the above tells Fontconfig to look for fonts in the location (/usr/share/fonts/custom)
	- Remember this corresponds in the buildroot environment to (<rootfs-overlay>/usr/share/fonts/custom)
	- changed <dir> in the above example to <dir>/root/py_dash_FS/fonts</dir> for the updated user FS
* added serveral font tff files I was able to find online
	- Verified OS recognizes them and works as intended in tkinter. See additional notes for other things I noted

### Additional Notes
This section doesn't necesarily include final changes but was more of a running tally of thigns I tried and was a point to keep notes on ongoing issues
* Remember that the different fonts like “open sans” vs “open sans – light” may have just “open sans” as their name in the information
	- This results in essentially 4 different instances of the “open sans” family in the available fonts list
	- Remember when uploading/adding new fonts that this could be an issue
* After uploading new fonts via the new fsoverlay and font package, tested out a tkinter window using a simple text label
	- Configuring label to different newly loaded fonts (like “bebas”) and it renders and works correctly. Huzzah.
* successfully picked out about about 20 different opensource fonts
	- load them into the /root/fonts/ overlay directory to use in the PyDash
	- Remember that any used here will also need to added to the computers users have the PyDash program on.
	- (complete) included a provision in the builder program to handle detecting if the appropriate fonts are installed

# Future Updates
Include any items below in the appropriate README.md file section
* Someday goal of supporting tunerstudio dash (TS Dash)
	- Right now, PyDash is basically locked into just using the same-named app.
	- Realistically though, the OS is just a linux kernel and so running TS dash shouldn't be an issue. Many raspberry pis already use this program already anyway.
	- Opening up to TS Dash would "unburden" the need for the PyDash builder, and app. Also it would open the dash to a much wider audience and probably would be good for it.
	- Could probably achieve this by using a separate build that launches TS dash on startup and then use a same/similar folder structure in the uSD card for TS to look for the config file at startup.
		+ unsure how navigating menus and pages would work with this but it has the pi GPIO integrated and I can't be the first person do do this.
		+ also unsure if TS dash will allow for configuring log paths, but that seems to be a pretty easy request and I'd expect it to be included natively.