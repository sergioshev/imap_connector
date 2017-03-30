use Imapconnector;
use Data::Dumper;

my $ic = Imapconnector->new(
  '92.54.22.41',
  '443',
  'domain.devel.spamina.net\admintmp',
  'Adm3ntmp2014',
  'tls',
);

$ic->action('mark_flagged');
$ic->stick_to('INBOX');
my $data = $ic->collect;
print "$data messages\n";
print Dumper($ic->{collected});
$ic->send;
