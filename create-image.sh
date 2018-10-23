#!/bin/bash

set -e

cd ~/

# Delete any old builds
if [ -d ~/custom-image ]; then
  sudo rm -Rf ~/custom-image;
fi

mkdir ~/custom-image
cd ~/custom-image
sudo apt-get update -y
sudo apt-get install -y unzip squashfs-tools aria2 genisoimage tlsdate

sudo timedatectl --adjust-system-clock set-local-rtc true
sudo timedatectl set-ntp true
sudo tlsdate -s -H mail.google.com
sudo timedatectl set-local-rtc false
timedatectl

# aria2c --seed-time=0 --summary-interval=3 http://releases.ubuntu.com/16.04.5/ubuntu-16.04.5-server-amd64.iso.torrent
aria2c -x 16 -s 16 -k 4M -o ubuntu-16.04.5-server-amd64.iso http://releases.ubuntu.com/16.04.5/ubuntu-16.04.5-server-amd64.iso

mkdir mnt
sudo mount -o loop ~/custom-image/ubuntu*.iso mnt
mkdir extract
sudo rsync --exclude=/install/filesystem.squashfs -a mnt/ extract
sudo unsquashfs mnt/install/filesystem.squashfs
sudo mv squashfs-root edit

# Make sure the DNS is working properly otherwise, the installation might fail.
sudo bash -c "cat > ~/custom-image/edit/etc/resolv.conf" <<EOL
nameserver 1.1.1.1
EOL

# Copy SSH .pub key
sudo mkdir -p ~/custom-image/edit/root/.ssh
sudo mkdir -p ~/custom-image/edit/home/ubuntu/.ssh
sudo cp ~/id_rsa.pub ~/custom-image/edit/home/ubuntu/.ssh/authorized_keys
sudo chmod 0644 ~/custom-image/edit/home/ubuntu/.ssh/authorized_keys
# sudo cp ~/id_rsa ~/custom-image/edit/home/ubuntu/.ssh/id_rsa
# sudo chmod 0600 ~/custom-image/edit/home/ubuntu/.ssh/id_rsa

sudo mkdir -p ~/custom-image/edit/var/lib/postgresql/.ssh
sudo cp ~/rsync.pub ~/custom-image/edit/var/lib/postgresql/.ssh/authorized_keys
sudo cp ~/rsync ~/custom-image/edit/var/lib/postgresql/.ssh/rsync
sudo bash -c "cat > ~/custom-image/edit/var/lib/postgresql/.ssh/config" <<EOL
Host *
  IdentityFile ~/.ssh/rsync
EOL
sudo chmod 0644 ~/custom-image/edit/var/lib/postgresql/.ssh/authorized_keys
sudo chmod 0644 ~/custom-image/edit/var/lib/postgresql/.ssh/config
sudo chmod 0600 ~/custom-image/edit/var/lib/postgresql/.ssh/rsync

# Copy Configuration Scripts
sudo cp ~/glances.conf ~/custom-image/edit/glances.conf
sudo cp ~/postgresql.conf ~/custom-image/edit/postgresql.conf
sudo cp ~/pg_hba.conf ~/custom-image/edit/pg_hba.conf
sudo cp ~/recovery.conf ~/custom-image/edit/recovery.conf


sudo mount --bind /dev/ edit/dev
sudo bash -c "cat > ~/custom-image/edit/usr/sbin/policy-rc.d" <<EOL
exit 101
#!/bin/sh
EOL

# Disable unnattended upgrades
sudo bash -c "cat >> ~/custom-image/edit/etc/apt/apt.conf.d/10periodic" <<EOL
APT::Periodic::Unattended-Upgrade "0";
EOL

sudo bash -c "cat > ~/custom-image/edit/etc/custom_tmpreaper.conf" <<EOL
SHOWWARNING=false
TMPREAPER_TIME=2d
TMPREAPER_PROTECT_EXTRA='/tmp/systemd*'
TMPREAPER_DIRS='/tmp/. /var/tmp/.'
TMPREAPER_DELAY='256'
TMPREAPER_ADDITIONALOPTIONS=''
EOL

sudo bash -c "cat >  ~/custom-image/edit/etc/systemd/system/glances.service" <<EOL
[Unit]
Description=Glances
After=network.target

[Service]
ExecStart=/usr/local/bin/glances -C /glances.conf -w --percpu -p 80 --fs-free-space --disable-check-update --hide-kernel-threads --time 1 
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

