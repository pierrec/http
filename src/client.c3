module http;
import std::io;
import std::net;

struct Client
{
    CookieJar jar;
}

struct CookieJar
{
    String todo;
}

fn Response! Client.do_request(Client* c, Request* req)
{
    Socket sock = dial::dial(TCP, req.url.host, req.url.port)!;
    Stream sock_stream = sock.as_stream();

    req.header.del("Host");
    req.header.set("Host", req.url.host);
    req.write_to(&sock_stream)!;

    Response resp;
    resp.parse(&sock_stream, req)!;

    return resp;
}