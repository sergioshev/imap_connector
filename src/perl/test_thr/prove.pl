use threads;
use threads::shared;

use lib qw(/var/tmp);
use test;

my $t = shared_clone(test->new());

my $c = \&test::set_strong_abort;

my $thr = threads->create(sub { $t->send(); });
$thr->detach();
sleep(15);
$c->($t, 1);
print "ordene abortar\n";
sleep(15);
