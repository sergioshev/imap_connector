use threads;
use threads::shared;

use test;

sub run {
  my $id = shift;
  my $t = test->new($id);
  $SIG{KILL} = sub {
    threads->exit();
  };

  $t->send();
}

my $thr = threads->create(\&run, 1);
my $thr2 = threads->create(\&run, 2);
$thr->detach();
$thr2->detach();

sleep(20);
print "mando kill a thr1\n";
$thr->kill('KILL');
sleep(15);
print "mando kill a thr2\n";
$thr2->kill('KILL');
sleep(10);

