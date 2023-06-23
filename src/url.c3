module http;

struct Url
{
    String scheme;
    String host; // host or host:port
    String user;
    String password;
    String path;
    String query;
    String fragment;
}