package test;

use Data::Dumper;

sub set_strong_abort {
  my $self = shift;
  my $abort = shift;
  $self->{'strong_abort'} = $abort;
}

sub new {
  my $class = shift;
  my $id = shift;
  my $self = {
    'strong_abort' => 0,
    'id' => $id
  };
  bless $self,$class;
  return $self;
}

sub send {
  my $self = shift;
  while (1) {
    sleep(int(rand(4))+11);
    print "thr_".$self->{'id'}.": mande el correo uid ".int(rand(1000))."\n";
    last if ($self->{'strong_abort'});
  }
  print "thr_".$self->{'id'}."me fui chau!\n";
}

1
