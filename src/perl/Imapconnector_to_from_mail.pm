# Imapconnector, es una clase que maneja las operaciones que se van a ejecutar
# sobre in servidor imap. 
# Durante la creacion se deben proporcionar los datos para acceder al servidor
# imap. Los cuales son servidor, puerto, usuario, clave, uso de ssl o tls.
# Asi mismo se debe establecer la accion posterior a la revision del correo.
# La accion puede ser.
# 1. Borrar el correo analizado
# 2. Marcar el correo como leido
# 3. Marcar el correo con un flag $MDNSent o Flagged el cual indica que los
#  mensajes no deben ser tenidos en cuenta en la proxima revision.
#
# TODO: Imapconnector entregara el correo analizado a un servidor de correos
# siempre y cuando este definido el objeto SMTP.
package Imapconnector;

use IO::File;
use Mail::IMAPClient;
use warnings;
use Data::Dumper;
do 'Imapconnector.conf.pl';

sub _debug_ {
  my $self = shift;
  my $msg = shift;
  if ($self->{debug}) {
    print {$self->{debug_fh}} "$msg\n";
  }
}

sub _report_ {
  my $self = shift;
  my $msg = shift;
  $self->{report_flag} = 1;
  if ($self->{report_fh}) {
    print {$self->{report_fh}} "$msg\n";
  }
}

# $user=usuario
# $pass=password
# $ssl=mecanismo de cifrado (tls | ssl | none)
# $debug=niver de debug(1|2), 1 - solo conector, 2 - conector + sesion_imap
sub new {
  my $class = shift;
  my $self = {
    server => shift,
    port => shift,
    user => shift,
    pass => shift,
    ssl => shift,
    debug => $CONFIG{loglevel},
    action => '',
    collected_total => 0,
    collected => {},
    stick_to => '',
    report_flag => 0,
    report_filename => '',
    report_fh => ''
  };
  
  $self->{report_filename} = 
    $CONFIG{tmp_report_dir}."/".
    $CONFIG{tmp_report_file_prefix}.$$;
  $self->{report_fh} = IO::File->new(">".$self->{report_filename});
  print $self->{report_filename}."\n";
  if ($self->{debug}) {
    $self->{debug_fh} = IO::File->new(">>".$CONFIG{logfile});
  }
  if (not $self->{debug_fh}) {
    print STDERR "Can't open logfile ".$CONFIG{logfile}."\n";
    print STDERR "Disabling logs\n";
    $self->{debug} = 0;
  }
  my $imap_ops = {};
  $imap_ops->{Server} = $self->{server};
  $imap_ops->{Port} = $self->{port};
  $imap_ops->{User} = $self->{user};
  $imap_ops->{Password} = $self->{pass};
  $imap_ops->{Peek} = 1;
  $imap_ops->{Uid} = 1;
  if ($self->{debug} > 1 ) {
    $imap_ops->{Debug} = 1;
    $imap_ops->{Debug_fh} = $self->{debug_fh};
  }
  $imap_ops->{Ssl} = 1 if ($self->{ssl} =~ /^ssl$/);
  $imap_ops->{Tls} = 1 if ($self->{ssl} =~ /^tls$/);
  my $imap =  Mail::IMAPClient->new(%$imap_ops);
  $self->{imap} = $imap;
  bless $self, $class;
  if (! $imap) {
    $self->_report_("{conectar}.Error durante la conexion con el servidor [".
      $self->{server}.":".$self->{port}."]"
    );
    $self->_report_("    RESPUESTA:$@");
    $self->_report_("---");
  }
  return $self;
}

# Define la accion a ejecutar sobre los mensajes en el servidor
# $action =accion por defecto( delete | mark_flagged | mark_seen)
#   "delete" - borrar los mensajes
#   "mark_flagged" - marcar con el flag $MDNSent o Flagged
#   "mark_seen" - marcar como leido
sub action{
  my $self = shift;
  my $action = shift;
  $self->_debug_("IC action: setting action to $action");
  $self->{action} = $action if ($action =~ /^(delete|mark_flagged|mark_seen)$/);
}