sudo bash -c "cat >  ~/custom-image/edit/etc/systemd/system/pg.service" <<EOL
[Unit]
Description=PostgreSQL database server
Documentation=man:postgres(1)

[Service]
Type=notify
User=postgres
ExecStart=/usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOL

sudo bash -c "cat > ~/custom-image/edit/etc/issue" <<EOL
//////////////////////////////////////   @@@@@
//////////////////////////////////////   @@@@@@@@
./////////////////////////////////////   @@@@@@@@@@
 .////////////////////////////////////   @@@@@@@@@@@@
   ///////////////////////////////////   @@@@@@@@@@@@%
     /////////////////////////////////   @@@@@@@@@@@@@
         .////////////////////////////   @@@@@@@@@@@@@
                                         @@@@@@@@@@@@@
                                         @@@@@@@@@@@@@
                                         @@@@@@@@@@@@@
                                         @@@@@@@@@@@@@
              %@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@%,
              .@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@/
               @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                @@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                   @@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                      @@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                                                             ,@@@@@@@@@@@@@@@@
                                                                @@@@@@@@@@@@@@@
                                                                 ,@@@@@@@@@@@@@
                                                                  @@@@@@@@@@@@@
                                                                  @@@@@@@@@@@@@
                                                                  @@@@@@@@@@@@@
                                                                 @@@@@@@@@@@@@@
                                                               @@@@@@@@@@@@@@@*
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*
                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@&
EOL

sudo bash -c "cat > ~/custom-image/edit/build.sh" <<EOL
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C
apt-get install -y dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
chmod +x /usr/sbin/policy-rc.d

# Install packages
apt-get update -y --fix-missing
apt-get dist-upgrade -y --fix-missing
apt-get install software-properties-common wget apt-transport-https git curl openssh-server libpam-systemd openssl python3 vim -y

# Enable Ubuntu repos
add-apt-repository main
add-apt-repository universe
add-apt-repository restricted
add-apt-repository multiverse
apt-get update -y --fix-missing

# Install pip
apt-get install -y python3-pip

# Install Glances
pip3 install 'glances[action,browser,cloud,cpuinfo,chart,folders,ip,raid,web]' 

# Install tmpreaper
apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y install tmpreaper
mv /etc/custom_tmpreaper.conf /etc/tmpreaper.conf

# Install PostgreSQL v11
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
apt-get update
apt-get install postgresql postgresql-contrib -y

# Setup directories
mv /recovery.conf /var/lib/postgresql/recovery.conf
mkdir -p /var/lib/postgresql/master_wal
chown -R postgres:postgres /var/lib/postgresql/

# Copy PostgreSQL config files
mkdir -p /etc/postgresql/11/main/
mv /postgresql.conf /etc/postgresql/11/main/postgresql.conf
mv /pg_hba.conf /etc/postgresql/11/main/pg_hba.conf
chown -R postgres:postgres /etc/postgresql/11
openssl dhparam -out /etc/ssl/dhparam.pem 2048

echo "session required pam_limits.so" >> /etc/pam.d/common-session

# Mask irqbalance to avoid problems associated with VMWare.
# This service usually only assists in 'bare metal' situations.
# See https://serverfault.com/questions/513807/is-there-still-a-use-for-irqbalance-on-modern-hardware
# https://unix.stackexchange.com/questions/264677/when-is-irqbalance-needed-in-a-linux-vm-under-vmware
systemctl mask irqbalance

systemctl daemon-reload
# Enable pg.service after cluster setup
# systemctl enable pg
systemctl enable glances

# Sysctl Settings
echo "vm.overcommit_memory=2" > /etc/sysctl.conf;

apt-get install --fix-missing
apt-get update -y --fix-missing
apt-get dist-upgrade -y --fix-missing

apt-get autoremove -y
apt-get autoclean -y

echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu-sudo ;

