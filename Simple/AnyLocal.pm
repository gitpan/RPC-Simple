package RPC::Simple::AnyLocal;

use strict;
use vars qw($VERSION $AUTOLOAD);

use RPC::Simple::Agent ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.01';

# Preloaded methods go here.

# We may need a mechanism to declare the functions vailable on the remote
# side

sub createRemote
  {
    my $self = shift ;
    my $factory = shift ;
    my $remoteClass = shift ;

    die "No factory object given to ",ref($self),"->createRemote\n"
      unless defined $factory ;

    # create real process object
    $self->{remoteHandle} = 
      $factory->newRemoteObject($self, $remoteClass, @_ ) ;
    
    $self->{remoteHostName} = $self->{remoteHandle}->getRemoteHostName() ;
    return $self ;
  }

sub AUTOLOAD
  {
    my $self = shift ;
	
    my $called = $AUTOLOAD ;
    return if $called =~ /::DESTROY$/ ;

    $called =~ s/.*::// ;

    $self->{remoteHandle}->delegate($called,@_) ;
    return $self ;
  }

sub DESTROY
  {
    my $self = shift ;
    print "class ",ref($self)," destroyed \n";
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyLocal - Perl extension defining a virtual SRPC client class

=head1 SYNOPSIS

 package MyLocal ;

 use RPC::Simple::AnyLocal;
 use vars qw($VERSION @ISA) ;
 @ISA = qw(RPC::Simple::AnyLocal);

 sub new
  {
    my $type = shift ;

    my $self = {} ;
    my $remote =  shift ;
    bless $self,$type ;

    $self->createRemote($remote,'your_class_name') ;
    return $self ;
  }

 # Note that the 'remoteHello' method is not part of MyLocal

 package main;

 use Tk ;
 use RPC::Simple::Server ;
 use RPC::Simple::Factory ;

 my $pid = &spawn ; # spawn server if needed
 
 # client part
 my $mw = MainWindow-> new ;
 my $verbose = 1 ;

 # create factory
 my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
 my $local = new MyLocal($factory) ;
 $mw -> Button (text => 'quit', command => sub {exit;} ) -> pack ;
 $mw -> Button (text => 'remoteAct',
   command => sub {$local->remoteHello();} ) -> pack ;

 MainLoop ; # Tk's


=head1 DESCRIPTION

This class must be inherited by a sub-class so this one can use the RPC 
facility.

Note that this class (and the Factory class) was designed to use Tk's 
fileevent facilities.

=head1 Methods

=head2 createRemote(factory_object_ref, [remote_class_name], ... )

This method should be called by the child object during start-up. It will
ask the SRPC factory to create a ClientAgent class dedicated to this new 
object.

The server on the other side of the socket will load the code necessary
for the remote class. By default the remote class name will be 
...::Real<LocalClass>. I.e if your local class is Test::Foo the remote
class name will be Test::RealFoo. 

If the remote class name has no prefix, '.pm' will be appended to get the
file name to load

The remaining parameters will passed to the remote object's new method
during its creation.

returns self.

=head2 AUTOLOAD()

When this method is called (generally through perl mechanism), the call will
be forwarded with all parameter to the remote object. If the parameters
are  :

'callback' => \$one_callback 

the function &one_callback will be called when the remote side has finished
its function. 

If you want to call-back an object method, use a closure. Such as

 $self->remote_method('callback' => sub {$self-> finished(@_)})

returns self.

=head1 instance variable

AnyLocal will create the following instance variables:

=head2 remoteHandle

Will contains the ref of the RPC::Simple::Agent object.

=head2 remoteHostName

Will contains the name of the remote host.

=head1 CAVEATS

I have not yet tested how to use this class and the AutoLoader in the same
child class. This may lead to 'intersting' side effects.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::Factory(3), RPC::Simple::AnyRemote(3)

=cut


