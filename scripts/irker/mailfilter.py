#!/usr/bin/python

import email
import json
import socket
import sys
import re
from urllib2 import urlopen, Request, URLError, HTTPError, HTTPRedirectHandler, build_opener
from urllib import urlencode, quote
from urlparse import urlparse
import textwrap

targets = ['irc://chat.freenode.net/#fink']

bold = "\x02"
green = "\x0303"
yellow = "\x0307"
clear = "\x0F"
red = "\x0305"
blue = "\x0302"

def request(url, parameters=None, username_pass=None, post_data=None):
    # build url + parameters
    if parameters:
        url_params = '%s?%s' % (url, urlencode(parameters))
    else:
        url_params = url

    # if username and pass supplied, build basic auth header
    headers = {}
    if username_pass:
        headers['Authorization'] = 'Basic %s' % base64.b64encode('%s:%s' % username_pass)

    # send request
    try:
        req = Request(url_params, headers=headers)
        if post_data:
            req.add_data(post_data)
        return urlopen(req)
    except URLError, e:
        raise ShortyError(e)

def githubshrink(bigurl):
    gitio_pattern = 'http(s)?://((gist|raw|develop(er)?)\.)?github\.com'
    gitio_re = re.compile(gitio_pattern)
    if not gitio_re.search(bigurl):
        raise ShortyError('URL must match %s' % gitio_pattern)
    resp = request('http://git.io', post_data="url=%s" % bigurl)
    for header in resp.info().headers:
        if header.startswith("Location:"):
            return header[10:].strip('\n\r')
    raise ShortyError('Failed to shrink url')

incoming = email.message_from_file(sys.stdin)

if incoming.is_multipart():
    payload = incoming.get_payload(0).get_payload(decode=True)
else:
    payload = incoming.get_payload(decode=True)

bodylines = payload.split("\n")
subj = incoming.get("Subject")

userparts = incoming.get("From").split("@", 1)
theuser = userparts[0].split("<", 1)

msgs = []
foundcommit = 0
foundmsg = 0
foundfiles = 0
filescount = 0
filestr = ""
dirs = []
firstpass = 1
filescount = 0
dircount = 0

if subj.startswith("[cvs] "):
    filestr = subj.lstrip("[cvs] ")
    parts = filestr.split(" ")
    for part in parts:
	subparts = part.split(",")
        for subpart in subparts:
            if re.match("^([0-9.]+|NONE)$", subpart):
                continue
            elif re.search("\/", subpart):
                dir = subpart
                dircount = dircount + 1
            else:
                file = subpart
                filescount = filescount + 1
    dirstr = "dir"
    if dircount > 1:
        dirstr = "dirs"
    if filescount > 1:
        filestr = "(%d files in %d %s)" % (filescount, dircount, dirstr)
    else:
        filestr = "%s %s" % (dir, file)
    msg = "%s%s%s: %s" % (green, theuser[1], clear, filestr)
    msgs.append(msg)
    for line in bodylines:
        line = line.strip()
	if foundmsg == 1:
            if line == "":
                foundmsg = 0
                break
            msg = "    %s" % (line)
            msgs.append(msg)
        elif line.startswith("Log Message:"):
            foundmsg = 1
else:
    tree = subj.lstrip("[").split("]", 1)
    tree = tree[0]
    for line in bodylines:
        line = line.strip()
        if line.startswith("Branch:"):
            fullbranch = line.lstrip("Branch: ").split("/")
            continue
        elif foundfiles == 1:
            if line == "":
                foundfiles = 0
                filescount = 0
                dirs = []
                continue
            pathparts = line.split("/")
            pathparts.pop()
            dirs.append("%s/" % ("/".join(pathparts)[2:]))
            filescount = filescount + 1
            if filescount == 1:
                filestr = line[2:]
            else:
                dircount = len(set(dirs))
                dirstr = "dir"
                if dircount > 1:
                    dirstr = "dirs"
                filestr = "(%d files in %d %s)" % (filescount, dircount, dirstr)
        elif foundcommit == 1 or foundmsg == 2:
            if foundcommit == 1:
                commiturl = githubshrink(line)
                foundcommit = 0 
            if foundmsg == 2 and line == "":
            	foundmsg = 0
                firstpass = 1
		continue
            elif foundmsg == 2:
		if firstpass == 1:
                    msgs.append("%s%s%s (%s%s%s): %s%s%s * %s%s%s / %s: %s%s%s" % (bold, tree, clear, yellow, fullbranch[len(fullbranch) - 1], clear, green, theuser[1], clear, red, commitsum, clear, filestr, blue, commiturl, clear))
                    firstpass = 0
                newlines = textwrap.fill(line).split("\n")
                linecount = 0
                for newline in newlines:
                    if (linecount >= 2):
                        linestr = "line"
                        if len(newlines) - linecount > 1:
                            linestr = "lines"
                        msgs.append("    (%s%s more %s%s)" % (white, len(newlines) - linecount, linestr, clear))
                        break
                    else:
               	        msgs.append("    %s" % (newline))
                    linecount = linecount + 1
        elif foundmsg == 1:
            foundmsg = 2
        elif line.startswith("Commit:"):
            commitsum = line.lstrip("Commit: ")
            commitsum = commitsum[:6]
            foundcommit =1 
        elif line.startswith("Log Message:"):
            foundmsg = 1
        elif line.startswith("Changed paths:"):
            foundfiles = 1

irkermsgs = []
for msg in msgs:
#    print "%s\n" % (msg)
    irkermsgs.append(json.dumps({ "to" : targets, "privmsg" : msg}))

for irkermsg in irkermsgs:
    socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(irkermsg + "\n", ("localhost", 6659))
