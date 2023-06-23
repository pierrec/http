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
    Socket sock = dial::dial(req.url.host, req.url.port)!;

    req.header.del("Host");
    req.header.set("Host", req.url.host);

    DString msg;
    msg.tinit(64 + req.header.size);
    defer msg.free();

    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.1
    msg.printf("%s %s %s/%d.%d\r\n", req.method.name, req.url.path, req.proto, req.proto_major, req.proto_minor);
    req.header.append_to(&msg);

    sock.write(msg.str())!;

    Response resp;
    resp.parse(sock, req)!;

    return resp;
}