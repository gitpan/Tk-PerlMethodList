#! /usr/bin/perl

package Tk::PerlMethodList;
our $VERSION = 0.04;

use warnings;
use strict;
use Class::ISA;
#use Data::Dumper;
use File::Slurp qw /read_file/;
require Tk;
require Tk::LabEntry;
require Tk::ROText;
use Devel::Peek qw(CvGV);
our @ISA    = ('Tk::Toplevel');

=head1 NAME

Tk::PerlMethodList - query the Symbol-table for methods (subroutines) defined in a class (package) and its parents.

=head1 SYNOPSIS


require Tk::PerlMethodList;

my $instance = $main_window->PerlMethodList();

=head1 DESCRIPTION

The window contains entry fields for a classname and a regex. The list below displays the subroutine-names in the package(s) of the given classname and its parent classes. The list will contain the sub-names present in the the symbol-table. It will therefore display imported subs as well. For the same reason it will not show subs which can be - but have not yet been autoloaded. It will show declared subs though. In case of imported subs, the last field of the row contains the aliased sub as reported by DevelPeek::CvGV. The 'Filter' entry takes a regex to filter the returned List of sub/methodnames.

If the file containing a subroutine definition can be found in %INC, a green mark will be displayed at the beginning of the line. The sourcecode will be displayed by clicking on the subs list-entry.


Method list and source window have Control-plus and Control-minus bindings to change fontsize.

Tk::PerlMethodList is a Tk::Toplevel-derived widget.

=head1 METHODS

B<Tk::PerlMethodList> supports the following methods:

=over 4

=item B<classname(>'A::Class::Name'B<)>

Set the classname-entry to 'A::Class::Name'.

=item B<filter(>'a_regex'B<)>

Set the filter-entry to 'a_regex'.

=item B<show_methods()>

Build the list for classname and filter present in the entry-fields.

=back

=head1 OPTIONS

B<Tk::PerlMethodList> supports the following options:

=over 4

=item B<-classname>

$instance->configure(-classname =>'A::Class::Name')
Same as classname('A::Class::Name').

=item B<-filter>

$instance->configure(-filter =>'a_regex')
Same as filter('a_regex').


=back

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut


Tk::Widget->Construct('PerlMethodList');
unless (caller()) {
    _test_();
}

sub Populate{
    my ($self,@args) = @_;
    $self->SUPER::Populate(@args);
    my $frame    = $self -> Frame()->pack(-fill => 'x',
                                          -padx => 20,
                                          -pady => 4,
                                      );
    my $fr_left  = $frame-> Frame()->pack(-side => 'left',
                                          -fill => 'y');
    my $fr_right = $frame-> Frame(-relief      => 'sunken',
                                  -borderwidth => 2,
                              )->pack(-side => 'left',
                                      -padx => 10);

    my $fr_overr = $fr_left->Frame()->pack(-anchor => 'nw',
                                           -pady   => 1
                                       );
    my $fr_source= $fr_left->Frame()->pack(-anchor => 'nw',
                                           -pady   => 1,
                                       );
    $fr_overr->Label(-width => 1,
                     -bg    => 'orange')->pack(-side => 'left');
    $fr_overr->Label(-text  => 'overridden if called as a method',
                 )->pack(-side => 'left');
    $fr_source->Label(-width => 1,
                      -bg    => 'green')->pack(-side => 'left');
    $fr_source->Label(-text  => 'sourcecode can be displayed',
                 )->pack(-side => 'left');
    my @btn_data = (['Classname',\$self->{classname}],
                    ['Filter'   ,\($self->{filter}||='')]);

    @$self{qw/entry_cl entry_f/}= 
        map {my $e = $fr_right -> LabEntry(-label       => $_->[0],
					   -textvariable=> $_->[1],
					   -labelPack   => [-side=>'left'],
				       )->pack(-anchor => 'e');
	     $e->Subwidget('entry')->configure(-background => 'white');
	     $e;
         } @btn_data;


    my $btn   = $fr_right -> Button (-text   => 'show methods',
                                     -command=> sub{$self->show_methods}
                                 )->pack;
    my $text  = $self -> Scrolled('ROText',
                                  -wrap         => 'none',
                                  -insertontime => 0,
                              )->pack(-fill   => 'both',
                                      -expand => 1,
                                  );
    my $font  = $self -> fontCreate(-family => 'Courier',
                                    -size   => 10,
                                );
    $text->configure(-font=>$font);
    $text->tagConfigure('overridden',-background => 'orange');
    $text->tagConfigure('source_ok' ,-background => 'green');
    $text->tagConfigure('white'     ,-background => 'white');

    $text->menu(undef);         #disable

    $self -> Label(-textvariable=>\$self->{status})->pack;

    $text->bind('<Control-plus>',sub{$self->_change_fontsize(2)});
    $text->bind('<Control-minus>',sub{$self->_change_fontsize(-2)});
    $text->bind('<1>',sub{$self->_text_click});
    $text->bind('<Motion>',sub {$self->_adjust_selection});
    for my $w (@$self{qw/entry_cl entry_f/}) {
        $w->bind('<Return>',sub{$btn->Invoke});
    }
    $text->focus;

    @$self{qw/text font list/}= ($text,$font,[]);

    $self->ConfigSpecs(-background  => [$text,'','','white'],
                       -classname   => ['METHOD'],
                       -filter      => ['METHOD'],
                       DEFAULT      => ['SELF'],
                   );
    return $self;
}

