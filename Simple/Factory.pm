package RPC::Simple::Factory;

use strict;
use vars qw(@ISA @EXPORT $serverPid);
use Tk ;
use IO::Socket ;
use Fcntl ;
use Data::Dumper ;

require Exporter;

@ISA = qw(Exporter);
@EXPORT= qw(spawn) ;
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# Preloaded methods go here.

# As a test may control several machines, several Factory object may be created

# opens a connection to a remote host
# Tk top window, remote_host, port
sub new
  {
    my $type = shift ;
    my $tkTop = shift ;
    my $verboseRef = shift ;
    my $remote  = shift || 'localhost'; 
    my $port    = shift || 7810;	
    
    my $self= {} ;
    $self->{verbose} = $verboseRef ;
    
    $self->{handleIdx} = 0;
    $self->{remoteHostName} = $remote ;
    my ($iaddr, $paddr, $proto, $line);
    
    if ($port =~ /\D/) { $port = getservbyname($port, 'tcp') }
    
    print "No port" unless $port;

    $self->{'socket'} = IO::Socket::INET -> new (PeerAddr => $remote,
                                              PeerPort => $port,
                                              Proto => 'tcp' ) ;
    die "Can't create a socket for $remote, port $port\n\t$!\n" 
      unless defined $self->{'socket'} ;

    fcntl($self->{'socket'},F_SETFL, O_NDELAY) 
      || die "fcntl failed $!\n";

    print "$type object created \n";
    
    # print "sleep over, closing\n";
    # shutdown ($self->{'socket'}, 2)            || print "close: $!";
    
    bless $self, $type ;
    
    # register socket to TK's fileevent ...
    $tkTop -> fileevent($self->{'socket'},
                        'readable' => [$self, 'readSock']) ;
    $self->{tkTop} = $tkTop ;
    $self->{sockBuffer} = '' ;
    return $self ;
  }

sub logmsg
  {
    my $self = shift ;
    
    print @_ if (defined $self->{verbose} and ${$self->{verbose}} );
}

sub newRemoteObject
  {
    my $self=shift ;
    my $clientRef = shift ;
    my $remoteClass = shift ; #optionnal
    
    # create an Agent tied to the client object
    my $handle = RPC::Simple::Agent->new ($self,$clientRef,$self->{handleIdx},
                                          $remoteClass,@_) ;
    
    $self->{handleTab}{$self->{handleIdx}++} = $handle ;
    return $handle ;
  }

sub getRemoteHostName
  {
    my $self=shift ;
    return $self->{remoteHostName} ;
  }

sub writeSockBuffer
  {
    my $self=shift ;
    my $callingIdx = shift ;    # index of Agent
    my $method = shift ;
    my $reqId = shift ;
    my $param = shift  ;        # usually an array ref
    my $objectName = shift ;    # optionnal
    
    my $refs = [$param,$method,$reqId, $callingIdx ] ;
    my $names = ['args','method','reqId','handle',] ;
    
    if (defined $objectName)
      {
        push @$refs, $objectName ;
        push @$names, 'objectName' ;
      }
    
    my $d = Data::Dumper->new ( $refs, $names ) ;
    my $paramStr = "#begin\n".$d->Dumpxs."#end\n"  ; 
    #my $str = sprintf("%6d",length($paramStr)) . $paramStr ;
    my $str = $paramStr ;
    $self->logmsg( "$str\n");
    
    $self->{sockBuffer} .= $str ;
    # can't have read and write fileevent at the same time ...
    
    # 	$self->{tkTop} -> fileevent($self->{'socket'},
    # 						'writable' => [$self, 'writeSock']) ;
    # 	$self->{tkTop} -> fileevent($self->{'socket'},
    # 						'readable' => [$self, 'readSock']) ;
    #   }
    
    # sub writeSock
    #   {
    # 	my $self= shift ;
    
    # 	print "writeSock called\n";
    
    my $str2 = "#begin_buffer\n".$self->{sockBuffer}."#end_buffer\n" ;
    no strict 'refs' ;
    my $val = send($self->{'socket'} ,$str2,0) ;
    if ( defined $val and $val == length($str2))
      {
        $self->logmsg( "$val bytes sent\n");
      } 
    else
      {
        warn "write failed for \n",$str2  ;
      } 
    
    $self->{sockBuffer} = '' ;
    # 	$self->{tkTop} -> fileevent($self->{'socket'}, 'writable' => '') ;
    # 	$self->{tkTop} -> fileevent($self->{'socket'},
    # 						'readable' => [$self, 'readSock']) ;
  }

