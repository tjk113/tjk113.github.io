import strutils
import sequtils
import options
import times
import math
import os

import html_strings
import post

type
    PostModification = enum
        Added,
        Removed,
        Updated

    ModifiedPost = object
        post*: Post
        modification*: PostModification

# https://math.stackexchange.com/a/3056363
proc closest_multiple_to_n(multiple: int, n: int): int =
    if n mod multiple == 0:
       return n
    return ceilDiv(n, multiple) * multiple

proc get_num_posts(): int =
    return toSeq(walkDir("raw/", relative=true)).len

proc generate_post_html(post: Post, publish_date: string): string =
    # We have to pick and choose what we replace,
    # because otherwise the Github link will break
    var header = HEADER.replace("href=\"styles.css", "href=\"../styles.css")
                       .replace("href=\"index.html", "href=\"../index.html")
                       .replace("href=\"about.html", "href=\"../about.html")
                       .replace("href=\"things.html", "href=\"../things.html")
    var post_html = header & """    <a class="backButton" href="../index.html">< Back</a>
        <div class="post">
        <div class="title">""" & post.title & """</div>
        <div class="publishDate">""" & publish_date & """</div>
        <div class="snippet">""" & post.desc & """</div>
        <div class="body">
"""
    # Proper indentation
    for line in post.body.splitLines():
        post_html.add("            " & line & '\n')
    # Gotta make sure that raw HTML
    # no one's reading is pretty :D
    post_html.removeSuffix('\n')
    post_html.add("\n        </div>\n    </div>\n</body>\n</html>")
    
    return post_html

proc generate_thumbnail_html(post: Post, publish_date: string): string =
    var temp_publish_date = publish_date
    if post.publish_date.isSome:
        temp_publish_date = post.publish_date.get().format("M/dd/yyyy")
    return """
            <div class="thumbnail">
                <a href="posts/""" & post.filename & """.html"><div class="body">
                    <div class="title">""" & post.title & """</div>
                    <div class="publishDate">""" & temp_publish_date & """</div>
                    <div class="snippet">""" & post.desc & """</div>
                </div></a>
            </div>
"""

proc generate_homepage_html(publish_date: string): string =
    var homepage_html = HEADER & "    <div class=\"postList\">\n        <div class=\"row\">\n"
    let num_thumbnails = closest_multiple_to_n(3, get_num_posts())
    for i in 1..num_thumbnails:
        let post = create_post(i, true, true)
        if post.isSome:
            homepage_html.add(generate_thumbnail_html(post.get(), publish_date))
        # Properly align last row even if
        # the total number of posts is
        # not a multple of 3
        else:
            homepage_html.add("""
            <div class="thumbnail">
                <div class="blank"></div>
            </div>
""")
        # Post thumbnails are in rows of 3
        if i mod 3 == 0 and i != 0:
            homepage_html.add("        </div>\n")
            # Only open a new row if there
            # are more posts to fill it
            if i != num_thumbnails:
                homepage_html.add("        <div class=\"row\">\n")

    homepage_html.add("    </div>\n</body>\n</html>")
    return homepage_html

proc help() =
    echo """Commands:
h               - display this help menu
a <post_number> - add a post
r <post_number> - remove a post
u <post_number> - update a post
p               - publish changes
q               - quit
q!              - quit without confirmation
pq              - publish changes and quit"""

proc main() =
    var published = false
    var modified_posts: seq[ModifiedPost]
    while true:
        write(stdout, "> ")
        let input: seq[string] = readLine(stdin).split()
        # Meridiem will be uppercase by default
        let meridiem = now().format("tt").toLower()
        let publish_date = now().format("M/dd/yyyy h:mm") & meridiem
        case input[0]:
            of "h": help()
            of "q", "q!":
                # Support "q!" command
                if not published and modified_posts.len > 0 and input[0].len == 1:
                    write(stdout, "You have unpublished changes. Are you sure you want to exit? [y/n] ")
                    if readLine(stdin)[0] == 'n':
                        continue
                break
            of "a", "u", "r":
                let post_number = parseInt(input[1])

                var post: Option[Post]
                try:
                    post = create_post(post_number)
                except Defect as d:
                    echo d.msg
                    continue

                let modification = case input[0]:
                                       of "a": Added
                                       of "u": Updated
                                       else:   Removed
                modified_posts.add(ModifiedPost(post: post.get(), modification: modification))
            of "p", "pq":
                if modified_posts.len == 0:
                    echo "Nothing new to publish!"
                    continue

                for post in modified_posts:
                    if post.modification != Removed:
                        let post_obj = post.post
                        let file = open("posts/" & post_obj.filename & ".html", fmWrite)
                        file.write(generate_post_html(post_obj, publish_date))
                        file.close()

                var file = open("index.html", fmWrite)
                file.write(generate_homepage_html(publish_date))
                file.close()

                published = true

                # Support "pq" command
                if input[0] == "pq":
                    break

when isMainModule:
    main()