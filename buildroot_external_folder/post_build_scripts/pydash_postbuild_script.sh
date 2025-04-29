#!/bin/sh

######-----------------py specific changes----------------------
#/Home/buildroot/buildroot-2023.11/output/images/rpi-firmware
rpi_firmware="${BINARIES_DIR}/rpi-firmware"
#config.txt
config_filepath="$rpi_firmware"'/config.txt'
#cmdline.txt
cmdline_filepath="$rpi_firmware"'/cmdline.txt'

#####update config.txt
#add spi overlay
search_spi='#dtparam=spi=on'
uncomment_spi='dtparam=spi=on'
new_spi='\
#enable SPI\
dtparam=spi=on'
if grep -q "$search_spi" "$config_filepath"; then
	sed -i 's|'"$search_spi"'|'"$uncomment_spi"'|' "$config_filepath"
else
	sed -i '$a\'"$new_spi" "$config_filepath"
fi

#add can overlay to the end of the file
search_can='dtoverlay=mcp2515'
new_can='\
#enable CANbus overlay\
dtoverlay=mcp2515-can0, oscillator=16000000,interrupt=12\
'
if grep -q "$search_can" "$config_filepath"; then
	true
else
	sed -i '$a\'"$new_can" "$config_filepath"
fi

######-----------------root OS changes----------------------
#/Home/buildroot/buildroot-2023.11/output/images/rpi-firmware
target_fs=${TARGET_DIR}
#xorg profile
xorg_profile_filepath="$target_fs"'/etc/profile'
#xinitrc
xinitrc_filepath="$target_fs"'/etc/X11/xinit/xinitrc'
#system config
sys_config_filepath="$target_fs"'/etc/systemd/system.conf'

#!TODO: Enable silent login

#####update xinitrc
pattern1='xclock -geometry'
sed -i '\|^#|b;\|'"$pattern1"'|d' "$xinitrc_filepath"

old_exec='exec xterm -geometry 80x66+0+0 -name login'
new_exec='exec python /root/py_dash/py_dash.py -geometry +0+0'
sed -i '\|^#|b;s|'"$old_exec"'|'"$new_exec"'|' "$xinitrc_filepath"

pattern3='xterm -geometry'
sed -i '\|^#|b;\|^exec|b;\|'"$pattern3"'|d' "$xinitrc_filepath"

#####update xorg_profile
new_txt='exec startx'
search_txt='done'
if grep -q "$new_txt" "$xorg_profile_filepath"; then
	true
else
	sed -i '\|^#|b;\|'"$search_txt"'|i \
'"$new_txt" "$xorg_profile_filepath"
fi

#####update system.conf
old_timeout='#DefaultTimeoutStopSec=90s'
new_timeout='#DefaultTimeoutStopSec=5s'
sed -i 's|'"$old_timeout"'|'"$new_timeout"'|' "$sys_config_filepath"
