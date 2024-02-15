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
# '[text](link)' - Hyperlink/Anchor text
# TODO: 
# '1. ...'       - Numbered List
# '- ...'        - Bulleted List
# `...`          - Code snippet
# ```...```      - Code block

type
    MarkdownParser* = object
        src: string
        len: int
        pos: int

    TextFormat = enum
        Tag        = -1,
        None       =  0,
        Italic     =  1,
        Bold       =  2,
        BoldItalic =  3,
        Paragraph  =  4
        Heading    =  5,
        Heading2   =  6,
        Heading3   =  7,
        LinkText   =  8
        LinkRef    =  9

const special_chars = ['*', '#', '\\']
const void_elements = ["<area>", "<base>", "<br>", "<col>", "<command>", "<embed>", "<hr>", "<img>", "<input>", "<keygen>", "<link>", "<meta>", "<param>", "<source>", "<track>", "<wbr>"]

proc create_markdown_parser*(src: string): MarkdownParser =
    return MarkdownParser(src: src, len: src.len, pos: 0)

proc next(self: var MarkdownParser): char =
    if self.pos >= self.len:
        raise IndexDefect.newException("Error: Tried to read past end of text")
    else:
        let next = self.src[self.pos]
        inc self.pos
        return next

proc peek(self: MarkdownParser, offset: int = 0): char =
    if self.pos >= self.len:
        raise IndexDefect.newException("Error: Tried to read past end of text")
    return self.src[self.pos + offset]

proc is_at_end(self: var MarkdownParser): bool =
    return (if self.pos < self.src.len: false else: true)

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
    var format_stack: seq[TextFormat]
    var current_link_text: string
    var indent = ""
    var parsed_text: string
    var c: char
    while not self.is_at_end():
        c = self.next()
        case c:
            of '*':
                if format_stack.len == 0 or TextFormat.Paragraph notin format_stack and
                   self.peek(-2) == '\n':
                        echo "ngl i did add that shit"
                        format_stack.add(TextFormat.Paragraph)
                        parsed_text.add("<p>")
                # Separate so that we can either
                # prepend an opening or closing
                # tag in one case statement
                var tag_prefix = "<"

                var format = TextFormat.Italic

                # Determine what style to use based
                # on the number of asterisks
                if format_stack[^1] == TextFormat.Paragraph:
                    while self.peek() == '*':
                        inc format
                        if self.peek(2) != '*':
                            discard self.next()
                    format_stack.add(format)
                # If we're looking for a closing
                # asterisk, add the closing slash
                # to the tag
                else:
                    while self.peek() == '*':
                        discard self.next()
                    format = format_stack.pop()
                    tag_prefix.add('/')

                case format:
                    of TextFormat.Italic:     parsed_text.add(tag_prefix & "em>")
                    of TextFormat.Bold:       parsed_text.add(tag_prefix & "strong>")
                    of TextFormat.BoldItalic: parsed_text.add(tag_prefix & "em>" & tag_prefix & "strong>")
                    else: discard
            of '[':
                # Weird hack so that I can do my little [noindent]
                # tag on paragraphs I don't want to start with indents
                if self.src.substr(self.pos, self.pos + 7) == "noindent":
                    indent = "style=\"text-indent: 0px;\""
                    self.pos += 9
                    continue
                if format_stack.len > 0 and format_stack[^1] != TextFormat.LinkText:
                    var i = 0
                    while self.peek(i) != ']' and self.pos + i < self.len:
                        inc i
                    if self.peek(i + 1) == '(':
                        parsed_text.add("<a target=\"_blank\" href=\"")
                        format_stack.add(TextFormat.LinkText)
                else:
                    parsed_text.add(c)
            of ']', '(':
                if format_stack.len > 0:
                    if format_stack[^1] == TextFormat.LinkText:
                        discard format_stack.pop()
                        format_stack.add(TextFormat.LinkRef)
                        continue
                    elif format_stack[^1] == TextFormat.LinkRef:
                        continue
                parsed_text.add(c)
            of ')':
                if format_stack.len > 0 and format_stack[^1] == TextFormat.LinkRef:
                    parsed_text.add("\">" & current_link_text & "</a>")
                    current_link_text = ""
                    discard format_stack.pop()
                else:
                    parsed_text.add(c)
            of '#':
                format_stack.add(TextFormat.Heading)
                while self.peek() == '#':
                    inc format_stack[^1]
                    discard self.next()
                # Skip over space after '#'
                if self.peek() == ' ':
                    discard self.next()
                
                case format_stack[^1]:
                    of TextFormat.Heading:  parsed_text.add("<h1>")
                    of TextFormat.Heading2: parsed_text.add("<h2>")
                    of TextFormat.Heading3: parsed_text.add("<h3>")
                    else: discard
            of '\n':
                if format_stack.len > 0:
                    case format_stack[^1]:
                        of TextFormat.Paragraph: parsed_text.add("</p>\n")
                        of TextFormat.Heading:   parsed_text.add("</h1>\n")
                        of TextFormat.Heading2:  parsed_text.add("</h2>\n")
                        of TextFormat.Heading3:  parsed_text.add("</h3>\n")
                        else:                    parsed_text.add("\n")
                    indent = ""
                    # We know we're closing a top-level tag here
                    discard format_stack.pop()
            # Windows...
            of '\r': continue
            # Don't interfere with raw tags
            of '<':
                var tag = self.parse_tag()
                if format_stack.len > 0:
                    if format_stack[^1] != TextFormat.Tag and
                       remove_attributes(tag) notin void_elements:
                            format_stack.add(TextFormat.Tag)
                    elif format_stack[^1] == TextFormat.Tag and '/' in tag:
                        discard format_stack.pop()
                parsed_text.add(tag)
            # Escape special characters
            of '\\':
                if self.peek() in special_chars:
                    parsed_text.add(self.next()) 
            else:
                if format_stack.len > 0:
                    if format_stack[^1] == TextFormat.LinkText:
                        current_link_text.add(c)
                        continue
                    elif TextFormat.Paragraph in format_stack or
                         format_stack[^1] == TextFormat.Tag or
                         ord(format_stack[^1]) >= ord(TextFormat.Heading):
                            parsed_text.add(c)
                            continue
                else:
                    parsed_text.add("<p" & indent & ">" & c)
                    format_stack.add(TextFormat.Paragraph)
    # Add final closing paragraph tag
    if format_stack.len > 0 and format_stack[^1] == TextFormat.Paragraph:
        parsed_text.add("</p>")
    return parsed_text