# smol-pong-zig
Sort of spiritual port of [smol-pong repo](https://github.com/g3rwy/smol-pong)

Goal is to create minimalistic pong implementations fined-tuned to particular targets, so that its size would be (hopefully) minimal

## Building
For convenience `build` directory has scripts that make orchestrations of tooling needed for producing binaries, caveat is that you need to have `python3`

## Implemented targets
### nt-gdi
Win32 with GDI
Tested on Win10 and Windows 2000, but theoretically should run on any Windows version with Win32, starting from Windows 95 and NT 3.1

* Microsoft Defender and many anti-viruses detect produced executable as malicious, you have to make exception for it, if you dare to run it
```
   text    data     bss     dec     hex filename
   4588       0       0    4588    11ec ./zig-out/bin/smol-pong-zig.exe
```
![smol-pong-zig running on windows 2000 in qemu](/demo/windows2000.png)

* Section sizes are provided by `size` cli util