rm -rf /tmp/* ~/.bash_history
rm /sbin/initctl
rm /var/lib/dbus/machine-id
rm /usr/sbin/policy-rc.d
dpkg-divert --rename --remove /sbin/initctl
umount /proc || umount -lf /proc
umount /sys
until umount /dev/pts
do
  sleep 0.1
done
EOL

sudo chroot edit /bin/bash -e /build.sh

sudo rm ~/custom-image/edit/build.sh
cd ~/custom-image
until sudo umount edit/dev
do
  sleep 0.1
done

# sudo mkdir -p ~/custom-image/edit/etc/nginx
# sudo cp ~/nginx.conf ~/custom-image/edit/etc/nginx/nginx.conf

cd ~/custom-image
sudo chmod +w extract/install/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}n' | sudo tee extract/install/filesystem.manifest
sudo cp extract/install/filesystem.manifest extract/install/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract/install/filesystem.manifest-desktop
sudo sed -i '/install/d' extract/install/filesystem.manifest-desktop
sudo mksquashfs edit extract/install/filesystem.squashfs -b 1048576
printf $(sudo du -sx --block-size=1 edit | cut -f1) | sudo tee extract/install/filesystem.size

sudo bash -c "cat > ~/custom-image/extract/ks.cfg" <<EOL
lang en_US
langsupport en_US
keyboard us
mouse
timezone America/New_York
rootpw --disabled
user ubuntu --fullname "Admin" --password "ubuntu"
reboot
text
install
cdrom
auth  --useshadow --enablemd5
network --bootproto=dhcp --device=eth0
firewall --disabled
skipx
halt
%packages
EOL

sudo bash -c "cat > ~/custom-image/extract/ks.preseed" <<EOL

d-i partman-lvm/device_remove_lvm                 boolean true
d-i partman-md/device_remove_md                   boolean true

d-i grub-installer/bootdev string /dev/sda

d-i partman-auto/disk string /dev/sda
d-i partman/unmount_active boolean true

d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select boot-root

d-i partman-auto/expert_recipe string                         \
      boot-root ::                                            \
              512 512 512 ext4                                \
                      $defaultignore{ }                       \
                      method{ format }                        \
                      format{ }                               \
                      use_filesystem{ }                       \
                      filesystem{ ext4 }                      \
                      mountpoint{ /boot }                     \
              .                                               \
              100% 2048 100% linux-swap                       \
                      method{ swap } format{ }                \
              .                                               \
              1024 4096 -1 ext4                               \
                      method{ format } format{ }              \
                      use_filesystem{ } filesystem{ ext4 }    \
                      mountpoint{ / }                         \
              .                                               \

d-i     partman-partitioning/confirm_write_new_label boolean true
d-i     partman/choose_partition select finish
d-i     partman/confirm boolean true
d-i     partman/confirm_nooverwrite boolean true

d-i user-setup/allow-password-weak      boolean true
d-i preseed/late_command string \
in-target mkdir -p /etc/sudoers.d ; \
in-target echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu-sudo ; \
in-target dpkg --configure -a ; \
in-target chown -R ubuntu /home/ubuntu ; \
in-target sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config ; \
in-target rm -rf /var/lib/cloud/data ; \
in-target rm -rf /var/lib/cloud/instance ; \
in-target rm -rf /var/lib/cloud/instances/* ; \
in-target sed -i '/^deb cdrom/d' /etc/apt/sources.list ; \
in-target apt-get update ; \
in-target apt-get -y upgrade ; \
in-target apt-get -y dist-upgrade ; \
in-target apt-get -y autoremove ; \
in-target apt-get autoclean ; \
in-target apt-get clean ;
EOL

sudo bash -c "cat > ~/custom-image/extract/isolinux/isolinux.cfg" <<EOL
INCLUDE /isolinux/defaults.cfgs
prompt 0
TIMEOUT 5
default biblioinstall
menu background #99999999
menu color border 0 #ffffffff #ee000000 std
menu color title 0 #ffffffff #ee000000 std
menu color sel 0 #ffffffff #85000000 std
menu color unsel 0 #ffffffff #ee000000 std
menu color pwdheader 0 #ff000000 #99ffffff rev
menu color pwdborder 0 #ff000000 #99ffffff rev
menu color pwdentry 0 #ff000000 #99ffffff rev
menu color hotkey 0 #ff00ff00 #ee000000 std
menu color hotsel 0 #ffffffff #85000000 std
menu title Automatically Install PostgreSQL Server
label biblioinstall
  menu label ^Automatically Install PostgreSQL Server
  kernel /install/vmlinuz
  append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz quiet ks=cdrom:/ks.cfg preseed/file=/cdrom/ks.preseed --
EOL

cd extract
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt
sudo mkisofs -D -r -V "Installer" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ~/ubuntu-postgresql.iso .

cd ~/custom-image
until sudo umount mnt
do
  sleep 0.1
done

sudo chown ubuntu:ubuntu ~/ubuntu-postgresql.iso
chmod go-w ~
chmod 755 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
sudo service ssh restart