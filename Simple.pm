package RPC::Simple;

use strict  ;
use vars qw/$VERSION/;

use RPC::Simple::AnyLocal;
use RPC::Simple::AnyRemote ;

$VERSION = '1.001' ;

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

But it works. (Although I'm opened to suggestion regarding the
"un-proof" areas)

The module is made of the following sub-classes :

 RPC::Simple::Agent - Perl extension for an agent object 
 RPC::Simple::AnyLocal - Perl extension defining a virtual RPC client class

 RPC::Simple::AnyRemote - Perl base class for a remote object 
 RPC::Simple::CallHandler - Perl class to handle RPC::Simple calls with call-back
 RPC::Simple::Factory - Perl extension for creating client
 RPC::Simple::ObjectHandler - Perl class to handle a remote object
 RPC::Simple::Server - Perl class to use in the RPC::Simple server script.
 RPC::Simple::AnyWhere - Common parts for AnyLocal and AnyRemote

Anyway, the casual user should worry only about inheriting the 
RPC::Simple::AnyLocal class and creating a RPC::Simple::Factory on the local
side.

On the remote side, the user will only have to inherit RPC::Simple::AnyRemote
and run the mainLoop method of RPC::Simple::Server.

In each side you must declare all methods available on the other side
in a global array of your class.

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

 - Now any call to an undefined method (BUT declared in @RPC_SUB)
of LocalClass will be forwarded to the Remote class.
If this call has a code reference as first parameter, Agent
will call this code when the remote call is over. I.e. all remote
procedure call must be designed in asynchronous mode.

Note that undefined method not declared in @RPC_SUB will lead to an
error. Autoloading is no longer supported (unless someone complains
loudly).

Note that Factory and Agent can use Tk to manage the socket
connection, but thisis no longer required..


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
LocalClass. RemtoteClass may call a function from local class using the
same mechanism but it may NOT expect a call-back from this call to the 
local side.

Note that the remote class may call directly method from the Local class.
(Provided the local method is declared in the @RPC_SUB array of the remote
class)

Note that the instance variable of the local class or remote class are not
shared or updated or replicated magically. If you must pass data from one side
to the other, you have to do it explicitely. In most case you'll pass the 
variable value as a method parameter.

=head1 CAVEATS

Well, this stuff is supposed to be pretty simple, the code to handle
the RPC and callback is not very complicated, but I sure have a lot of
problem to write a doc which make using this module simple. Future
version may get better depending on your comments or questions.

=head1 AUTHOR

Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3), RPC::Simple::AnyRemote(3) .

=cut
