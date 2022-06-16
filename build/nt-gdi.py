#!/usr/bin/env python3

# todo: Versions older than Windows 2000 might be runnable too, all the way to Win 95 / NT 3.1, but testing is needed

import subprocess, os

# Uses zig C headers to infer winapi symbols and types
# A hack for not linking to libc
zig_path = subprocess.run(["which", "zig"], capture_output=True, check=True)
zig_dir = os.path.dirname(str(zig_path.stdout, encoding="utf8"))
zig_libc_path = f"{zig_dir}/lib/libc/include/any-windows-any"
zig_libc_path = "C:\\env\\tools\\zig-windows-x86_64-0.10.0-dev.555+1b6a1e691\\lib\\libc\\include\\any-windows-any"
subprocess.run(["zig", "build", f"-Dlibc-path={zig_libc_path}", "-Dtarget=i386-windows.nt4...win10-gnu", "-Drelease-small=true"], check=True)

# Produced executable is not runnable by old NT versions, as PE header is still populated with version 6, which is XP
with open("./../zig-out/bin/smol-pong-zig.exe", "r+b") as f:
  content = bytearray(f.read())
  content[0xb8] = 0x5 # Fix Major OS Version
  content[0xc0] = 0x5 # Fix Major SubSystem Version
  f.seek(0)
  f.write(content)
  f.truncate()

# todo: Call UPX if available
