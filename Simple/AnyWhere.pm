package RPC::Simple::AnyWhere;

use strict;
use AutoLoader ;

use vars qw($VERSION $AUTOLOAD @RPC_SUB %_RPC_SUBS);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

( $VERSION ) = '$Revision: 1.4 $ ' =~ /\$Revision:\s+([^\s]+)/;

# Preloaded methods go here.

# We may need a mechanism to declare the functions vailable on the remote
# side

sub _searchSubs
  {
    my $self = shift ;
    my $package = shift ;

    push @{$_RPC_SUBS{ref($self)}}, eval("\@${package}::RPC_SUB") ;

    foreach my $class (eval("\@${package}::ISA")) 
      {
        $self->_searchSubs($class) ;
      }
  }

sub AUTOLOAD
  {
    my $self = $_[0] ; # do not shift out self
	
    my $called = $AUTOLOAD ;
    $called =~ s/.*::// ;

    if (defined $_RPC_SUBS{ref($self)} and
        scalar grep ($called eq $_,@{$_RPC_SUBS{ref($self)}} ))
      {
        shift ; # delegate does not want $self as first parameter
        $self->{_twinHandle}->delegate($called,@_) ;
        return $self ;
      }

    $AutoLoader::AUTOLOAD=$AUTOLOAD;
    goto &AutoLoader::AUTOLOAD ;
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

RPC::Simple::AnyWhere - extension defining a virtual SRPC client or server class

=head1 SYNOPSIS

 package MyLocal ;

 use RPC::Simple::AnyLocal; # or AnyRemote BUT NOT THIS CLASS


=head1 DESCRIPTION

This class is intented to be inherited only by AnyLocal or AnyRemote.
Don't use it yourself.


=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::Factory(3), RPC::Simple::AnyRemote(3)

=cut


