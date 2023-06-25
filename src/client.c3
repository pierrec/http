module http;
import std::encoding;
import std::io;
import std::net;

struct HTTPClient
{
    CookieJar jar;
}

struct CookieJar
{
    String todo;
}

struct Cookie
{
    String name;
    String value;
}

fn void! HTTPClient.do_request(HTTPClient* c, HTTPRequest* req, HTTPResponse* resp)
{
    // TODO handle redirects.
    Cut host_port = cut(req.url.host, ':');
    String host = host_port.before.len == 0 ? req.url.host : host_port.before;
    String port = host_port.before.len == 0 ? "80" : host_port.after;

    Socket sock = dial::dial(TCP, host, port)!;
    Stream sock_stream = sock.as_stream();

    // Prepare the header.
    req.header.set("Host", req.url.host, true);

    // The client does not support persistent connections.
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-6.1
    req.header.set("Connection", "close", true);

    const AUTH_HEADER = "Authorization";
    bool with_auth;
    if (with_auth)
    {
        StringList auth = req.header.get(AUTH_HEADER);
        if (auth.len() == 0)
        {
            const PREFIX = "Basic ";
            String creds = string::tprintf("%s:%s", req.url.user, req.url.password);

            Base64Encoder enc;
            enc.init(base64::URL_ALPHABET)!;
            usz enc_len = enc.encode_len(creds.len);

            ByteWriter bw;
            bw.tinit();
            bw.ensure_capacity(PREFIX.len + enc_len)!;
            bw.write(PREFIX)!;
            usz n = enc.encode(creds, bw.bytes[bw.index:])!;
            bw.bytes = bw.bytes[:bw.index+n];

            req.header.set(AUTH_HEADER, bw.as_str());
            with_auth = true;
        }
    }
    // Only delete the authorization header if it was set by the client.
    defer if (with_auth) req.header.del(AUTH_HEADER);

    req.write_to(&sock_stream)!;

    resp.parse(&sock_stream, req)!;
}