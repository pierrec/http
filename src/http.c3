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