sub _build_filter_ {
  my $self = shift;
  my $action = $self->{action};
  return '' if ($action eq '');
  # la accion define un filtro totalmente inverso
  # mark_seen - marcar como visto, hace que busque todos los mensajes sin leer unseen
  # delete - hace que busque directamente todos los mensajes.
  # mark_flagged - buscar todos los mensajes sin el flag $MDNSent o Flagged
  my $filter_map = {
    'mark_seen' => 'UNSEEN',
    'delete' => 'ALL',
    'mark_flagged' => 'UNFLAGGED'
    #'mark_flagged' => 'NOT KEYWORD $MDNSent'
  };
  return $filter_map->{$action};
}


sub _post_callback_ {
  my $self = shift;
  my $action = $self->{action};
  return sub {} if ($action eq '');
  my $callbacks = {
    'mark_seen' => sub {
      my $imap = shift;
      my $msgs = shift;
      $imap->set_flag("\\Seen", @$msgs);
    },
    'delete' => sub {
      my $imap = shift;
      my $msgs = shift;
      $imap->delete_message(@$msgs);
      $imap->expunge;
    },
    'mark_flagged' => sub {
      my $imap = shift;
      my $msgs = shift;
      $imap->set_flag("\\Flagged", @$msgs);
    }
  };
  return $callbacks->{$action};
}



# Funcion para establecer la carpeta a la cual se quedara "pegado"
# el conector imap. Por "pegado" se entiende que todas las operaciones se 
# ejecutaran solo sobre esa carpeta. Todas las demas se saltearan.
sub stick_to {
  my $self = shift;
  my $sfolder = shift;
  
  return if (! $self->{imap});
  
  if ($sfolder eq '') {
    $self->{stick_to} = '';
  } else {
    @folders = $self->{imap}->folders;
    foreach my $folder (@folders) {
      if ($sfolder eq $folder) {
        $self->_debug_("IC stick_to: sticked to $folder");
        $self->{stick_to} = $folder;
      }
    }
  }
}

# Ejecuta la revision de la cuenta imap
# Revisa todos los mensajes basandose en la accion establecida.
# Los UIDs de los mensajes que satisfacen el criterio son recolectados en 
#   la estructura interna.
# La funcion retorna el nro de mensajes recolectados.
sub collect{
  my $self = shift;
  return if (! $self->{imap});
  $self->_debug_("IC collect: scanning folders");
  my @folders;
  $self->{collected} = {};
  my $collected = $self->{collected};
  my $searched_total = 0;
  @folders = $self->{imap}->folders;
  if ($self->{imap}->LastError) {
    $self->_debug_("IC collect: Error while scan folders ".
      $self->{imap}->LastError
    );
    $self->_report_("{colectar}.Error al obtener el listado de las bandejas");
    $self->_report_("    ERROR:".$self->{imap}->LastError);
    $self->_report_("---");
  }
  my $filter = $self->_build_filter_;
  $self->_debug_("IC collect: setting up $filter filter");
  foreach my $folder (@folders) {
    if ($self->{stick_to} ne '' && $self->{stick_to} ne $folder) {
      $self->_debug_("IC collect: skipping $folder, sticked to ".
        $self->{stick_to});
      next;
    }
    $collected->{$folder} = [];
    $self->_debug_("IC collect: examining $folder");
    my $res = $self->{imap}->examine($folder);
    if ($self->{imap}->IsSelected and $res) {
      my @searched = $self->{imap}->search($filter);
      # IMAPClient vacia $@ y lo mantiene vacio si todo va bien
      if (not $@) {
        # tengo 0 o mas mensajes
        my $searched_count = scalar @searched;
        if ($searched_count > 0) {
          $searched_total = $searched_total + $searched_count;
          $self->_debug_("IC collect: collected $searched_count message(s)");
          $collected->{$folder} = \(@{$collected->{$folder}} , @searched);
        }
      } else {
        $self->_report_("{colectar}.Error al ejecutar el filtro [$filter] en la bandeja [$folder]");
        $self->_report_("    ERROR:".$self->{imap}->LastError);
        $self->_report_("---");
      }
    } else {
      $self->_debug_("IC collect: failed opening $folder. Not in selected state");
      $self->_report_("{colectar}.Error al examinar la bandeja [$folder]");
      $self->_report_("    ERROR:".$self->{imap}->LastError);
      $self->_report_("---");
    }
  }
  $self->{collected_total} = $searched_total;
  return $searched_total; 
}

