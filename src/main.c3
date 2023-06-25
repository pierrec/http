module http;
import std::io;
//import std::net;
//import libc;

fn int main(String[] args)
{
    //do_client();
    do_server();
    return 0;
}

fn void do_client()
{
    HTTPClient client;
    HTTPRequest req = {
        .method = GET,
        .url = { .host = "www.example.com:80", .path = "/" },
        .proto = "HTTP",
        .proto_major = 1,
        .proto_minor = 1,
    };
    HTTPResponse resp;
    resp.init();
    client.do_request(&req, &resp)!!;
    //io::printn(resp.status);
    io::printn(resp.body);
}

fn void do_server()
{
    HTTPServer server;
    server.init("localhost:8081", 10000000)!!;
    server.serve(&handler)!!;
}

fn void handler(HTTPRequest* req, HTTPResponse* resp)
{
    resp.status_code = 200;
    resp.body = "Hello world";
}