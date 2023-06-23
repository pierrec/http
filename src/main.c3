module http;
import std::io;
//import std::net;
//import libc;

fn int main(String[] args)
{
//    ZString host = "www.example.com";
//    ZString service = "80";
//    AddrInfo hints = { .ai_family = net::os::AF_INET, .ai_socktype = net::SOCK_STREAM };
//    AddrInfo* res;
//    int errcode = os::getaddrinfo(host, service, &hints, &res);
//    if (errcode != 0) return libc::os::errno();
//    defer net::os::freeaddrinfo(res);
//
//    NativeSocket sockfd = os::socket(res.ai_family, res.ai_socktype, res.ai_protocol);
//    if (sockfd < 0) return libc::os::errno();
//    defer sockfd.close()!!;
//    io::printfn("sockfd=%d, %d %d", sockfd, res.ai_addr, res.ai_addrlen);
//
//    errcode = net::os::connect(sockfd, res.ai_addr, res.ai_addrlen);
//    io::printf("connecting..");
//    if (errcode != 0) return libc::os::errno();
//    io::print("connected.");
//
//    char[] header = "GET /\n\n\nHTTP/1.1\r\n";
//    usz n = libc::write(sockfd, header, header.len);
//
//    char[2048] buf;
//    n = libc::read(sockfd, &buf, buf.len);
//    io::printfn("%s", buf[:n]);
    Client client;
    Request req = {
        .method = GET,
        .url = { .host = "www.example.com:80", .path = "/" },
        .proto = "HTTP",
        .proto_major = 1,
        .proto_minor = 1,
    };
    Response resp = client.do_request(&req)!!;
    //io::printn(resp.status);
    io::printn(resp.body);

	return 0;
}