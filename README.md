This module provides HTTP client and server implementations.

Add the following to lib/std/net/os/posix.c3
```
extern fn CInt bind(NativeSocket socket, SockAddrPtr address, Socklen_t address_len) @extern("bind");
extern fn CInt listen(NativeSocket socket, CInt backlog) @extern("listen");
extern fn NativeSocket accept(NativeSocket socket, SockAddrPtr address, Socklen_t* address_len) @extern("accept");
```