sub _adjust_selection{
    my $self = shift;
    my $w = $self->{text};
    $w->unselectAll;
    $w->adjustSelect;
    $w->selectLine;
}

sub _change_fontsize{
    my $self = shift;
    my $delta = $_[0];
    my ($text,$font) = @$self{qw/text font/};
    my $size = $text->fontConfigure($font,'-size');
    $size += $delta;
    $size = ($size < 8) ? 8  : $size;
    $size = ($size > 14)? 14 : $size;
    $text->fontConfigure($font,'-size',$size);
}


sub _text_click{
    my $self = shift;
    my $w    = $self->{text};
    my $position = $w->index('current');
    my $line;
    if ($position =~ m/^(\d+)\./) {
        $line = $1;
    } else {
        return
    }
    my $idx  = $line - 1; #line range starts at 1
    my $file = '';
    for (qw/sourcepackage package/){
        $file = _convert_classname($self->{list}[$idx]{$_});
        last if $file;
    }
    my $methodname = $self->{list}[$idx]{sourcesymbol};
    my $re = qq/sub\\s+$methodname(\\W.*)?\$/;
    $self->_start_code_view($file,$re);
}

sub _get_methods{
    my $self = shift;
    my ($class_name) = @_;
    my $filter = $self->{filter};
    my $regex = qr/$filter/i ;
    #  print "g_m called for $class_name\n";
    my @function_list;
    my @classes=Class::ISA::self_and_super_path($class_name);
    my %overridden;
    foreach my $class (@classes) {
        no strict 'refs';
        my @list;
        my $s_t_r = \%{$class."::"};
        use strict ;
        foreach my $key ( keys %$s_t_r) {
            next unless ($key =~ $regex);
            my $var =  \ ( $s_t_r->{$key} );
            my $state;
            ref $var eq 'GLOB' && *{$var}{CODE}
                && ($state = 'declared')
                && defined &{*{$var}{CODE}} && ($state = 'defined');
            ref $var eq 'SCALAR' && $$var == -1 && ($state = 'declared');
            if ($state) {
                my $overridden = $overridden{$key} || 0;
                my $definition = '';
                $definition .= CvGV(*{$var}{CODE}).'' if $state eq 'defined';
                $overridden{$key} = 1;
                push @list , {symbol       => $key,
                              state        => $state,
                              package      => $class,
                              overridden   => $overridden,
                              defined_as   => $definition,
                          };
            }
        }
        @list = sort {lc $a->{symbol}cmp lc $b->{symbol}} @list;
        push @function_list,@list;
    }
    $self->{list} = \@function_list;
    return $self;
}

sub _grep_sources{
    my $self = shift;
    my $list = $self->{list};
    $self->_set_source_fields;
    my $last_filename = '';
    my $filename      = '';
    my $module_source = '';
    for my $element (@$list) {
        for (qw/sourcepackage package/){
            $filename = _convert_classname($element->{$_});
            last if $filename;
        }
        if ($filename && !($filename eq $last_filename)){
            $module_source = read_file($filename);
            $last_filename = $filename;
        }
        my $symbol = $element->{sourcesymbol};
        $element->{source_avail} =
            ($module_source =~/sub\s+$symbol(\W.*)?$/m)?
                1 : 0;
    }
    return $self;
}

sub _set_source_fields{
    my $self = shift;
    my $list = $self->{list};
    for my $element (@$list) {
        if ($element->{defined_as} =~ /\*(.*)::(.*)$/){
            $element->{sourcepackage} = $1;
            $element->{sourcesymbol}  = $2;
            $element->{defined_as} =~ s/^\*/alias to:  /;
        }
        my $defined_as = '';
        for (qw/package symbol/){
            $element->{"source$_"}||= $element->{$_};
            unless($element->{$_} eq $element->{"source$_"}){
                $defined_as = $element->{defined_as};
            }
        }
        $element->{defined_as} = $defined_as;
    }
}


