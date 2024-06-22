import std/strformat
import strutils

# World's simplest, most incomplete Markdown parser
# (with just enough HTML in there...)
# Supported syntax:
# '**...**'      - Bold
# '*...*'        - Italic
# '***...***'    - BoldItalic
# '# ...'         - Heading
# '## ...'        - Heading2
# '### ...'       - Heading3
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
        Tag        = -1
        None       =  0
        Italic     =  1
        Bold       =  2
        BoldItalic =  3
        Paragraph  =  4
        Heading    =  5
        Heading2   =  6
        Heading3   =  7
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
        block outer:
            c = self.next()
            case c:
                of '*':
                    if format_stack.len == 0 or TextFormat.Paragraph notin format_stack and
                    self.peek(-2) == '\n':
                            format_stack.add(TextFormat.Paragraph)
                            parsed_text.add("<p>")
                    # Separate so that we can either
                    # prepend an opening or closing
                    # tag in one case statement
                    var tag_prefix = "<"

                    var format = TextFormat.Italic

                    # Determine what style to use based
                    # on the number of asterisks
                    if ord(format_stack[^1]) >= ord(TextFormat.Paragraph) and
                    ord(format_stack[^1]) < ord(TextFormat.LinkRef):
                        while not self.is_at_end() and self.peek() == '*':
                            inc format
                            discard self.next()
                        format_stack.add(format)
                    # If we're looking for a closing
                    # asterisk, add the closing slash
                    # to the tag
                    else:
                        while not self.is_at_end() and self.peek() == '*':
                            discard self.next()
                        format = format_stack.pop()
                        tag_prefix.add('/')

                    case format:
                        of TextFormat.Italic:     parsed_text.add(tag_prefix & "em>")
                        of TextFormat.Bold:       parsed_text.add(tag_prefix & "strong>")
                        of TextFormat.BoldItalic: parsed_text.add(tag_prefix & "em>" & tag_prefix & "strong>")
                        else: discard
                of '[':
                    if (format_stack.len > 0 and format_stack[^1] != TextFormat.LinkText) or
                        format_stack.len == 0:
                        var i = 0
                        while self.peek(i) != ']' and self.pos + i < self.len:
                            inc i
                        if self.peek(i + 1) == '(':
                            parsed_text.add("<a target=\"_blank\" href=\"")
                            # If we're just coming out of another tag,
                            # we need to intuit what tag we're in
                            if format_stack.len == 0:
                                # Handle Links in headers
                                if self.peek(-2) == '#':
                                    format_stack.add(TextFormat.Paragraph)
                                else:
                                    format_stack.add(TextFormat.Paragraph)
                            format_stack.add(TextFormat.LinkText)
                    else:
                        parsed_text.add(c)
                of ']':
                    if format_stack.len > 0 and format_stack[^1] == TextFormat.LinkText:
                        discard format_stack.pop()
                        format_stack.add(TextFormat.LinkRef)
                        continue
                    parsed_text.add(c)
                of '(':
                    if format_stack[^1] == TextFormat.LinkRef and self.peek(-2) == ']':
                        continue
                    parsed_text.add(c)
                of ')':
                    if format_stack.len > 0 and format_stack[^1] == TextFormat.LinkRef and
                       self.peek() != ')':
                        parsed_text.add("\">" & current_link_text & "</a>")
                        current_link_text = ""
                        discard format_stack.pop()
                    else:
                        parsed_text.add(c)
                of '#':
                    # It's only a header if it's
                    # at the start of a line!
                    let whitespace = [' ', '\n', '\r', '\t']
                    var i = -2
                    while self.pos + i > 0 and self.peek(i) != '\n':
                        if self.peek(i) notin whitespace:
                            parsed_text.add("#")
                            break outer
                        dec i

                    format_stack.add(TextFormat.Heading)
                    while not self.is_at_end() and self.peek() == '#':
                        inc format_stack[^1]
                        discard self.next()
                    # Skip over space after '#'
                    if self.peek() == ' ':
                        discard self.next()

                    case format_stack[^1]:
                        of TextFormat.Heading:  parsed_text.add("<h1># ")
                        of TextFormat.Heading2: parsed_text.add("<h2>## ")
                        of TextFormat.Heading3: parsed_text.add("<h3>### ")
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
                        else:
                            var in_tag = false
                            for format in format_stack:
                                if ord(format) >= ord(TextFormat.Paragraph):
                                    in_tag = true
                            if in_tag or format_stack[^1] == TextFormat.Tag:
                                parsed_text.add(c)
                                continue
                    else:
                        parsed_text.add("<p" & indent & ">" & c)
                        format_stack.add(TextFormat.Paragraph)
    # Add final closing paragraph tag
    if format_stack.len > 0 and format_stack[^1] == TextFormat.Paragraph:
        parsed_text.add("</p>")
    return parsed_text