# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::ISSN;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $issn = new Business::ISSN('0355-4325');

if($issn->is_valid()) {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}