# smol-pong-zig
Sort of spiritual port of [smol-pong repo](https://github.com/g3rwy/smol-pong)

Goal is to create minimalistic pong implementations fined-tuned to particular targets, so that its size would be (hopefully) minimal

## Implemented targets
### nt-gdi
Win32 with GDI
Tested on Win10, but theoretically should run on any NT version
```
   text    data     bss     dec     hex filename
   6594       0       0    6594    19c2 ./zig-out/bin/smol-pong-zig.exe
```
