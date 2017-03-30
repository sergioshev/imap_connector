use threads;
use threads::shared;

use test;

sub run {
  my $tid = threads->tid();

  $SIG{KILL} = sub {
    print STDOUT "tid $tid killed\n";
    threads->exit();
  };

  while (1) {
    my $a = $tid;
  }
}

while (1) {
  my $thr = threads->create(\&run);
  for (my $i = 1 ; $i < 90000; $i++) {
    my $b = $i;
  }
  $thr->kill('KILL')->detach();
}

