module http;
import std::io;
import std::collections::list;

// https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.2
struct Response
{
    ushort status_code;
    String status;
    String proto;
    char   proto_major;
    char   proto_minor;
    Header header;
    isz    content_length;
    char[] body;
}

fault ResponseError
{
    INVALID_PROTO,
    INVALID_PROTO_MAJOR,
    INVALID_PROTO_MINOR,
    INVALID_STATUS,
    INVALID_STATUSLINE,
    PARSE_ERROR,
}

fn void! Response.parse(Response* resp, Stream* from, Request* req)
{
    ByteWriter bw;
    bw.init();
    bw.read_from(from)!;
    String str = bw.as_str();
    Cut c;

    // Status line.
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.2
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-2.6
    const HTTP10 = "HTTP/1.0 ";
    const HTTP11 = "HTTP/1.1 ";
    switch
    {
    case str.starts_with(HTTP10):
        resp.proto = HTTP10[:HTTP10.len - 1];
        resp.proto_major = '1';
        resp.proto_minor = '0';
        str = str[HTTP10.len:];
    case str.starts_with(HTTP11):
        resp.proto = HTTP11[:HTTP11.len - 1];
        resp.proto_major = '1';
        resp.proto_minor = '1';
        str = str[HTTP11.len:];
    default:
        return ResponseError.INVALID_PROTO?;
    }

    c = cut(str, ' ');
    String code = c.before;
    if (code.len != 3) return ResponseError.INVALID_STATUS?;
    if (!is_digit(code[0]) || !is_digit(code[1]) || !is_digit(code[2])) return ResponseError.INVALID_STATUS?;
    resp.status_code = (ushort)(code[0] - '0')*100 + (ushort)(code[1] - '0') + (ushort)(code[2] - '0');
    str = c.after;

    usz! eol = str.index_of("\r\n");
    if (catch eol) return ResponseError.INVALID_STATUSLINE?;
    resp.status = str[:eol];
    str = str[eol+2:];

    resp.header.parse(str)!;

    // Body.
    resp.body = str;
}