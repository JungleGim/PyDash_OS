#!/bin/sh

######-----------------root OS changes----------------------
target_fs=${TARGET_DIR}						#/Home/buildroot/buildroot-2023.11/output/images/rpi-firmware
xorg_profile_filepath="$target_fs"'/etc/profile'		#xorg profile
xinitrc_filepath="$target_fs"'/etc/X11/xinit/xinitrc'		#xinitrc
sys_config_filepath="$target_fs"'/etc/systemd/system.conf'	#system config
usr_config_filepath="$target_fs"'/etc/systemd/user.conf'	#user config

#####update xinitrc
pattern1='xclock -geometry'
sed -i '\|^#|b;\|'"$pattern1"'|d' "$xinitrc_filepath"

old_exec='exec xterm -geometry 80x66+0+0 -name login'
#new_exec='exec python /PyDash/PyDash.pyc -geometry +0+0'		#compiled python prog
new_exec='exec python /PyDash/PyDash.py -geometry +0+0'		     	#non-compiled python prog
sed -i '\|^#|b;s|'"$old_exec"'|'"$new_exec"'|' "$xinitrc_filepath"

pattern3='xterm -geometry'
sed -i '\|^#|b;\|^exec|b;\|'"$pattern3"'|d' "$xinitrc_filepath"

#add in provisions to prevent screensaver/blanking
search_txt1='exec python'
new_txt1='xset s off -dpms'
if grep -q "$new_txt1" "$xinitrc_filepath"; then
	true
else
	sed -i '\|^#|b;\|'"$search_txt1"'|i \
'"$new_txt1" "$xinitrc_filepath"
fi

#####update xorg_profile
new_txt='exec startx -- -nocursor'		#server option for no-cursor (normal)
#new_txt='exec startx'				#debug (shows cursor)
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

#####update user.conf
old_timeout='#DefaultTimeoutStopSec=90s'
new_timeout='#DefaultTimeoutStopSec=5s'
sed -i 's|'"$old_timeout"'|'"$new_timeout"'|' "$usr_config_filepath"
