#!/bin/sh

# Override these variables in sourced script(s) located
# in /usr/lib/swupdate/conf.d or /etc/swupdate/conf.d
SWUPDATE_ARGS="-v ${SWUPDATE_EXTRA_ARGS}"
SWUPDATE_WEBSERVER_ARGS=""
SWUPDATE_SURICATTA_ARGS=""

# source all files from /etc/swupdate/conf.d and /usr/lib/swupdate/conf.d/
# A file found in /etc replaces the same file in /usr
for f in $( (test -d @LIBDIR@/swupdate/conf.d/ && ls -1 @LIBDIR@/swupdate/conf.d/; test -d /opt/swupdate/conf.d && ls -1 /opt/swupdate/conf.d) | sort -u); do
  if [ -f "/opt/swupdate/conf.d/$f" ]; then
    . /opt/swupdate/conf.d/$f
  else
    . /opt/swupdate/conf.d/$f
  fi
done

#  handle variable escaping in a simmple way. Use exec to forward open filedescriptors from systemd open.
if [ "$SWUPDATE_WEBSERVER_ARGS" != "" ] && [ "$SWUPDATE_SURICATTA_ARGS" != "" ]; then
  exec /usr/bin/swupdate $SWUPDATE_ARGS -w "$SWUPDATE_WEBSERVER_ARGS" -u "$SWUPDATE_SURICATTA_ARGS"
elif [ "$SWUPDATE_WEBSERVER_ARGS" != "" ]; then
  exec /usr/bin/swupdate $SWUPDATE_ARGS -w "$SWUPDATE_WEBSERVER_ARGS"
elif [ "$SWUPDATE_SURICATTA_ARGS" != "" ]; then
  exec /usr/bin/swupdate $SWUPDATE_ARGS -u "$SWUPDATE_SURICATTA_ARGS"
else
  exec /usr/bin/swupdate $SWUPDATE_ARGS
fi
