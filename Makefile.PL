use 5.001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::PerlMethodList',
    VERSION_FROM      => 'lib/Tk/PerlMethodList.pm', # finds $VERSION
    PREREQ_PM         => {Tk          =>'8.4',
			  Tk::LabEntry=>'4.006',
			  Class::ISA  =>'0.33',
			  File::Slurp =>'9999.08'
			  } ,
      ABSTRACT_FROM  => 'lib/Tk/PerlMethodList.pm', 
       AUTHOR         => 'Christoph Lamprecht <lamprecht@cpan.org>') ;



