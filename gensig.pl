#!/usr/bin/perl

use Getopt::Long;

sub usage() {
  print "$0 [[--signature=32]] [[--no-flip]] [[--folds=2]] --nbpg 32\n";
  print <<EOF
  Generate signatures ; eg: page number in the right order for books after being folded. 
  We start in the upper right corner of the first page and move in that order. Say for
  a bifolded 8 page zine, it would say: "4f 5f 8 1 3f 6f 2 7". 

  It assumes xerox config, eg: when landscape paper is used, it assumes that paper is
  flipped on the short side, hence, single fold signatures of a 4 pages zine is 4 1 2 3
  and not 4 1 2f 3f.
 
  It is designed to be called by software that does the work for you. Please contribute
  to this project, or ask me what the hell you're trying to do if you're that far down
  the hole.

EOF
;
  exit 0;
}

my $nbpg = 0;
my $signature = 0;
my $folds = 0;

GetOptions ('nbpg=s' => \$nbpg, 'signature=s' => \$signature, 'folds=s' => \$folds  ) or usage();

if ($nbpg eq '') { 
   usage();
}

# default to 1 fold
if ($folds eq '') {
   $folds = 1;
}

# yeah, we only do up to three folds
if ($folds < 1 or $folds >= 4) {
  print "this software only does single fold\n";
  exit 1;
}

# if the signature isn't defined, set it to current nbpg
if ($signature eq '') {
  $signature = $nbpg;
}

# we need to warn if the signature size do

