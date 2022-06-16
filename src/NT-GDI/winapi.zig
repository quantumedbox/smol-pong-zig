pub usingnamespace @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cDefine("_WIN32_WINNT", "0x0500"); // Windows 2000 as minimum version
    @cDefine("WINVER", "0x0500"); // Windows 2000 as minimum version
    @cDefine("__MSABI_LONG(x)", "x"); // cImport doesn't recognize token parsing macro in _mingw_mac.h
    @cInclude("windows.h");
});
