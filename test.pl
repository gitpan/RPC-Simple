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
use vars qw($VERSION @ISA) ;
@ISA = qw(RPC::Simple::AnyLocal);

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

sub implicitAnswer
  {
    my $self = shift ;
    my $result = shift ;

    print "implicit answer is $result\n" ;
  }
  
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

if (not defined $arg)
  {
    my $pid = &spawn ; # spawn server
  }
elsif ($arg eq '-s')
  {
    RPC::Simple::Server::mainLoop () ;
  }

# client part
my $mw = MainWindow-> new ;
my $verbose = 1 ;
# create factory
my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
my $local = new MyLocal($factory) ;
$mw -> Button (text => 'quit', command => sub {exit;} ) -> pack ;
$mw -> Button (text => 'remote hello', 
               command => sub {$local->remoteHello();} ) -> pack ;
$mw -> Button (text => 'remote query', 
               command => sub 
               {
                 $local->remoteAsk('callback' => sub{$local->answer(@_)});
               } ) -> pack ;
$mw -> Button (text => 'remote query, implicit answer', 
               command => sub 
               {
                 $local->remoteAsk();
               } ) -> pack ;
MainLoop ; # Tk's

