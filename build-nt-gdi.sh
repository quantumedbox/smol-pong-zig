# Uses zig c headers to infer winapi symbols and types
zig_path=$(command which zig)
zig_dir=$(dirname ${zig_path})
zig build -Dlibc-path="${zig_dir}/lib/libc/include/any-windows-any" -Drelease-small=true -Dtarget=i386-windows-gnu