sub readSock
  {
    my $self = shift ;
    my $fh = $self->{'socket'} ;
    
    $self->logmsg( "readSock called\n");
    no strict 'refs' ;
    
    if (eof $fh)
      {
        print "closing connection\n";
        close $fh ;
        return ;
      }
    
    my $line ;
    my @codeTab = () ;
    my $code = '' ;
    my $codeEnd = 1 ;
    while ( $line = $fh->getline or not $codeEnd )
      {
        next unless defined $line ;
        
        $self->logmsg( "->",$line );
        $code .= $line ;
        
        if ($line =~ /\s*#end$/
           )
          {
            push @codeTab, $code ;
            $code = '' ;
            $codeEnd = 1 ;
          }
        if ($line =~ /\s*#begin$/
           )
          {
            $codeEnd = 0 ;
          }
        
        # line is still #end
        # 		my $dummy=''; ;
        # 		my $recvRet = recv(CLIENT,$dummy,1,MSG_PEEK) ;
        # 		unless (defined $recvRet) {warn "recv error ",$!,"\n" ; return 0;}
        # 		last if (length($dummy) == 0)
      }
    
    use strict ;
    
    foreach $code (@codeTab)
      {
        my ($args,$method,$reqId,$handle,$objectName) ;
        eval $code ;
        
        if ($@)
          {
            print "failed eval ($@) of :\n",$code,"end evaled code\n"  ; 
          }
        elsif (defined $method)
          {
            # call object method directly
            $self->logmsg( "calling method $method\n");
            $self->{handleTab}{$handle} -> callMethod($method , $args) ;
          }
        else
          {
            # it's a call-back
            $self->logmsg( "callback for handle $handle, request $reqId\n");
            $self->{handleTab}{$handle}->treatCallBack($reqId, $args);
            #			  or print "eval failed: $@\n";
          }
      }
    
    return 1;
  }

# static method. spawn a server
sub spawn
  {
    $serverPid = fork ;

    if ($serverPid == 0)
      {
        # I am a server now 
        RPC::Simple::Server::mainLoop () ;
        exit ; # well I should never go there
      }
    print "spawned server pid $serverPid\n" ; # don't use verbose
    sleep 2 ; # let the server start
    return $serverPid ;
  }

sub END
  {
     if (defined $serverPid and $serverPid != 0 )
       {
         print "killing process $serverPid\n";
         # 15 is SIGTERM signal
         kill (15, $serverPid) ;
       }
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::Factory - Perl extension for creating RPC client 

=head1 SYNOPSIS

 use Tk;
 use RPC::Simple::Factory;

 my $mw = MainWindow-> new ;
 my $verbose = 1 ; # up to you 

 # create factory
 my $factory = new RPC::Simple::Factory($mw,\$verbose) ;

=head1 DESCRIPTION

This class handles all the tricky stuff involving socket handling. 
Note that this was written to be used with Tk. 

=head1 Methods

=head2 new($tkTop, [ $verboseRef ], [remote_host], [port] )

create the factory. One factory must be created for each remote host..

tkTop is the ref of Tk's main window.

$verboseRef is the ref of a variable. When set to 1 at any time, the object
will become verbose i.e. it will print on STDOUT a lot of messages related 
to the RPC processing. Then you may use $verboseRef as a text variable on 
a check button to control whether you want to trace RPC messages or not.
If not provided, the object will not be verbose.

By default, remote_host is set to 'localhost', port is set to 7810.

=head2 logmsg (...)

print arguments if verbose mode.

=head2 newRemoteObject( $owner_ref, [ remote_class_name ] ... )

Will create a remote (the remote_class_name) object tied to the owner.

Additional parameters will be passed as is to the remote 'new' method.

=head2 getRemoteHostName

return the remote host name

=head2 writeSockBuffer ( agent_index, remote_method, request_id, parameter, [object_name])

Encode the method, object, parameter and send it to the remote object.

agent_index and request_id are used later for the call-back mechanism.

=head2 readSock

read pending data on the socket. Do an eval on the read data to call-back
the relevent Agents.

Note that there's no security implemented (yet).

=head1 Static functions

=head2 spawn

Will spawn a RPC::Simple server on your machine. Don't call this function if
you need to do RPC on a remote machine.

Return the server pid or null (just like fork)

=head1 ON EXIT

When the object is destroyed, the 'END' routine will be called. This will
kill the server if it was created by spawn.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

=head1 SEE ALSO

perl(1), RPC::Simple::Agent(3), RPC::Simple::AnyLocal(3).

=cut
