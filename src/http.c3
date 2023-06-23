module http;

enum Method : char (String name)
{
    GET     ("GET"),
    HEAD    ("HEAD"),
    POST    ("POST"),
    PUT     ("PUT"),
    DELETE  ("DELETE"),
    CONNECT ("CONNECT"),
    OPTIONS ("OPTIONS"),
    TRACE   ("TRACE"),
    PATCH   ("PATCH"),
}

struct Cut
{
    String before;
    String after;
}

fn Cut cut(String str, char tok)
{
    foreach (i, cc : str) if (cc == tok) return { str[:i], str[i+1:] };
    return {};
}