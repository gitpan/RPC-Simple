package RPC::Simple::Agent;

use strict;
use vars qw($VERSION @ISA @EXPORT);

use RPC::Simple::Factory ;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '0.01';


# Preloaded methods go here.

# connection is opened, ask for a remote object
sub new
  {
    my $type = shift ;
    my $sockObj = shift ;       # factory
    my $objRef = shift;
    my $specRef = shift ;
    my $cspecRef = shift ;
    my $optHash = shift ;
    
    my $self={} ;
    $self->{'idx'} = shift ;
    
    $self->{requestId} = 0 ;
    
    $self->{'socket'} = $sockObj ;
    $self->{remoteHostName} = $sockObj->getRemoteHostName() ;
    my $objName = ref($objRef) ;
    $objName =~ s/(\w+)$/Real$1/ ;
    
    print "Creating $type for $objName\n";
    
    $self->{'processObj'}= $objRef ;
    
    # merge spec and context specs and optHash
    my $hash ;
    if (defined $cspecRef)
      {
        %$hash = (%$cspecRef, %$specRef) ; # spec must overload context values
      } 
    else
      {
        $hash = $specRef ;
      }
    
    if (defined $optHash)
      {
        foreach (keys %$optHash)
          {
            $hash->{$_} = $optHash->{$_} ;
          }
      }
    
    $sockObj->writeSockBuffer($self->{'idx'}, 'new', undef ,
                              [ $hash ], $objName ) ;
    
    bless $self, $type ;
  }

sub getRemoteHostName
  {
    my $self =shift ;
    return $self->{'remoteHostName'} ;
  }

sub delegate
  {
    # delegate to remote
    my $self = shift ;
    my $method = shift ;
    my $param = $_[0] ;
    my $id ;
    
    if ($param eq 'callback')
      {
        # callback required
        print "delegate: $method will lead to a call-back\n";
        shift ;                 # remove param from array
                                # callback given, processObj already known
        $self->{callback}{$self->{requestId}} = shift ; # store call-back info
        $id = $self->{requestId}++ ;
      }
    
    $self->{'socket'}->writeSockBuffer($self->{'idx'},$method, $id,[ @_]) ;
  }

sub callMethod
  {
    my $self = shift ;
    my $method = shift ;
    my $args = shift ;
    $self->{processObj} -> $method (@$args) ;
  }

sub treatCallBack
  {
    my $self = shift ;
    my $reqId = shift ;
    my $args = shift ;
    print "treatCallback called for request $reqId\n";
    my $cbRef = $self->{callback}{$reqId} ;

    if (ref $cbRef eq 'ARRAY')
      {
        my @lcb = @$cbRef ;
        my $ref = shift @lcb;
        my $meth = shift @lcb;
        $ref-> $meth (@lcb, @$args) ; # canonical callback method
      }
    else
      {
        &$cbRef(@$args);
      }
    
    delete $self->{callback}{$reqId} ;
  }


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::Agent - Perl extension for an agent object for SRPC

=head1 SYNOPSIS

  use RPC::Simple::Agent ;

=head1 DESCRIPTION

This class is an agent for client class inheriting SPRC::Any. This
class will handle all the boring stuff to create, access store call-back 
when dealing with the remote object.

This class should not be used directly. RPC::Simple::AnyLocal will deal with it.

=head1 new( $factory_ref, client_ref, spec_ref, context_spec_ref, 
            optionnal_hash_ref )

Create the agent. 

factory_ref is the SPRC::Factory object.

client_ref is the client object itself.

context_ref and spec_ref and optionnal_hash_ref are 3 hash containing 
relevant info tor the remote object.

The content of these hash are merged
in that order (i.e. the first values may be clobberred) before the remote 
object is created.

TBD: Whether it's a good idea to merge these hashes or not.

=head1 Methods

=head2 getRemoteHostName

returns the remote host name

=head2 delegate( method_name , ['callback' => funref | [$obj, 'method'] ],
                parameter ,... )

Call a method of the remote object. If call back is specified, the call
back will be called with whatever parameters the remote functions passed
in its reply.

optionnal parameters are passed as is to the remote.

Note that ref are copied. You can't expect the remote to be able to modify
a client's variable because you passed it's ref to the remote. nuff' said.

=head2 callMethod( method_name, argument_array_ref )

Function used to call the owner of the agent. All arguments of the 
function to be called back are passed in the array ref.

=head2 treatCallBack ( request_id, argument_array_ref)

Function used to call-back the owner of the agent. All arguments of the 
function to be called back are passed in the array ref.

'request_id' is used to know what object and methos are to be called back. 
These info were stored by the delegate function.

=head1 AUTHOR

Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3).

=cut
