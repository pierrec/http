module http;

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