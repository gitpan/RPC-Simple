package RPC::Simple::ObjectHandler;

use strict;
use vars qw($VERSION @ISA @EXPORT);

use RPC::Simple::CallHandler ;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

sub new
  {
    my $type = shift ;
    my $self = {} ;
    
    $self->{server} = shift ;
    my $objName = shift ;
    $self->{handle} = shift ;
    my $args = shift ;
    
    print "Creating object controler for $objName\n" if $main::verbose ;
    
    $self->{objRef} = $objName -> new ($self, @$args) ;

    bless $self,$type ;
  }

sub remoteCall
  {
    my $self = shift ;
    my $reqId = shift ; # optionnal
    my $method = shift ;
    my $args = shift ;
    
    if (defined $reqId)
      {
        # call back required
        $self->{requestTab}{$reqId} = 
          RPC::Simple::CallHandler -> 
            new ($self,$self->{objRef}, $reqId, $method, $args) ;
      }
    else
      {
        $self->{objRef} -> $method (@$args);
      }
  }

sub close 
  {
    my $self = shift ;
    
    print "Closing ",ref($self),"\n" ;
    
    map( undef $self->{requestTab}{$_}  , keys %{$self->{requestTab}}) ;
    $self->{objRef} -> close ;
    undef $self ;
  }

sub delegate 
  {
    my $self = shift ;
    my $method = shift ;
    my $args = \@_ ;
    
    return if ($method eq 'DESTROY' or $method eq 'close') ;
    
    print "delegate called by real object for $method\n" if $main::verbose ;
    $self->{serverRef}-> writeSock($self->{handle},$method,undef,$args) ;
  }

sub callbackDone 
  {
    my $self = shift ;
    my $reqId = shift ;
    my $result = shift ;
    
    print "callbackDone called\n" if $main::verbose ;
    $self->{server}->writeSock($self->{handle},undef,$reqId,[$result]) ;
  }

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::ObjectHandler - Perl class to handle a remote object 

=head1 SYNOPSIS

  use RPC::Simple::ObjectHandler;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for RPC::Simple::ObjectHandler was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 new (server_ref, object_name, agent_id, argument_array_ref)

Creates a new object controller. Also creates a new object_name which
is remotely controlled by the agent referenced by agent_id.

The new method of the slave object will be passed the argument stored
in array_ref

The connection server is passed with server_ref

=head1 METHODS

=head2 remoteCall( [request_id], method_name, arguments )

Will call the slave object with method method_name and the arguments.

If request_id is defined, it means that a call-back is expexted. In this case,
the argument passed should contains 'callback' => call_back_method.

=head2 close

=head2 delegate(method_name, ... )

Used to call the local object with passed method and arguments.

=head2 callbackDone($reqId,$result)

Called by the callHandler when a function performed by the remote object
is over. $result being the result of this function.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
