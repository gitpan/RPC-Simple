package RPC::Simple;

use RPC::Simple::AnyLocal;
use RPC::Simple::AnyRemote ;



1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple - Perl classes to handle SRPC calls with call-back

=head1 SYNOPSIS

  use RPC::Simple;

  #see test.pl file

=head1 DESCRIPTION

Dummy class which loads RPC::Simple::AnyLocal and RPC::Simple::AnyRemote ;

This module deals with remote procedure call. I've tried to keep things
simple. 

So this module should be :
 - quite simple to use (thanks to autoload mechanisms)
 - lightweight

It sure is not :
 - DCE
 - CORBA
 - bulletproof
 - securityproof
 - foolproof

But it works. (Although I'm opened to suggestion regarging the
"un-proof" areas)

The module is made of the following sub-classes :

 RPC::Simple::Agent - Perl extension for an agent object 
 RPC::Simple::AnyLocal - Perl extension defining a virtual RPC client class

 RPC::Simple::AnyRemote - Perl base class for a remote object 
 RPC::Simple::CallHandler - Perl class to handle RPC::Simple calls with call-back
 RPC::Simple::Factory - Perl extension for creating client
 RPC::Simple::ObjectHandler - Perl class to handle a remote object
 RPC::Simple::Server - Perl class to use in the RPC::Simple server script.


How it works ? The user (i.e. you) must write a local class which inherit
from AnyLocal. AnyLocal is designed to handle Agent and Factory.


    AnyLocal --1---<>---1-- Agent --*--<>---Factory----<>--LAN
        |
       /\____
            |
            |
        LocalClass

First, the user script will have to :
 - instantiate one Factory.
 - Create its instance of LocalClass
 - LocalClass::new will call $self->createRemote, this will create the 
Agent class.

 - Now any call to an undefined method of LocalClass will be forwarded 
to the Remote class.
If this call has 'callback' => [ $obj_ref, 'method'] as parameters, Agent
will call this object::method when the remote call is over. I.e. all remote
procedure call must be designed in asynchronous mode.

Note that Factory and Agent actually use Tk to manage the socket connection.



On the remote side, the user will write its RemoteClass which will inherit
from AnyRemote.

    LAN --1--<>--*-- Server --1--<>--*--ObjectHandler--1--<>--*--CallHandler
                                              |                        |
                                              1                        *
                                              |                        |
                                              --<>--1--AnyRemote--1-<>--
                                                           |
                                                          /\____
                                                               |
                                                               |
                                                          RemoteClass



RemoteClass will be called with the method name that was invoked for 
LocalClass.

=head1 TO DO

Write doc and test to handle remote processes. 

=head1 AUTHOR

Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3), RPC::Simple::AnyRemote(3) .

=cut
