module http;
import std::collections::list;
import std::io;

def StringList = List<String>;

// https://www.rfc-editor.org/rfc/rfc7230.html#section-2.1
struct HTTPHeader
{
     HTTPHeaderList fields;
     usz size;
}

def HTTPHeaderList = List<HTTPHeaderField>;

struct HTTPHeaderField
{
    String name;
    StringList values;
}

fault HeaderError
{
    INVALID_HEADERFIELD,
}

fn void HTTPHeader.free(HTTPHeader* h)
{
    foreach (&field : h.fields) field.values.free();
    h.fields.free();
}

fn StringList HTTPHeader.get(HTTPHeader *h, String name)
{
    if (canonicalize(name)) foreach (&field : h.fields) if (field.name == name) return field.values;
    return {};
}

fn void HTTPHeader.set(HTTPHeader *h, String name, String value, bool replace = false)
{
    if (!canonicalize(name)) return;
    if (value.len == 0) return;
    foreach (&field : h.fields)
    {
        if (field.name == name)
        {
            if (replace) field.values.clear();
            h.size += (field.values.len() == 0 ? 0 : 1) + value.len;
            field.values.append(value);
            return;
        }
    }
    // Keep track of the space occupied by this new field.
    // Add the name and value lengths plus the ':' field separator
    // and the terminating newline (CRLF).
    h.size += name.len + 1 + value.len + 2;
    HTTPHeaderField field = { .name = name };
    field.values.append(value);
    h.fields.append(field);
}

fn void HTTPHeader.del(HTTPHeader *h, String name)
{
    if (!canonicalize(name)) return;
    foreach (i, &field : h.fields)
    {
        if (field.name == name)
        {
            // No need to keep an accurate count of the header size.
            h.size -= name.len;
            field.values.free();
            h.fields.remove_at(i);
            return;
        }
    }
}

fn usz! HTTPHeader.write_to(HTTPHeader* h, Stream* out)
{
    char[4] buf = { ':', ' ', '\r', '\n' };
    char[] colon = buf[0:1];
    char[] space = buf[1:1];
    char[] crlf = buf[2:2];
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2
    usz n;
    foreach(field : h.fields)
    {
        n += out.write(field.name)!;
        n += out.write(colon)!;
        foreach (i, value : field.values.array_view())
        {
            if (i > 0) n += out.write(space)!;
            n += out.write(value)!;
        }
        out.write(crlf)!;
    }
    // End of fields.
    n += out.write(crlf)!;
    return n;
}

// Header fields.
// https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.4
fn usz! HTTPHeader.parse(HTTPHeader *h, String str)
{
    usz hn;
    while (true)
    {
        usz! eol = str.index_of("\r\n");
        if (catch eol) return HeaderError.INVALID_HEADERFIELD?;
        hn += eol + 2;
        String line = str[:eol];
        if (line.len == 0) return hn;
        str = str[eol+2:];
        // Field name.
        Cut cut_field = cut(line, ':');
        String name = cut_field.before;
        if (name.len == 0 || name[name.len-1] == ' ') return HeaderError.INVALID_HEADERFIELD?;
        line = cut_field.after;
        // Field values.
        while (true)
        {
            line = line.trim();
            Cut cut_value = cut(line, ' ');
            if (cut_value.before.len == 0)
            {
                h.set(name, line);
                break;
            }
            h.set(name, cut_value.before);
            line = cut_value.after;
        }
    }
}

/*
 * canonicalize the input and returns whether the canonicalization was successful.
 * It fails if s contains any invalid character.
 * See https://www.rfc-editor.org/rfc/rfc7230.html#appendix-B
 * tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." /
       "^" / "_" / "`" / "|" / "~" / DIGIT / ALPHA
 * Canonicalization converts the input as follow:
 * accept-encodING => Accept-Encoding
 */
fn bool canonicalize(String s)
{
    bool with_hyphen = true;
    foreach (&c : s)
    {
        char cc = *c;
        if (!is_alpha(cc) &&
            !is_digit(cc) &&
            !string::char_in_set(cc, "!#$%&'*+-.^_`|~")) return false;
        switch
        {
            case with_hyphen && 'a' <= cc && cc <= 'z': *c = cc - 'a' + 'A';
            case !with_hyphen && 'A' <= cc && cc <= 'Z': *c = cc - 'A' + 'a';
        }
        with_hyphen = cc == '-';
    }
    return true;
}

fn bool is_digit(char c) => '0' <= c && c <= '9';
fn bool is_alpha(char c) => ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z');