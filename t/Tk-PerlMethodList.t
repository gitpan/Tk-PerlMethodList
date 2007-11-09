# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-MethodList.t'


use Test::More tests => 7;
use_ok ('Tk');
require_ok('Tk::PerlMethodList') ;



use strict;
use warnings;

my $mw = tkinit();
my $w;
eval{$w = $mw->PerlMethodList};
ok( !$@,"instance creation: $@");
$mw->update;
{
my $text   =  $w->{text};
my $font   =  $w->{font};

my $size   = $text->fontConfigure($font,'-size');
is($size, 12, 'fontsize');

my $family = $text->fontConfigure($font,'-family');
is($family, 'Courier', 'fontfamily'); 
}

$w->classname('Tk::PerlMethodList');
is ($w->cget('-classname'), 'Tk::PerlMethodList','classname set/get');

$w->show_methods;
$w->update;
{
my $text = $w->{text};
my $line = $text->get('1.0','1.60');
like($line, qr/Tk::PerlMethodList\s*_adjust_selection/,
     q/find displayed method '_adjust_selection'/);
}


