#!/bin/sh

# kill jekyll
pid=`pidof ruby1.9.1`
if [ -n "$pid" ]; then
    kill -9 $pid
fi
# startup jekyll
/usr/bin/jekyll serve --watch > /dev/null 2>&1 &
echo $!