# La funcion es encargada de obtener los mensajes. 
# Para ejecutarse usa una estructura propia
# $self->{collected}. Esta estructura tiene que construirse por el 
# metodo collect
# Los mensajes seran enviados via SMTP.
sub send {
  use Net::SMTP;
  use Email::Address;
  my $self = shift;
  return if (! $self->{imap});

  my $smtp = Net::SMTP->new(
    Host => $CONFIG{relay_smtp},
    Port => $CONFIG{relay_port},
    Hello => $CONFIG{relay_smtp}
  );
  if (!$smtp) {
    $self->_debug_("IC send: ERROR can't connect to smtp server $CONFIG{relay_smtp}:$CONFIG{relay_port}");
    #TODO: posiblemente habra que enviar el correo a otro lugar si esto ocurre.
    return;
  }
  if ($self->{collected_total} > 0 ) {
    $self->_debug_("IC send: going to send $self->{collected_total} messages");
    foreach my $folder (keys $self->{collected}) {
      my $res = $self->{imap}->select($folder);
      if ($self->{imap}->IsSelected and $res) {
        my @success_set = ();
        $self->_debug_("IC send: $folder selected");
        foreach my $uid (@{$self->{collected}->{$folder}}) {
          my $message_string = $self->{imap}->message_string($uid);
          if (defined ($message_string)) {
            $self->_debug_("IC send: uid $uid fetched");

            # envio del mensaje via smtp
            my $to_header = $self->{imap}->get_header($uid, "To");
            if ($to_header) {
              # tengo el header to:
              my @parsed_tos = Email::Address->parse($to_header);
              if (scalar(@parsed_tos) > 0) {
                # tengo al menos una direccion que cumple con la RFC2822
                $to_header = $parsed_tos[0]->address;
                $to_header = 'relay-to-archiving-'.$to_header;
                $self->_debug_("IC send: sending uid $uid from:".$CONFIG{contacts}->{ic_mail_from}." to:$to_header");
                $smtp->mail($CONFIG{contacts}->{ic_mail_from});
                $smtp->to($to_header);
                $res = $smtp->data( ($message_string) );
                # fin del envio smtp
                #my $fh = IO::File->new("> /var/tmp/msgs/$uid");
                #print $fh $message_string;
                #$fh->close;
                push(@success_set, $uid);
              } 
            }
          } else {
            $self->_report_("{enviar}.Error leyendo el mensaje uid [$uid] en la bandeja [$folder]");
            $self->_report_("    ERROR:".$self->{imap}->LastError);
            $self->_report_("---");
         }
        }
        $callback = $self->_post_callback_;
        $self->_debug_("IC send: calling callback on @success_set");
        #$callback->($self->{imap}, \@success_set);
      } else {
        $self->_report_("{enviar}.Error al seleccionar la bandeja [$folder]");
        $self->_report_("    ERROR:".$self->{imap}->LastError);
        $self->_report_("---");
      }
    } 
  }
  $smtp->quit;
}

sub DESTROY
{
  my $self = shift;
  $self->_debug_("IC DESTROY: sending disconnect");
  $self->{imap}->disconnect if ($self->{imap});
  $self->{debug_fh}->close;
  #TODO: hacer el envio del reporte si corresponde
  $self->{report_fh}->close;
}

1
