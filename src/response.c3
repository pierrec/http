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

fn void! Response.parse(Response* resp, Socket sock, Request* req)
{
    Stream sock_stream = sock.as_stream();
    ByteWriter bw;
    bw.init();
    bw.read_from(&sock_stream)!;
    String str = bw.as_str();

    // Status line.
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.1.2
    String! proto = tokenize(str, '/');
    if (catch proto) return ResponseError.INVALID_PROTO?;
    resp.proto = proto;
    str = str[proto.len+1:];

    String! proto_major = tokenize(str, '.');
    if (catch proto_major) return ResponseError.INVALID_PROTO_MAJOR?;
    if (proto_major.len != 1) return ResponseError.INVALID_PROTO_MAJOR?;
    resp.proto_major = proto_major[0];
    str = str[proto_major.len+1:];

    String! proto_minor = tokenize(str, ' ');
    if (catch proto_minor) return ResponseError.INVALID_PROTO_MINOR?;
    if (proto_minor.len != 1) return ResponseError.INVALID_PROTO_MINOR?;
    resp.proto_minor = proto_minor[0];
    str = str[proto_minor.len+1:];

    String! code = tokenize(str, ' ');
    if (catch code) return ResponseError.INVALID_STATUS?;
    if (code.len != 3) return ResponseError.INVALID_STATUS?;
    if (!is_digit(code[0]) || !is_digit(code[1]) || !is_digit(code[2])) return ResponseError.INVALID_STATUS?;
    resp.status_code = (ushort)(code[0] - '0')*100 + (ushort)(code[1] - '0') + (ushort)(code[2] - '0');
    str = str[code.len+1:];

    String! status = tokenize(str, '\n');
    if (catch status) return ResponseError.INVALID_STATUSLINE?;
    resp.status = status;
    str = str[status.len+1:];

    resp.header.parse(str)!;

    // Body.
    resp.body = str;
}

fn String! tokenize(String str, char tok)
{
    foreach (i, c : str) if (c == tok) return str[:i];
    return ResponseError.PARSE_ERROR?;
}