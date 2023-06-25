module http;
import std::io;

struct HTTPServer
{
    Listener listener;
}

def HTTPHandler = fn void (HTTPRequest* req, HTTPResponse* resp);

fn void! HTTPServer.init(HTTPServer* srv, String address, int backlog)
{
    Cut host_port = cut(address, ':');
    String host = host_port.before.len == 0 ? address : host_port.before;
    String port = host_port.before.len == 0 ? "80" : host_port.after;
    srv.listener.init(TCP, host, port, backlog)!;
}

fn void! HTTPServer.serve(HTTPServer* srv, HTTPHandler handler)
{
    while (true)
    {
        Socket client_sock = srv.listener.accept()!;
        if (catch err = serve_client(client_sock, handler)) {};
    }
}

fn void! serve_client(Socket sock, HTTPHandler handler)
{
    defer sock.close()!!;
    Stream sock_stream = sock.as_stream();

    ByteWriter bw;
    bw.init();
    bw.read_from(&sock_stream)!;
    String str = bw.as_str();

    HTTPRequest req;
    defer req.free();
    req.parse(str)!;

    HTTPResponse resp;
    resp.init();
    defer resp.free()!!;
    handler(&req, &resp);
    resp.write_to(&sock_stream)!;
}