package RPC::Simple::CallHandler;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
sub new
  {
	my $type = shift ;
	my $self = {} ;

	$self->{controlRef} = shift ;
	$self->{objRef} = shift ;
	$self->{reqId} = shift ;
	my $method = shift ;
	my $args = shift ;
	
	print "Creating call handler\n" if $main::verbose ;
	bless $self,$type ;
	
	$self->{objRef} -> $method ('callback'=> [$self,'done'] , @$args) ;
	return $self ;
  }

sub done 
  {
	my $self = shift ;
	my $result = shift ;
	
	print "done called\n" if $main::verbose ;
	$self->{controlRef} -> callbackDone ($self->{reqId}, $result) ;
  }


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::CallHandler - Perl class to handle SRPC calls with call-back

=head1 SYNOPSIS

  use RPC::Simple::CallHandler;
  blah blah blah

=head1 DESCRIPTION

Used only for asynchronous functions calls.

=head1 new (handler_ref, remote_object, request_id, method, argument_ref)

Call the remote_object methods with a call-back parameter and the passed 
arguments, store the handler ref.

Note that the called method must be able to handle these parameters:
'callback' => [ $object_ref, 'method' ]

=head1 methods

=head2 done ($result)

call-back method.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
