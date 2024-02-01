import strutils

# World's simplest, most incomplete Markdown parser
# (with just enough HTML in there...)
# Supported syntax:
# '**...**'      - Bold
# '*...*'        - Italic
# '***...***'    - BoldItalic
# '# ..'         - Heading
# '## ..'        - Heading2
# '### ..'       - Heading3
# '1. ...'       - Numbered List
# '- ...'        - Bulleted List

type
    MarkdownParser* = object
        src: string
        len: int
        pos: int

    TextFormat = enum
        None       = 0,
        Italic     = 1,
        Bold       = 2,
        BoldItalic = 3,
        Paragraph  = 4
        Heading    = 5,
        Heading2   = 6,
        Heading3   = 7

const special_chars = ['*', '#', '\\']
const void_elements = ["<area>", "<base>", "<br>", "<col>", "<command>", "<embed>", "<hr>", "<img>", "<input>", "<keygen>", "<link>", "<meta>", "<param>", "<source>", "<track>", "<wbr>"]

proc create_markdown_parser*(src: string): MarkdownParser =
    return MarkdownParser(src: src, len: src.len, pos: 0)

proc next(self: var MarkdownParser): char =
    if self.pos >= self.len:
        raise IndexDefect.newException("Tried to read past end of text")
    else:
        let next = self.src[self.pos]
        inc self.pos
        return next

proc peek(self: MarkdownParser, offset: int = 0): char =
    if self.pos >= self.len:
        raise IndexDefect.newException("Tried to read past end of text")
    return self.src[self.pos + offset]

proc prev(self: var MarkdownParser): char =
    if self.pos - 1 < 0:
        raise IndexDefect.newException("Tried to read before beginning of text")
    else:
        dec self.pos
    return self.src[self.pos]

proc is_at_end(self: var MarkdownParser): bool =
    return (if self.pos < self.src.len - 1: false else: true)

proc parse_tag(self: var MarkdownParser): string =
    var tag: string
    tag.add(self.peek(-1))
    if self.peek().isAlphaAscii() or self.peek() == '/':
        while self.peek() != '>':
            tag.add(self.next())
    return tag & self.next()

proc remove_attributes(tag: string): string =
    let space_index = tag.find(' ')
    if space_index >= 0:
        return tag.substr(0, space_index - 1) & ">"
    return tag

proc parse*(self: var MarkdownParser): string =
    var looking_for = TextFormat.None
    var in_paragraph = false
    var in_raw_tag = false
    var parsed_text: string
    var c: char
    while not self.is_at_end():
        c = self.next()
        case c:
            of '*':
                if not in_paragraph and self.peek(-2) == '\n':
                    looking_for = TextFormat.Paragraph
                    in_paragraph = true
                    parsed_text.add("<p>")
                # Separate so that we can either
                # prepend an opening or closing
                # tag in one case statement
                var tag_prefix = "<"

                if looking_for == TextFormat.Paragraph:
                    looking_for = TextFormat.Italic
                    while self.peek() == '*':
                        inc looking_for
                        discard self.next()
                # If we're looking for a closing
                # symbol, add the closing slash
                # to the tag
                else:
                    tag_prefix.add('/')

                case looking_for:
                    of TextFormat.Italic:     parsed_text.add(tag_prefix & "em>")
                    of TextFormat.Bold:       parsed_text.add(tag_prefix & "strong>")
                    of TextFormat.BoldItalic: parsed_text.add(tag_prefix & "em>" & tag_prefix & "strong>")
                    else: discard
                # Couldn't think of a less
                # jank way to skip the
                # closing '*'s...
                if tag_prefix.len > 1:
                    # Skip over remaining '*'s
                    while self.peek() == '*':
                        discard self.next()
                    # Don't lose track of whether we're in a paragraph
                    looking_for = (if in_paragraph: TextFormat.Paragraph
                                   else:            TextFormat.None)
            of '#':
                looking_for = TextFormat.Heading
                while self.peek() == '#':
                    inc looking_for
                    discard self.next()
                # Skip over space after '#'
                discard self.next()

                case looking_for:
                    of TextFormat.Heading:  parsed_text.add("<h1>")
                    of TextFormat.Heading2: parsed_text.add("<h2>")
                    of TextFormat.Heading3: parsed_text.add("<h3>")
                    else: discard
            of '\n':
                case looking_for:
                    of TextFormat.Paragraph: parsed_text.add("</p>\n")
                    of TextFormat.Heading:   parsed_text.add("</h1>\n")
                    of TextFormat.Heading2:  parsed_text.add("</h2>\n")
                    of TextFormat.Heading3:  parsed_text.add("</h3>\n")
                    else:                    parsed_text.add("\n")
                # We know we're closing a top-level
                # tag, so we just reset these
                looking_for = TextFormat.None
                in_paragraph = false
            # Windows...
            of '\r': continue
            # Don't interfere with raw tags
            of '<':
                var tag = self.parse_tag()
                if not in_raw_tag and remove_attributes(tag) notin void_elements:
                    in_raw_tag = true
                if in_raw_tag and '/' in tag:
                    in_raw_tag = false
                parsed_text.add(tag)
            # Escape special characters
            of '\\':
                if self.peek() in special_chars:
                    parsed_text.add(self.next()) 
            else:
                if in_paragraph or in_raw_tag or ord(looking_for) >= ord(TextFormat.Heading):
                    parsed_text.add(c)
                else:
                    parsed_text.add("<p>" & c)
                    looking_for = TextFormat.Paragraph
                    in_paragraph = true
    # Add final closing paragraph tag
    if in_paragraph:
        parsed_text.add("</p>")
    return parsed_text