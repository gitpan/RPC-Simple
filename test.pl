# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib ;
use RPC::Simple ;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$SIG{CHLD} = \&childDeath ;

package MyLocal ;
use vars qw($VERSION @ISA @RPC_SUB $tempObj) ;
@ISA = qw(RPC::Simple::AnyLocal);
@RPC_SUB = qw(close remoteHello remoteAsk);

sub new 
  {
    my $type = shift ;
    
    my $self = {} ;
    print "creating $type\n";
    my $remote =  shift ; 
    bless $self,$type ;

    $self->createRemote($remote,'RealMyLocal.test_pm') ;
    return $self ;
  }

# this routine is known by the remote class and is actually called by it
sub implicitAnswer
  {
    my $self = shift ;
    my $result = shift ;

    print "implicit answer is $result\n" ;
  }
  
# this routine is not knwon from the remote class and will be called only
# by the call-back mechanism.
sub answer
  {
    my $self = shift ;
    my $result = shift ;

    print "answer is $result\n" ;
  }


package main ;

use Tk ;
use RPC::Simple::Server ;
use RPC::Simple::Factory ;

my $arg = shift ;
my $clientPid ;

my $verbose = 0 ; # you may change this value to see RPC traffic

if (not defined $arg)
  {
    my $pid = &spawn(undef,$verbose) ; # spawn server
  }
elsif ($arg eq '-s')
  {
    RPC::Simple::Server::mainLoop (undef,$verbose) ;
  }

# client part
my $mw = MainWindow-> new ;
# create factory
my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
my $local = new MyLocal($factory) ;


$mw -> Button (text => 'quit', command => sub {exit;} ) -> pack ;
$mw -> Button (text => 'remote hello', 
               command => sub {$local->remoteHello();} ) -> pack ;
$mw -> Button (text => 'remote query', 
               command => sub 
               {
                 $local->remoteAsk(sub{$local->answer(@_)});
               } ) -> pack ;
$mw -> Button (text => 'remote query, implicit answer', 
               command => sub 
               {
                 $local->remoteAsk();
               } ) -> pack ;

my $queryb = 
  $mw -> Button (text => 'remote query on new object', 
                 state => 'disabled',
                 command => sub 
                 {$tempObj->remoteAsk(sub{$tempObj->answer(@_)});} ) -> pack ;
$mw -> Button (text => 'create new object', 
               command => sub 
               {
                 $tempObj =  new MyLocal($factory) ;
                 $queryb->configure( state => 'active');
               } ) -> pack ;
$mw -> Button (text => 'delete new object', 
               command => sub 
               {
                 $tempObj->destroy ; undef $tempObj;
                 $queryb->configure( state => 'disabled');
               } ) -> pack ;
MainLoop ; # Tk's

