module http;
import std::io;

// https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.1
struct Request
{
    Method method;
    Url    url;
    String proto;
    char   proto_major;
    char   proto_minor;
    Header header;
    // TODO Body body;
}

fn usz! Request.write_to(Request* req, Stream* out)
{
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.1
    DString msg;
    msg.tinit(req.method.name.len + req.url.path.len + req.header.size + 8);
    defer msg.free();
    msg.printf("%s %s %s/%d.%d\r\n", req.method.name, req.url.path, req.proto, req.proto_major, req.proto_minor);

    Stream msg_stream = msg.as_stream();
    req.header.write_to(&msg_stream)!;

    return out.write(msg.str())!;
}