sub show_methods{
    my $self = shift;
    my ($text,$classname) = @$self{qw/text classname/};
    $text->delete('1.0','end');
    $self->{indexmap} = [];
    if (! eval "require $classname") {
        $self->{list}= [];
        $self->{status}="Error: package '$classname' not found!";
        return;
    }
    $self->{status}="Showing methods for '$classname'";
    $self->_get_methods($classname)
         ->_grep_sources;
    my $list = $self->{list};
    my %max_width = ( symbol  => 0,
                       package => 0,
                  );
    for my $element (@$list) {
        map {my $length = length($element->{$_})+2;
             $max_width{$_} =  $length if $length > $max_width{$_};
         } qw/symbol package/;
    }
    for my $element (@$list) {
            my $line = sprintf('%-'.$max_width{package}.'s'
                               .'%-'.$max_width{symbol}.'s%-12s%-30s',
                               $element->{package},
                               $element->{symbol} ,
                               $element->{state},
                               $element->{defined_as})."\n";
            $text->insert('end', '  ',
                          $element->{overridden} ? 'overridden': 'white',# tag
                           '  ',
                          $element->{source_avail}? 'source_ok': 'white',# tag
                          $line, '');
    }
    return $self;
}

sub _convert_classname{
    my $filename = $_[0];
    $filename =~  s#::#/#g;
    $filename.='.pm';
    return $INC{$filename}||'';
}
sub classname{
    my ($self,$classname) = @_;
    $self->{classname} = $classname if $classname;
    $self->{classname};
}
sub filter{
    my ($self,$filter) = @_;
    $self->{filter} = $filter;
    $filter;
}

sub _start_code_view{
    my $self = shift;
    my ($filename,$regex)=@_;
    return unless $filename;
    my $c_v = $self->{c_v};
    $self->{c_v_entry_filter}= $regex;
    unless ($c_v && $c_v->Exists){
        $self->_code_view_init_top();
        $c_v = $self->{c_v};
    } else {
        $c_v->deiconify;
        $c_v->raise;
    }
    my $text = $self->{c_v_text};
    my $fh;
    open $fh,'<',$filename or die  "could not open '$filename'  $!";
    my @lines = <$fh>;
    close $fh or die "could not close '$filename' $!";
    $c_v->configure(-title=>$filename);
    $text->delete('0.0','end');
    $text->insert('end',$_) for @lines;
    $c_v->focus();
    $self->_c_v_filter_changed() if $regex;
}
sub _code_view_init_top{
    my $self = shift;
    my $c_v = $self->Toplevel();
    my $frame = $c_v->Frame()->pack;
    my $text     = $c_v->Scrolled('ROText',
                                  -wrap => 'none',
                                  -bg   => 'white',
                              )->pack(-fill   => 'both',
                                      -expand => 1,
				  );
    my $entry = $frame ->LabEntry(-label       => 'Filter',
                                  -labelPack   => [-side=>'left'],
                                  -textvariable=>\($self->{c_v_entry_filter}||=''),
                                  -bg          =>'white'
                              )->pack(-anchor => 'e');
    my $font  = $self -> fontCreate(-family => 'Courier',
                                    -size   => 10,
                                );
    $text->configure(-font => $font);
    $text->bind('<Control-plus>' ,sub{$self->_c_v_change_fontsize( 2)});
    $text->bind('<Control-minus>',sub{$self->_c_v_change_fontsize(-2)});
    $entry->bind('<Return>',sub {$self->_c_v_filter_changed});

    $frame->Button(-text    =>'Find Next',
                   -command => sub{$self->_c_v_filter_changed})->pack;
    @$self{qw/c_v c_v_text c_v_font/} = ($c_v,$text,$font);
    #allow one code_view window only:
    $c_v->protocol("WM_DELETE_WINDOW",sub{$c_v->withdraw});
}
sub _c_v_filter_changed{
    my $self = shift;
    my $text = $self->{c_v_text};
    $text->focus;
    $text->FindNext(-forward=>'-regex','-case',$self->{c_v_entry_filter});
}

sub _c_v_change_fontsize{
    my $self = shift;
    my $delta = $_[0];
    my ($text,$font) = @$self{qw/c_v_text c_v_font/};
    my $size = $text->fontConfigure($font,'-size');
    $size += $delta;
    $size = ($size < 8) ? 8  : $size;
    $size = ($size > 12)? 12 : $size;
    $text->fontConfigure($font,'-size',$size);
}

sub _test_{
    my $mw = Tk::tkinit();
    $mw->PerlMethodList(-classname=>'Tk::MainWindow')->show_methods;

    Tk::MainLoop();
}
1;
