
use Net::SMTP ;
use Data::Dumper;

@LISTA= ( 'To: sergioshev@gmail.com'."\r\n".
          'From: hcurti@fio.unicen.edu.ar'."\r\n".
          'Message-Id: Pindonga'."\r\n".
          'Date: Thu, 17 Apr 2012 20:04:51 -0300'."\r\n".
          'Subject: Prueba de Net::SMTP'."\r\n\r\n".
          'Hola esto es una prueba. Chau.'."\r\n" ) ;

$smtp = Net::SMTP->new(
  Host => 'localhost',
  Hello => 'vm1',
  Port => '2525'
) ;

my $res = $smtp->mail( 'hcurti@exa.unicen.edu.ar' ) ;
my $code = $smtp->code();
print "mail code = $code\n";
print "res ".Dumper($res)."\n";

$res = $smtp->to( 'sergioshev@gmail.com' ) ;
my $code = $smtp->code();
print "to code = $code\n";
print "res ".Dumper($res)."\n";

$res = $smtp->data( @LISTA ) ;
my $code = $smtp->code();
print "data code = $code\n";
print "res ".Dumper($res)."\n";

$smtp->quit;
