package RPC::Simple::AnyLocal;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

use RPC::Simple::Agent ;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.01';

# Preloaded methods go here.

sub createRemote
  {
    my $self = shift ;
    my $factory = shift ;
    
    # create real process object
    $self->{remoteHandle} = 
      $factory->newRemoteObject($self, @_ ) ;
    
    $self->{remoteHostName} = $self->{remoteHandle}->getRemoteHostName() ;
  }

sub AUTOLOAD
  {
    my $self = shift ;
	
    my $called = $AUTOLOAD ;
    return if $called =~ /::DESTROY$/ ;

    $called =~ s/.*::// ;

    $self->{remoteHandle}->delegate($called,@_) ;
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyLocal - Perl extension defining a virtual SRPC client class

=head1 SYNOPSIS

 use RPC::Simple::AnyLocal;

 package MyLocal ;
 use vars qw($VERSION @ISA) ;
 @ISA = qw(RPC::Simple::AnyLocal);

 sub new
  {
    my $type = shift ;

    my $self = {} ;
    my $remote =  shift ;
    bless $self,$type ;

    $self->createRemote($remote) ;
    return $self ;
  }

 # Note that the 'remoteHello' method is not part of MyLocal

 package main;

 # client part
 my $mw = MainWindow-> new ;
 my $verbose = 1 ;

 # create fatory
 my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
 my $local = new MyLocal($factory) ;
 $mw -> Button (text => 'quit', command => sub {exit;} ) -> pack ;
 $mw -> Button (text => 'remoteAct',
   command => sub {$local->remoteHello();} ) -> pack ;

 MainLoop ; # Tk's


=head1 DESCRIPTION

This class must be herited by a sub-class so this one can use the SRPC 
facility.

Note that this class (and the Factory class) was designed to use Tk's 
fileevent facilities.

=head1 Methods

=head2 createRemote(ref)

This method should be called by the child object during start-up. It will
ask the SRPC factory to create a ClientAgent class dedicated to this new 
object.

The hash will be copied by Data::Dumper and passed to the remote object
during ots creation.

=head2 AUTOLOAD()

When this method is called (generally through perl mechanism), the call will
be forwarded with all parameter to the remote object. If the parameters
are  :

'callback' => \$one_callback 

the function &one_callback will be called.

If the parameters are 'callback' => [ $anobject, 'a_method' ].
Then this object method will be called back.

=head2 setUserName()

This method may be used by the remote object to set the 'userName' instance 
variable of RPC::Simple::AnyLocal.

=head1 instance variable

AnyLocal will create the following instance variables:

=head2 remoteHandle

Will contains the ref of the RPC::Simple::Agent object.

=head2 remoteHostName

Will contains the name of the remote host.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::Factory(3), RPC::Simple::AnyRemote(3)

=cut


# used by remote object to inform local object of the user name
sub setUserName
  {
	my $self =shift ;
	$self->{userName} = shift ;
  }

