# Build Yocto image with SWUpdate for RPi4 and install on the SD card


## Clean build directory 
```
shopt -s extglob
rm -rf !("downloads")
```

## Build Yocto image
```
mkdir yocto-rpi && cd yocto-rpi/
mkdir layers && cd layers

git clone git://git.yoctoproject.org/poky -b kirkstone
git clone https://github.com/openembedded/meta-openembedded -b kirkstone
git clone https://github.com/sbabic/meta-swupdate -b kirkstone
git clone https://github.com/agherzan/meta-raspberrypi -b kirkstone
# git clone https://github.com/sbabic/meta-swupdate-boards -b master
# git clone https://github.com/malyjak/meta-swupdate-boards -b kirkstone
# pushd meta-swupdate-boards && git checkout a3dc5d0 && popd
git clone https://github.com/ipitsyn/meta-swupdate-boards -b kirkstone

cd ..
. layers/poky/oe-init-build-env build

bitbake-layers add-layer ../layers/meta-openembedded/meta-oe
bitbake-layers add-layer ../layers/meta-openembedded/meta-python
bitbake-layers add-layer ../layers/meta-openembedded/meta-multimedia
bitbake-layers add-layer ../layers/meta-openembedded/meta-networking
bitbake-layers add-layer ../layers/meta-raspberrypi
bitbake-layers add-layer ../layers/meta-swupdate
bitbake-layers add-layer ../layers/meta-swupdate-boards


cat << EoF >> conf/local.conf

MONGOOSE_PORT = 8081
MACHINE = "raspberrypi4-64"
RPI_USE_U_BOOT = "1"
ENABLE_UART = "1"
IMAGE_FSTYPES += "ext4.gz wic"
PREFERRED_PROVIDER_u-boot-fw-utils = "libubootenv"
IMAGE_INSTALL:append = " swupdate u-boot-fw-utils rsync bind-utils tcpdump"

# Use systemd for system initialization
DISTRO_FEATURES:append = " systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED:append = " sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"
VIRTUAL-RUNTIME_login_manager = "shadow-base"
VIRTUAL-RUNTIME_dev_manager = "systemd"

# Remove psplash, it fails to start
IMAGE_FEATURES:remove = "splash"
EoF

bitbake update-image
```

## ~~Copy image to the SD card (don't use)~~
```
bzip2 -cd tmp/deploy/images/raspberrypi4-64/core-image-full-cmdline-raspberrypi4-64.wic.bz2 | sudo dd of=/dev/sda bs=1M status=progress conv=fsync
```


## Install on the SD card

### Mount WIC image
```
IMG=tmp/deploy/images/raspberrypi4-64/core-image-full-cmdline-raspberrypi4-64.wic
LOOP=/dev/loop9
sudo losetup -P ${LOOP} $IMG
sudo partprobe ${LOOP}
sudo mkdir -p /mnt/src/p1
sudo mkdir -p /mnt/src/p2
sudo mount ${LOOP}p1 /mnt/src/p1
sudo mount ${LOOP}p2 /mnt/src/p2
```

### Prepare an SD card
```
CARD=/dev/sda
sudo sfdisk $CARD << 'EoF'
1: start=8192,     size=100M, type=c, bootable
2:                 size=4G  , type=83
3:                 size=4G  , type=83
4: start=16990208           , type=83
EoF

sudo mkfs.vfat -v -F 32 -n BOOT -c ${CARD}1
sudo mkfs.ext4 -v ${CARD}2
sudo mkfs.ext4 -v -L media ${CARD}4
sudo mkdir -p /mnt/dst/p1
sudo mkdir -p /mnt/dst/p2
sudo mount ${CARD}1 /mnt/dst/p1
sudo mount ${CARD}2 /mnt/dst/p2
```

### Copy everything to SD card
```
sudo rsync -avP --numeric-ids /mnt/src/p1/ /mnt/dst/p1
sudo rsync -avP --numeric-ids /mnt/src/p2/ /mnt/dst/p2
sync
```

### Unmount and cleanup
```
sudo umount /mnt/src/p1
sudo umount /mnt/src/p2
sudo umount /mnt/dst/p1
sudo umount /mnt/dst/p2
sudo rm -rf /mnt/src
sudo rm -rf /mnt/dst
sudo losetup -d $LOOP
```