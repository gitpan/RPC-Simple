package RPC::Simple::AnyRemote;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

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

# this is the former package LabDev::RemCommon ;
use English ;

# see loadspecs for other names
sub new 
  {
    my $type = shift ;
    my $self = {} ;

    print "creating new $type\n";
    $self->{ctrlRef} = shift ;
	
    $self->{specs} = shift ;

    $self->{name}= $self->{specs}{name} ;
    $self->{workDir} = $self->{specs}{workDir} ;
    $self->{workDir}.='/' unless $self->{workDir} =~ m!/$! ;
     
    bless $self,$type ;
    
    $self->{origDir} = $ENV{'PWD'} ;
    
    $self->loadSpecs() ;
    return $self ;
  }

sub check
  {
	my $self = shift ;
	my $dummy = shift ;

	die "Error: no callback specified $self->{name} for check method\n" if 
	  $dummy ne 'callback' ;

	my $callback  = shift ;

	$self->printRemDebug("Performing check\n");

	$self->findUid() unless defined $self->{uid} ;
	
	my $result = 0 ;

	if (defined $self->{uid})
	  {
		$EUID = $self->{uid} ;
		$EGID = $self->{gid} ;
		$UID = $self->{uid} ;
		$GID = $self->{gid} ;
		$result = $self->actualCheck(@_) ;
	  }

	$self->printRemDebug("check done, result is $result\n");

	$self->doCallback($callback,$result) ;
  }

sub findUid
  {
	my $self = shift ;
	
	if (defined $self->{specs}{setUser})
	  {
		my $theName = $self->{userName} = $self->{specs}{setUser} ;
		my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell)
		  = getpwnam($theName) ;
		unless (defined $uid )
		  {
			$self->printEvent("No uid found for user '$theName'\n") ;
			return 0;
		  }
		$self->{uid} = $uid ;
		$self->{gid} = $gid ;
	  }
	else
	  {
		$self->{uid} =$self->{specs}{uid};
		my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell)
		  = getpwuid($self->{specs}{uid});
		unless (defined $name )
		  {
			$self->printEvent("No user found for uid $self->{uid}\n") ;
			return 0;
		  }
		$self->{userName} = $name ;
		$self->{gid} = $gid ;
	  }

	$self->setUserName($self->{userName});
}

sub doCallback
  {
	my $self = shift ; #unused ...
	my $cbRef = shift ;
	my $result = shift ;

	print ref($self)," doCallback called\n";
	if (defined $cbRef)
	  {
		if (ref $cbRef eq 'ARRAY')
		  {
			my @tab=@$cbRef ;
			my $ref = shift @tab ;
			my $meth =shift @tab ;
			$ref-> $meth ( @tab, $result) ; # canonical callback method
		  }
		else
		  {
			&$cbRef($result);
		  }
		return 1;
	  }
	return 0 ;
  }


sub blast
  {
	my $self = shift ;
	$self->printRemDebug( "dummy blast for ",ref($self)," $self->{name}\n");
	# delete log files if ??? TBD
  }

sub init
  {
	my $self =shift ;
	my $dummy = shift ;

	die "Error: no callback specified $self->{name} for init method\n" if 
	  $dummy ne 'callback' ;

	my $callback  = shift ;

	$self->printRemDebug( "Initialising  \n");

	$self->findUid() unless defined $self->{uid} ;
	
	my $result = 0 ;

	if (defined $self->{uid})
	  {
		$EUID = $self->{uid} ;
		$EGID = $self->{gid} ;
		$UID = $self->{uid} ;
		$GID = $self->{gid} ;
		$result = $self->actualInit() ;
	  }

	$self->printRemDebug( "init done, result is $result\n");

	$self->doCallback($callback,$result) ;
  }

sub update
  {
    my $self = shift ;
    my $dummy = shift ;
    my $callback = shift ;
    
    my ($key,$value) ;
    while ($key = shift )
      {
	$self->{$key} = $value ;
      }
  }

sub query
  {
    my $self = shift ;
    my $dummy = shift ;
    my $callback = shift ;
    
    my %hash ;
    
    foreach (@_)
      {
	$hash{$_}= $self->{$_} ;
      }
    $self->doCallback($callback,\%hash) ;
  }

sub queryKeys
  {
    my $self = shift ;
    my $dummy = shift ;
    my $callback = shift ;
    
    my @array = keys(%$self) ;
    $self->doCallback($callback,\@array) ;
  }

sub AUTOLOAD
  {
    my $self = shift ;
    
    my $called = $AUTOLOAD ;
    return if $called =~ /::DESTROY$/ ;
    
    $called =~ s/.*::// ;
    
    $self->{ctrlRef}->delegate($called,@_) ;
  }

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyRemote - Perl base class for a remote object accessible by SRPC

=head1 SYNOPSIS

  package myClass ;
  use vars qw(@ISA);
  use RPC::Simple::AnyRemote;

  @ISA=('RPC::Simple::AnyRemote') ;


=head1 DESCRIPTION

This class must be inherited by the user's class actually performing the 
remote functions.

Note that any user defined method which can be called by the local object must 
be able to handle the following optionnal parameters :

'callback' => [ $object_ref, 'method' ]

Usually, the methods will be like :

 sub 
 {
   my $self = shift ;
   my $param = shift ;
   my $callback ;

   if ($param eq 'callback')
     {
       # callback required
       $callback = shift          
     }

   # user code

   # when the user code is over
   return unless defined $callback ;

   my ($obj,$method) = @$callback ;
   $obj -> $method ( $your, $arguments ); # well, sort of
 }

=head1 Methods

=head2 query (key , ... )

query self for a key/value,

Returns a hash ref containing key/values for all passed keys.

=cut

=head2 update(key => value, ... )

update self with a key/value

=cut

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3)

=cut

