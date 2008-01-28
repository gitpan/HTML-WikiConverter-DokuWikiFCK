use 5.008008;
use ExtUtils::MakeMaker;
use Term::ReadLine;
use Cwd;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::WikiConverter::DokuWikiFCK',
    VERSION_FROM      => 'lib/HTML/WikiConverter/DokuWikiFCK.pm', # finds $VERSION
    PREREQ_PM         => { 'HTML::WikiConverter' =>0.061,
                           'HTML::WikiConverter::DokuWiki' =>  '0.53'			       
                            }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/WikiConverter/DokuWikiFCK.pod', # retrieve abstract from module
       AUTHOR         => 'Myron Turner <turnermm02@shaw.ca>') : ()),
);



our $term = new Term::ReadLine 'DokuWik Plugins Directory';
our $prompt= "Name of Directory: ";         
our $OUT = $term->OUT || \*STDOUT;

sub getDWPluginsDir {
my $tpl = shift;            

         while ( defined ($_ = $term->readline($prompt)) ) {
           print $OUT $dwplugins, "\n";
           last if (/^$/ || /^\n$/m || /^\s+$/m);
           if(-d $_ || $tpl) {
              return $_;
           }            
           else {
             print "\n$_ is not accessible. Try again? Or press Return to abort.\n"
                  . "You can then install fckg.tgz manually\n";
           }
         }

      return 0;
}


END {

my $pwd = cwd();
my $HOME = $ENV{'HOME'};
print qq(\n------------------
  I need the (absolute) pathname to your DokuWiki plugins directory,
  in order to install the fckg plugin. For instance:
           /var/www/html/dokuwiki/lib/plugins
  If you don't know it or want to install it later, just press return. 

  You can always install the fckg plugin later. If you
  are installing from the CPAN shell (perl -MCPAN -e shell),
  you should find fckg.tgz in your home directory at
        $HOME/.cpan/DokuWikiFCK_<version>/fckg.
  If you are installing from the perl distribution,
  you will find it in the current directory under fckg/. 
  If you have any questions, see the README file.

\n----------\n
);

my $dwplugins =  getDWPluginsDir(0);

if($dwplugins) {
  my @args = ("cp", "fckg/fckg.tgz", $dwplugins);
  if(system(@args) == 0) {
     print "copied fckg/fckg.tgz to $dwplugins\n";
     print "Installing editor\n";
     chdir($dwplugins);
     my @args = ("tar", "-xzf", "fckg.tgz");

     if(system(@args) == 0) {
         print "Install successful\n";
     }

    print qq(\n
    The FCKeditor's image manager uses a modified version
    of DokuWiki's mediamanager.php. The modified version is fully 
    compatible with the original.  The original version
    will be backed up as mediamanager.php.$$.  To substitute
    the modified version for the original, please enter the
    name of the directory where it is found, for instance:
              default
    We will then install the new medimanager in lib/tpl/default.     
    );   
   my $tpl_dir =  getDWPluginsDir(1);
   my $mediamanager = $pwd .'/fckg/mediamanager.php' ;

   $dwplugins =~ s/\/plugins.*//;
   chomp($tpl_dir);
   $tpl_dir = $dwplugins . '/tpl/' . $tpl_dir;
   chdir($tpl_dir);

   rename ('mediamanager.php', 'mediamanager.php' . '.' . $$);
   @args = ("cp", $mediamanager, $tpl_dir);
   if(system(@args) == 0) {
         print "Copied new mediamanager to $tpl_dir\n";
         print "Renamed original mediamanager: mediamanager.php.$$\n";
     }
     else {
           print "Unable to copy new media manager to $tpl_dir\n";
           print "You may do this manually.\n"
     }
  }
  else {
     print qq(\n
  Unable to copy fckg/fckg.tgz to $dwplugins.
  Please copy it to your plugins directory and unzip it.
  It will install from the command line.\n);
  }
}
else {
   print qq(\n
           Unable to install fckg.tgz.  Please copy
           fckg/fckg.tgz to your DokuWiki plugins directory and
           unzip it.\n);
}

         

}




