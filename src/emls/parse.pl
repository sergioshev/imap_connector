use Email::MIME;
use Email::Simple;
use Data::Dumper;

my @lines = <STDIN>;

my $message = join("",@lines);

my $header_re = '^X-MS-Journal-Report:';
my $bcc_re = '^Bcc: .*@.*$';

if ( ($message =~ /$header_re/m) and ($message =~ /$bcc_re/m)) {
  my $parsed = Email::MIME->new($message);
  my @parts = $parsed->parts;
  my $attachment = undef;
  my @bcc_set;
  foreach my $part (@parts) {
    my @part_headers = @{$part->{header}->{headers}};
    if (grep /.*message\/rfc822.*/, @part_headers ) {
      $attachment = $part->body_raw;
    }
    if ( grep /.*text\/plain.*/, @part_headers) {
      my $body = $part->body;
      my @m = $body =~ /^Bcc: (.*)$/mg;
      push (@bcc_set, @m);
    }
  }
  foreach my $bcc (@bcc_set) {
    #print "X-Spamina-Bcc: $bcc\n";
  };

  if ($attachment) {
    my $mail = Email::Simple->new($attachment);
    $mail->header_set("X-Spamina-Bcc" , @bcc_set);
    print $mail->as_string;
  }
}



