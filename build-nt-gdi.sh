# Uses zig c headers to infer winapi symbols and types
# A hack for not linking to libc
zig_path=$(command which zig)
zig_dir=$(dirname ${zig_path})
zig build -Dlibc-path="${zig_dir}/lib/libc/include/any-windows-any" -Dtarget=i386-windows-gnu -Drelease-small=true
