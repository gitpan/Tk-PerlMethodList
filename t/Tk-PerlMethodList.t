# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-MethodList.t'


use Test::More tests => 3;
use_ok ('Tk');
require_ok('Tk::PerlMethodList') ;



use strict;
use warnings;
my $mw = tkinit();
my $w;
eval{$w = $mw->PerlMethodList};
ok( !$@,"instance creation: $@");
