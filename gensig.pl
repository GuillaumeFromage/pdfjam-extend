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

  It uses B for blank pages. However, by default, it uses the number of page submitted
  as the signature size, so you'll get an error instead of blank pages if you don't 
  specify the signature size when you have a number of pages non-divisible by 2 to the
  power of (the number of folds+1).
 
  It is designed to be called by software that does the work for you. Please contribute
  to this project, or ask me what the hell you're trying to do if you're that far down
  the hole. 

EOF
;
  exit 0;
}

my $nbpg = 0;
my $signature = 0;
my $folds = 1;

GetOptions ('nbpg=s' => \$nbpg, 'signature=s' => \$signature, 'folds=s' => \$folds  ) or usage();

if ($nbpg eq '') { 
   usage();
}

# default to 1 fold
if ($folds eq '') {
   $folds = 1;
}

# yeah, we only do up to three folds
if ($folds <= 0 or $folds >= 3) {
  print "this software only does single or double fold (eg: 12, 16 and 16 oblong pages signature are not yet supported)\n";
  exit 1;
}

# if the signature isn't defined, set it to current nbpg
if ($signature eq '') {
  $signature = $nbpg;
}

# we need to warn if the signature size doesn't match the # of folds
# (we need to have multiple of 4 pages for single fold, multiple of
# 8 for dual fold, etc)
if ($signature % 2**($folds+1)) {
  print "Signature size incorrect.\nMore help is available if you invoke this program without argument\n";
  exit 2;
}
my $output = '';
# for each spread 
for (my $i = 0; $i < $nbpg/2**($folds+1) ; $i++) {
  #print "spread $i\n";
  # for each individual page in the spread
  for (my $j = 0; $j < 2**($folds+1) ; $j++) {
    #print "page $j\n";
    if ($folds == 1) {
      if ($j == 0 or $j == 3) {
         $output .= $nbpg - $i * ($folds + 1) - $j % ($folds + 1). " ";
      } else {
         $output .= $j + $i * ($folds + 1) . " ";
      }
    }
  }
}

print "$output\n";
