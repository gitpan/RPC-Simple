package RPC::Simple::AnyRemote;

use strict;
use vars qw($VERSION $AUTOLOAD);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

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
    $self->{origDir} = $ENV{'PWD'} ;
	
    bless $self,$type ;
  }


sub AUTOLOAD
  {
    my $self = shift ;
    
    my $called = $AUTOLOAD ;
    return if $called =~ /::DESTROY$/ ;
    
    $called =~ s/.*::// ;
    
    $self->{ctrlRef}->delegate($called,@_) ;
    
    return $self ;
  }

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyRemote - Perl base class for a remote object accessible by RPC

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

'callback' => [ $function_ref ]

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

   &$callback("Hello local object" ) ;
 }

=head1 Methods

=head2 new('controller_ref')

controller_ref is the RPC::Simple::ObjectHandler object actually controlling 
this instance.

If you overload 'new', don't forget to call also the inherited 'new' method.

=head2 AUTOLOAD

Will call a local object method.

returns self.

=head1 instance variable

AnyRemote will create the following instance variables:

=head2 ctrlRef

RPC::Simple::ObjectHandler object reference

=head2 origDir

Store the pwd of the object during its creation.

=head1 CAVEATS

I have not yet tested how to use this class and the AutoLoader in the same
child class. This may lead to 'intersting' side effects.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3)

=cut

