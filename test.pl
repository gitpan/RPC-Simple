# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
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

    $self->createRemote($remote) ;
    return $self ;
  }

sub answer
  {
    my $self = shift ;
    my $result = shift ;

    print "answer is $result\n" ;
  }

package RealMyLocal ;

use vars qw($VERSION @ISA) ;
@ISA = qw(RPC::Simple::AnyRemote);

sub new 
  {
    my $type = shift ;
    
    print "creating $type\n";

    my $self = {} ;
    bless $self,$type ;
  }

sub close 
  {
    my $self = shift ;
    print "close called on ",ref($self),"\n";
  }

sub remoteHello
  {
    my $self=shift ;
    print "Remote said 'Hello world'\n";
  }

sub remoteAsk
  {
    my $self=shift ;
    my $param = shift ;
    my $callback ;

    if ($param eq 'callback')
     {
       # callback required
       $callback = shift          
     }
    print "Local asked me to say hello\n";

   return unless defined $callback ;

   my ($obj,$method) = @$callback ;
   $obj -> $method ( "Hello local object" );
  }

package main ;
use Tk ;
use RPC::Simple::Server ;

my $arg = shift ;
my $clientPid ;

if (not defined $arg )
  {
    $serverPid = fork ;
  }
elsif ($arg eq '-c')
  {
    $serverPid = 1 ;
  }
elsif ($arg eq '-s')
  {
    $serverPid = 0 ;
  }

if ($serverPid != 0)
  {
    sleep 4 unless $arg eq '-c' ; # let the server start ...
    # client part
    my $mw = MainWindow-> new ;
    my $verbose = 1 ;
    # create fatory
    my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
    my $local = new MyLocal($factory) ;
    $mw -> Button (text => 'quit', command => 
                   sub 
                   { print "Killing process $serverPid\n";
                     kill KILL,$serverPid; 
                     exit;} ) -> pack ;
    $mw -> Button (text => 'remote hello', 
                   command => sub {$local->remoteHello();} ) -> pack ;
    $mw -> Button (text => 'remote query', 
                   command => sub 
                   {
                     $local->remoteAsk('callback' => [$local, 'answer']);
                   } ) -> pack ;
    MainLoop ; # Tk's

    # create local class (which should create its agent)
  }
else
  {
    print "spawned server pid $serverPid\n" unless $arg eq '-s' ;;
    #server part
    mainLoop() ;
    
    #create server
    # and listen
  }
