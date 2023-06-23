module http::dial;
import std::collections::list;
import std::io;
import std::net;
import libc;

def Socket = NativeSocket;

fault DialError
{
    ADDRINFO,
    SOCKET,
    CONNECT,
}

fault SocketError
{
    WRITE,
    READ,
}

fn Socket! dial(String host, String port)
{
    ZString zhost = host.zstr_tcopy();
    ZString zport = port.zstr_tcopy();
    AddrInfo hints = { .ai_family = net::os::AF_INET, .ai_socktype = net::SOCK_STREAM };
    AddrInfo* res;
    int errcode = os::getaddrinfo(zhost, zport, &hints, &res);
    if (errcode != 0) return DialError.ADDRINFO?;
    defer os::freeaddrinfo(res);

    while (res)
    {
        NativeSocket sockfd = os::socket(res.ai_family, res.ai_socktype, res.ai_protocol);
        if (sockfd > 0)
        {
            errcode = os::connect(sockfd, res.ai_addr, res.ai_addrlen);
            if (errcode != 0) return DialError.CONNECT?;
            return sockfd;
        }
        res = res.ai_next;
    }
    return DialError.SOCKET?;
}

// Make Socket comply with the io::Stream interface.

fn io::Stream Socket.as_stream(Socket* s)
{
    return { .fns = &socket_interface, .data = s };
}

fn usz! Socket.read(Socket* s, char[] bytes)
{
    isz n = libc::read(*s, bytes.ptr, bytes.len);
    if (n < 0) return SocketError.READ?;
    return (usz)n;
}

fn usz! Socket.write(Socket* s, char[] bytes)
{
    isz n = libc::write(*s, bytes.ptr, bytes.len);
    if (n < 0) return SocketError.WRITE?;
    return (usz)n;
}

StreamInterface socket_interface = {
    .read_fn = fn(s, char[] bytes) => ((Socket*)s.data).read(bytes) @inline,
    .write_fn = fn(s, char[] bytes) => ((Socket*)s.data).write(bytes) @inline,
};