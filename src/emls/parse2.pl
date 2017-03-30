use Email::MIME;
use Email::Simple;
use Data::Dumper;


my @lines = <STDIN>;

my $message = join("",@lines);



sub filter_jreport_2010 {
  my $message = shift;
  my $header_re = '^X-MS-Journal-Report:';
  if ($message =~ /$header_re/m) {
    my $parsed = Email::MIME->new($message);
    my @parts = $parsed->parts;
    my $attachment = undef;
    my @bcc_set;
    foreach my $part (@parts) {
      my @part_headers = @{$part->{header}->{headers}};
      if (grep /.*message\/rfc822.*/, @part_headers ) {
        $attachment = $part->body_raw;
        my $parsed_embed_message = Email::MIME->new($attachment);
        @bcc_set = $parsed_embed_message->header("bcc");
        if (scalar(@bcc_set) > 0 ) {
           my $mail = Email::Simple->new($attachment);
           $mail->header_set("X-Spamina-Bcc" , @bcc_set);
           return $mail->as_string;
        }
      }
    }
  } 
  return $message;
}


my $filtered_msg = filter_jreport_2010($message);

print $filtered_msg;

