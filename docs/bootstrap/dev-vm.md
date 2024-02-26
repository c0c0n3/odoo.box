Dev VM Bootstrap
----------------
> Creating a test VM

We're going to build a node to host our Odoo stack. This base machine
packs a fully-fledged, one-node Odoo cluster—yea, that's a bit of an
oxymoron. This kind of setup is okay for devs, but obviously not suitable
for prod.


### Outcome

At the end of the procedure detailed below, you should end up with
a NixOS machine having

- All the services you'd expect in a full-blown Odoo installation.
  Namely: Nginx, Odoo, Postgres, module extensions, etc.
- No firewall. You can turn it on if you really want it, but most
  likely it's not needed for a dev box?
- An admin user named `admin` with a password of `abc123`. (You
  can change the password later.)
- Remote access through SSH.
- Basic Linux sys admin tools like `hwinfo`, `tcpdump`, etc. You
  can find the full list in our `cli-tools` Nix package. Plus, Bash
  completion and Emacs (built without X11 deps) as a default system
  editor.


### Hardware

Ideally, you have a box with at least 4 CPUs, 8GB of RAM and 50GB
SSD storage. But you can get away with just 2 CPUs, 4GB RAM and 20GB
storage. Surely you can use a VM with the same specs instead of bare
metal. In fact, that's what we do in the examples below where we use
Qemu to simulate a basic aarch64 server.

For an explanation of the Qemu commands we use below, have a read
through our [Qemu snippets][qemu-snippets]. There you'll also find
ways to customise those commands to e.g. run VMs at near native speed
depending on your host—e.g. MacOS on Apple silicon, MacOS on x86-64,
Linux on ARM64, etc.


### NixOS installation

After provisioning the hardware, you install our NixOS/Odoo stack.
At the moment we have a semi-automated procedure to do that:

1. Log onto the target machine.
2. Boot the NixOS ISO image.
3. Partition the disk.
4. Install a bare-bones NixOS.
5. Install our Odoo/NixOS stack.

We'll demo below how to do all this with the example Qemu VM.

Keep in mind we could automate all this so after provisioning the
box, all you'd have to do is run a single command which would take
care of steps (1) through (5) above. All we need to do is package
our Flake into [NixOS Anywhere][nixos-anywhere]. This would be a
life-saver for cloud deployments with dozens of machines, but for
now it's not really needed since we've got just a couple of boxes
to manage. So I'd rather not introduce yet another tool.


#### Booting the ISO image
Download the NixOS 23.11 image and boot it on the designated victim,
i.e. your target installation machine. How to do that exactly depends
on your hardware—have a look at the NixOS manual for the details. For
the sake of having a concrete example, we use Qemu—[our Nix shell][dev-env]
comes with the exact Qemu version we used.

First create a 50GB disk. For best performance, you should create a
raw disk like so

```bash
$ qemu-img create -f raw devm.img.raw 50G
```

Now make Qemu boot from the NixOS ISO image file

```bash
$ qemu-system-aarch64 \
    -machine virt,gic-version=3 -accel hvf -cpu host -smp 4 -m 8192M \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -cdrom nixos.iso \
    -drive file=devm.img.raw,format=raw \
    -nographic
```

Notice the above command starts a Qemu aarch64 machine and should work
even if your host isn't aarch64—e.g. you're on a MacOS Intel box.
Ideally though, your host should have more than 4 cores and 8GB of
RAM. If that's not the case, tweak the above `-smp` and `-m` params
according to your actual hardware resources.

Also notice the NixOS ISO is the aarch64 one. We've got to boot
in UEFI mode which is why we attach the OVMF firmware file, i.e.
`edk2-aarch64-code.fd`. You can find this file bundled with the Qemu
instance in our Nix shell, copy it out and change its perms so you
can both read and write it.

```bash
# the commands below will only work **after** you entered our Nix shell
$ ls -al $(dirname $(readlink $(which qemu-system-aarch64)))/../share/qemu | grep edk
$ cp $(dirname $(readlink $(which qemu-system-aarch64)))/../share/qemu/edk2-aarch64-code.fd .
$ chmod 0664 edk2-aarch64-code.fd
```

Make yourself root before running the commands in the sections below.

```bash
$ sudo -i
```

#### Partitioning
Partition your storage with one bootable ext4 partition of at least
30GB to host the OS. Again, how to do that exactly depends on your
hardware—have a look at the NixOS manual for the details.

In our running example, we partition our storage using a GPT scheme
with one bootable partition and a root partition spanning the entire
drive to host the whole OS. You can always add disks later which you
can use for cloud storage.

Anyway, on with our Qemu example.

```bash
$ lsblk                              # should list /dev/vdb

$ parted -a optimal /dev/vdb -- mklabel gpt

$ parted -a optimal /dev/vdb -- mkpart ESP fat32 0% 512MiB
$ parted -a optimal /dev/vdb -- set 1 esp on
$ parted -a optimal /dev/vdb -- name 1 boot

$ parted -a optimal /dev/vdb -- mkpart primary ext4 512MiB 30GiB
$ parted -a optimal /dev/vdb -- name 2 nixos
```

#### Formatting

Now format the boot partition with FAT and the root partition with
ext4.

```bash
$ mkfs.fat -F 32 -n boot /dev/vdb1
$ mkfs.ext4 -L nixos /dev/vdb2
```

#### Mounting
Mount the `nixos` disk on `/mnt` and the `boot` one on `/mnt/boot`.

```bash
$ mount /dev/disk/by-label/nixos /mnt
$ mkdir -p /mnt/boot
$ mount /dev/disk/by-label/boot /mnt/boot
```

#### Installing a bare-bones NixOS
Generate NixOS's initial config

```bash
$ nixos-generate-config --root /mnt
```

Then tweak the generated config

```bash
$ nano /mnt/etc/nixos/configuration.nix
```

```nix
boot.loader.systemd-boot.enable = true;       # double-check it's enabled
boot.loader.efi.canTouchEfiVariables = true;  # double-check it's enabled
networking.hostName = "devm";                 # pick a hostname
time.timeZone = "Europe/Amsterdam";           # set your time zone

# make root able to access this box thru SSH. We only need it for the
# first Flake install since there's no sudoer at the moment. Later we
# can disable root access.
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "yes";
```

Finally do the actual install, enter the root password when prompted
and then power off the box.

```bash
$ nixos-install
#  <enter root password>
$ poweroff
```

Also, after rebooting run

```bash
$ nix-collect-garbage -d
```

to get rid of unused packages in the Nix store and save disk space.



### Running the VM

Create a convenience start script to run the VM. Put the content
below in a `start.sh` file and make it executable.

```bash
#!/usr/bin/env bash

port_fwd='hostfwd=tcp::22-:22,'
port_fwd+='hostfwd=tcp::80-:80,'
port_fwd+='hostfwd=tcp::5432-:5432'

qemu-system-aarch64 \
    -machine virt,gic-version=3 -smp 4 -m 8G -cpu host -accel hvf \
    -drive if=pflash,format=raw,file=edk2-aarch64-code.fd \
    -drive file=devm.img.raw,format=raw,if=virtio \
    -nic user,model=virtio-net-pci,${port_fwd} \
    -nographic
```




[dev-env]: ../dev-env.md
[nixos-anywhere]: https://github.com/numtide/nixos-anywhere
[qemu-snippets]: ../qemu.md
