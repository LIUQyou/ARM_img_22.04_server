set -e -x

INSTALL_ISO=ubuntu-22.04-live-server-arm64.iso
DISK_IMG=disk-22.04.4-live-server-arm64.img
DISK_SIZE=8G
RAM=8G
CPUS=4

cp configs/autoinstall.yaml configs/user-data
touch configs/meta-data
touch configs/vendor-data

mkdir -p iso
sudo mount $INSTALL_ISO iso

python3 -m http.server -d configs 3003 &
SERVER_PID=$!

qemu-img create disk.img $DISK_SIZE

sudo qemu-system-aarch64 \
    -machine virt \
    -nographic -vnc :1 \
    -cpu cortex-a57 \
    -smp ${CPUS} \
    -m ${RAM} \
    -no-reboot \
    -drive file=disk.img,format=raw \
    -cdrom $INSTALL_ISO \
    -kernel iso/casper/vmlinuz \
    -initrd iso/casper/initrd \
    -drive file=flash0.img,format=raw,if=pflash -drive file=flash1.img,format=raw,if=pflash \
    -append 'autoinstall ds=nocloud-net;s=http://_gateway:3003/'

echo "Ubuntu installed on disk image"

## Cleanup everything
kill "$SERVER_PID"

sudo umount iso
rm -r configs/user-data \
    configs/meta-data \
    configs/vendor-data

# Move the final ready to use disk image to the workload folder
mv disk.img workload/$DISK_IMG
