module http;
import std::io;
import std::collections::list;

// https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.2
struct HTTPResponse
{
    HTTPStatusCode status_code;
    String         status;
    String         proto;
    char           proto_major;
    char           proto_minor;
    HTTPHeader     header;
    isz            content_length;
    char[]         body;

    // Internal fields.
    Allocator* allocator;
    char[] bytes;
}

fault HTTPResponseError
{
    INVALID_PROTO,
    INVALID_PROTO_MAJOR,
    INVALID_PROTO_MINOR,
    INVALID_STATUS,
    INVALID_STATUSLINE,
    PARSE_ERROR,
}

/**
 * @require using != null "A valid allocator must be provided"
 **/
fn void HTTPResponse.init(HTTPResponse* resp, Allocator* using = mem::heap())
{
    *resp = { .allocator = using };
}

fn void! HTTPResponse.free(HTTPResponse* resp)
{
    resp.header.free();
    resp.allocator.free(resp.bytes.ptr)!;
}

fn usz! HTTPResponse.write_to(HTTPResponse* resp, Stream* out)
{
    if (!resp.status_code.is_valid()) return HTTPResponseError.INVALID_STATUS?;
    resp.status = resp.status_code.as_str();
    resp.proto = HTTP11;
    resp.proto_major = 1;
    resp.proto_minor = 1;

    // TODO date header
    resp.header.set("Date", "", true);

    DString msg;
    msg.tinit(resp.proto.len + 5 + resp.status.len + resp.header.size + 2);
    defer msg.free();
    msg.printf("%s %d %s\r\n", resp.proto, resp.status_code, resp.status);

    Stream msg_stream = msg.as_stream();
    usz written = resp.header.write_to(&msg_stream)!;

    written += out.write(msg.str())!;
    written += out.write(resp.body)!;

    return written;
}

fn void! HTTPResponse.parse(HTTPResponse* resp, Stream* from, HTTPRequest* req)
{
    resp.header.free();
    ByteWriter bw;
    bw.init(resp.allocator);
    bw.bytes = resp.bytes;
    bw.read_from(from)!;
    String str = bw.as_str();

    // Status line.
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.2
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-2.6
    switch
    {
        case str.starts_with(HTTP10):
            resp.proto = HTTP10;
            resp.proto_major = '1';
            resp.proto_minor = '0';
        case str.starts_with(HTTP11):
            resp.proto = HTTP11;
            resp.proto_major = '1';
            resp.proto_minor = '1';
        default:
            return HTTPResponseError.INVALID_PROTO?;
    }
    str = str[resp.proto.len:];
    if (str.len > 0 && str[0] != ' ') return HTTPResponseError.INVALID_PROTO?;
    str = str[1:];

    Cut c;
    c = cut(str, ' ');
    String code = c.before;
    if (code.len != 3) return HTTPResponseError.INVALID_STATUS?;
    if (!is_digit(code[0]) || !is_digit(code[1]) || !is_digit(code[2])) return HTTPResponseError.INVALID_STATUS?;
    resp.status_code = (ushort)(code[0] - '0')*100 + (ushort)(code[1] - '0')*10 + (ushort)(code[2] - '0');
    if (!resp.status_code.is_valid()) return HTTPResponseError.INVALID_STATUS?;
    str = c.after;

    usz! eol = str.index_of("\r\n");
    if (catch eol) return HTTPResponseError.INVALID_STATUSLINE?;
    resp.status = str[:eol];
    str = str[eol+2:];

    usz hn = resp.header.parse(str)!;
    resp.body = hn < str.len ? str[hn:] : "";
}