/* This is a generated file, don't edit */

#define NUM_APPLETS 10
#define KNOWN_APPNAME_OFFSETS 0

const char applet_names[] ALIGN1 = ""
"cat" "\0"
"findfs" "\0"
"hush" "\0"
"losetup" "\0"
"mkdir" "\0"
"modprobe" "\0"
"mount" "\0"
"sh" "\0"
"sleep" "\0"
"switch_root" "\0"
;

#define APPLET_NO_cat 0
#define APPLET_NO_findfs 1
#define APPLET_NO_hush 2
#define APPLET_NO_losetup 3
#define APPLET_NO_mkdir 4
#define APPLET_NO_modprobe 5
#define APPLET_NO_mount 6
#define APPLET_NO_sh 7
#define APPLET_NO_sleep 8
#define APPLET_NO_switch_root 9

#ifndef SKIP_applet_main
int (*const applet_main[])(int argc, char **argv) = {
cat_main,
findfs_main,
hush_main,
losetup_main,
mkdir_main,
modprobe_main,
mount_main,
hush_main,
sleep_main,
switch_root_main,
};
#endif

