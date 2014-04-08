#!/bin/sh

# kill jekyll
pid=`pidof ruby1.9.1`
if [ -n "$pid" ]; then
    kill -9 $pid
fi
# startup jekyll
/usr/bin/jekyll serve --watch >> /tmp/jekyll.log 2>&1 &
echo $!
