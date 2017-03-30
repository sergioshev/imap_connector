use Imapconnector;
use Data::Dumper;

my $ic = Imapconnector->new(
  'test_ic',
  'imap.gmail.com',
  '993',
  'sergioshev@gmail.com',
  '&f1xt1r3%',
  'ssl',
);

$ic->action('mark_flagged');
#$ic->stick_to('[Gmail]/&BCEEPwQwBDw-');
#$ic->stick_to('INBOX');
my $data = $ic->collect;
print "$data messages\n";
print Dumper($ic->{collected});
#$ic->send;
