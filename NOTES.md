# Notes

## Access Mac External Hard Drive in Linux

From: https://michael.mulqueen.me.uk/2018/03/reading-a-macos-harddisk-on-linux/

- Basic Mounting
  - Ensure you have hfsplus installed: sudo apt install hfsplus
  - Find the block device for the volume, you can list all connected disks by running sudo fdisk -l, you’re looking for the ones with the type Apple HFS/HFS+. For the purposes of this guide, we’ll assume it’s /dev/sdd2 (but yours could be completely different).
  - Make sure you have a mount point: sudo mkdir /media/myhfsdrive
  - Mount the device: sudo mount -t hfsplus /dev/sdd2 /media/myhfsdrive
- Use Bind Mount to Change Ownership
  - Ensure you have bindfs installed: sudo apt install bindfs
  - Make sure you’ve completed all of the basic mounting steps.
  - Make sure you have a mount point: sudo mkdir /media/myhfsdrive-mirrored
  - Make the bind mount: sudo bindfs --mirror=alice,bob /media/myhfsdrive /media/myhfsdrive-mirrored
- You will now have access to the drive in the new mount point
- Unmount drive
  - sudo umount /media/myhfsdrive-mirrored
  - sudo umount /media/myhfsdrive
