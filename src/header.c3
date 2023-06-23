module http;
import std::collections::list;

def StringList = List<String>;

// https://www.rfc-editor.org/rfc/rfc7230.html#section-2.1
struct Header
{
     HeaderList fields;
     usz size;
}

def HeaderList = List<HeaderField>;

struct HeaderField
{
    String name;
    StringList values;
}

fault HeaderError
{
    INVALID_HEADERFIELD,
}

fn void Header.set(Header *h, String name, String value)
{
    if (!canonicalize(name)) return;
    if (value.len == 0) return;
    foreach (&field : h.fields)
    {
        if (field.name == name)
        {
            h.size += (field.values.len() == 0 ? 0 : 1) + value.len;
            field.values.append(value);
            return;
        }
    }
    // Keep track of the space occupied by this new field.
    // Add the name and value lengths plus the ':' field separator
    // and the terminating newline (CRLF).
    h.size += name.len + 1 + value.len + 2;
    HeaderField field = { .name = name };
    field.values.append(value);
    h.fields.append(field);
}

fn void Header.del(Header *h, String name)
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

fn void Header.append_to(Header *h, DString* out)
{
    out.reserve(h.size);
    // https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2
    foreach(field : h.fields)
    {
        out.append_chars(field.name);
        out.append_char(':');
        foreach (i, value : field.values.array_view())
        {
            if (i > 0) out.append_char(' ');
            out.append_chars(value);
        }
        out.append_chars("\r\n");
    }
    // End of fields.
    out.append_chars("\r\n");
}

// Header fields.
// https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.4
fn void! Header.parse(Header *h, String str)
{
    while (true)
    {
        String line = tokenize(str, '\n')!;
        if (line.len == 1 && line[0] == '\r') break;
        str = str[line.len+1:];
        // Field name.
        String name = tokenize(line, ':')!;
        if (name.len == 0 || name[name.len-1] == ' ') return HeaderError.INVALID_HEADERFIELD?;
        line = line[name.len+1:];
        // Field values.
        while (true)
        {
            line = line.trim();
            String! value = tokenize(line, ' ');
            if (catch value)
            {
                h.set(name, line);
                break;
            }
            h.set(name, value);
            line = line[value.len+1:];
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
