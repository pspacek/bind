#!/bin/sh
#
# Copyright (C) 2014  Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

status=0
n=0

rm -f dig.out.*

DIGOPTS="+tcp +noadd +nosea +nostat +nocmd -p 5300"

echo "I:checking DNSSEC SERVFAIL is cached ($n)"
ret=0
$DIG $DIGOPTS +dnssec foo.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
$RNDC -c ../common/rndc.conf -s 10.53.0.5 -p 9953 dumpdb -all 2>&1 | sed 's/^/I:ns5 /'
for i in 1 2 3 4 5 6 7 8 9 10; do
    awk '/Zone/{out=0} { if (out) print } /SERVFAIL/{out=1}' ns5/named_dump.db > sfcache.$n
    [ -s "sfcache.$n" ] && break
    sleep 1
done
grep "^; foo.example/A" sfcache.$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking SERVFAIL is returned from cache ($n)"
ret=0
$DIG $DIGOPTS +dnssec foo.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
grep "SERVFAIL" dig.out.ns5.test$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking that +cd bypasses cache check ($n)"
ret=0
$DIG $DIGOPTS +dnssec +cd foo.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
grep "SERVFAIL" dig.out.ns5.test$n > /dev/null && ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:disabling server to force non-dnssec SERVFAIL"
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 stop 2>&1 | sed 's/^/I:ns2 /'

awk '/SERVFAIL/ { next; out=1 } /Zone/ { out=0 } { if (out) print }' ns5/named_dump.db
echo "I:checking SERVFAIL is cached ($n)"
ret=0
$DIG $DIGOPTS bar.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
$RNDC -c ../common/rndc.conf -s 10.53.0.5 -p 9953 dumpdb -all 2>&1 | sed 's/^/I:ns5 /'
for i in 1 2 3 4 5 6 7 8 9 10; do
    awk '/Zone/{out=0} { if (out) print } /SERVFAIL/{out=1}' ns5/named_dump.db > sfcache.$n
    [ -s "sfcache.$n" ] && break
    sleep 1
done
grep "^; bar.example/A" sfcache.$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking SERVFAIL is returned from cache ($n)"
ret=0
$DIG $DIGOPTS bar.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
grep "SERVFAIL" dig.out.ns5.test$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking with +cd query ($n)"
ret=0
$DIG $DIGOPTS +cd bar.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
grep "SERVFAIL" dig.out.ns5.test$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking with +dnssec query ($n)"
ret=0
$DIG $DIGOPTS +cd bar.example. a @10.53.0.5 > dig.out.ns5.test$n || ret=1
grep "SERVFAIL" dig.out.ns5.test$n > /dev/null || ret=1
n=`expr $n + 1`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:exit status: $status"
exit $status