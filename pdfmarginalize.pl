#!/usr/bin/perl
#
# THIS IS LICENSED UNDER  GPL YOU CORPORATE SCUM ! IF MODIFY THIS YOU MUST
# DISTRIBUTE IT ! IF SOME FUCKS ON THE INTERNET LIKES RUSTY SPOONS, THERE
# MIGHT BE SOME OTHERS LIKING RUSTY KNIVES !
#
# http://www.gnu.org/licenses/gpl-3.0.html
#
# Copyright Guillaume Beaulieu 2008-2013
# 
# A lot inspired of David Firth's psnup
#
# The documentation for the pdfpages packages that basically
# http://mirrors.ctan.org/macros/latex/contrib/pdfpages/pdfpages.pdf
# 
use Getopt::Std;

$frame=0;            ## do not print a thin border around pages
$fitpaper="true";          ## alternatives are other LaTeX paper sizes
$pages="-";
$turn=0;              ## landscape pages are landscape-oriented
$noautoscale=0;      ## scale logical pages to fit
$column=0;           ## don't use column-major ordering
$columnstrict=0;     ## (see the pdfpages manual)
$scale=1.0;              ## don't scale the resultant pages
$openright=0;        ## don't insert blank page at front of document
$tidy=1;              ## delete all temporary files immediately
$randomLatexFile="punksnotdead.latex";
$pdflatex="pdflatex";
$tempfileDir="/var/tmp"; ## /var/tmp is standard on many unix systems

getopts("nLRl:r:t:b:");
if ((scalar @ARGV) == 0) {
	print "must have at least an input file ... \n\n\n";
	help();
}

$infile = shift;
$outfile = shift;
getPdfInfo();
$msgFile="$msgFile.msg";

open TEMP, "> $tempfileDir/$randomLatexFile";

$marginsize=0.25;
# the tolerance for users margins that dont fit quite right
$tolerance = 0.05;

# fuck this point bullshit
$width2 = $width;
$width2 =~ s/(.*)pt/\1/;
$width = $width2/72;
$height2 = $height;
$height2 =~ s/(.*)pt/\1/;
$height = $height2/72;

if (($opt_l + $opt_r)/$width >= ($opt_t + $opt_b)/$height) {
  # so, if we're shrinking more on the horizontal than on the vertical

  # This is the ugly mathematical part: we calculate which percentage we must 
  # chop from each pages which is equal to the (the first one mean 100%) 
  # 1 - ((space in inches) * 72) / (total page # width in pt). 
  $marginsize = $opt_l + $opt_r;
  $scale = 1 - ($marginsize) / ($width);

  # print "marginsize = $marginsize ; opt_l = $opt_l ; opt_r = $opt_r ;\n";
  # in case of epic debug :D
  # print "final scale = $scale\n";
  
  # then we calculate the offsets
  $offX = $opt_l - $marginsize / 2; # Its easy ; draw a picture to understand !

  # $offY is tricky, because by default its centered (like the one above)
  # and is scaled to a factor that isn't the margins on the side. If no margins
  # are specified, then we just keep it centered, if there is either a top or a
  # bottom margin, we set it from that distance from that location. If there is
  # both, we're just fucked as we're dealing with floating point crap, and we
  # can't really figure out which margins to use.
  if (!$opt_t && !$opt_b) {
    # this works
    $offY = 0;
  } elsif($opt_t && !$opt_b) {
    # this almost works for small values of t
    $Ymargins = (1 - $scale) * $height;
    print "Ymargins = $Ymargins\n";
    $offY =  (1-$scale)*$height/2 - $opt_t;
    # print "$offY = (1-$scale)*$height/2 - $opt_t";
  } elsif(!$opt_t && $opt_b) {
    # this is likely to be as busted as above
    $offY = $opt_b - (1-$scale)*$height/2;
  } elsif((($opt_l + $opt_r)/$width == ($opt_t + $opt_b)/$height)) {
    # I wouldn't trust my weight on those maths.

    # okay, the margins actually fit so we just use either 
    $offY = $opt_b - $marginsize*$height/$width;
  } elsif((($opt_l + $opt_r)/$width - ($opt_t + $opt_b)/$height)*$height > -$tolerance &&
    (($opt_l + $opt_r)/$width - ($opt_t + $opt_b)/$height)*$height < $tolerance) {
    # I didn't actually got to test that as the shit above was busted

    # okay, the margins "sorta" fit so we just use either and warn
    $difference = $opt_b - (($opt_l + $opt_r)/$width - ($opt_t + $opt_b)/$height)*$height;
    $offY = $marginsize*$height/$width - $opt_t;
    print <<WARN;
    Motherfucker ! You specified a top, a bottom and margins on the side. 
    We're trying to keep the aspect ratio and the margins you specified
    aren't exactly even (they can't be, its floating point number, blah blah), 
    so we used the top margin and the bottom margin you specified will be off
    by $difference.
WARN
  } else {
    # This actually seems to work

    # okay, if we're here the user is just fucking with us, die horribly 
    print <<ERROR;
    Motherfucker ! You specified a top, a bottom and margins on the side. 
    We're trying to keep the aspect ratio and the margins you specified
    are just too wrong to be dealt with. BTW, fuck you.
ERROR
    die(665);
  }
} else {
  # left as a exercise to the user. Or just tell the user to use pdf90. Or 
  # just reverse the dimensions or something. This is annoying maths after
  # all !
}


# set a few options in the document style, see
# http://www.latex-community.org/forum/viewtopic.php?f=5&t=1076
if ($opt_L) {
  $sides = "twoside,openleft";
} elsif ($opt_R) {
  $sides = "twoside,openright";
} else {
  $sides = "oneside";
}

#print "trimmedwidth = $width\n";
# Hack around, but double your \
print TEMP <<EOF;
\\documentclass[$sides,$orientation]{article}
\\usepackage[left=0in,right=0in,top=0in,bottom=0in,dvips]{geometry}
\\geometry{papersize={$width,$height}}
\\usepackage{pdfpages}
\\begin{document}
EOF

if ($opt_O || $opt_E) {
  # if we touch only odd or oven pages
  print TEMP <<EOF;
\\includepdf[fitpaper=$fitpaper, scale=$scale, offset=${offX}in ${offY}in]{$infile}
EOF
} else {
  print TEMP <<EOF;
\\includepdf[fitpaper=$fitpaper,pages=-, scale=$scale, offset=${offX}in ${offY}in]{$infile}
EOF
}
 
print TEMP <<EOF;
\\thispagestyle{empty}
\\end{document}
EOF

close TEMP;
print "Calling pdflatex...\n";

$curdir = $ENV{"PWD"};
`cp $uniqueName.pdf $tempfileDir`;
chdir $tempfileDir;
`$pdflatex --interaction batchmode $randomLatexFile > $msgFile`;
chdir $curdir;
if ($opt_n) {
	print $tempfileDir;
}
if (-f "$tempfileDir/$uniqueName.scaled.aux") {  
	## ie if LaTeX didn't choke
	if (not($outfile eq "")) {
		`mv $tempfileDir/$uniqueName.scaled.pdf $outfile`;
		print "  Finished: output is $outfile\n";
	} else {
		`mv $tempfileDir/$uniqueName.scaled.pdf .`;
		print "  Finished: output is $uniqueName.scaled.pdf\n";
	}
#	`rm $tempfileDir/$uniqueName*`;
} else {
	print "  Failed: output file not written";
}

sub getPdfInfo {
	($uniqueName,)=split /\./, $infile;
	$randomLatexFile="$uniqueName.scaled.latex";
	if (!$opt_q) {print "Temporary LaTeX file for this job is $randomLatexFile\n";}
	# Get the pdf info
	open VACHIER, "pdfinfo $infile | grep Pages | cut -d: -f2 |";
	$pgNb = <VACHIER>;
	# trim the fucking whitespace
	chop $pgNb;
	$pgNb =~ s/\s//g;
	close VACHIER;
	# OK, now we have the number of pages to grab, grab now the paper size
	open VACHIER, "pdfinfo $infile | grep \"Page size\" | cut -d: -f2 |";
	$size = <VACHIER>;
	# separate the stuff
	($width, $heightandunit) = split / x /, $size;
	($height, $unit) = split / /, $heightandunit;
	# trim the whitespace
	chop $unit;
	$width =~ s/\s//g;
	# This part will flake at some point (EG: whenever unit isn't fucking point ?) 
	if ($unit eq "pts") {
		$unit = "pt";
	}
	$width = "$width$unit";
	$height = "$height$unit";
}
sub help {
	print <<EOF;
pdfmarginalize 0.01

This software adds margins around a pdf file

pdfbook Options infile.pdf [outfile.pdf]
Options:
 -l Left margin (inner, in inches, like all other dimensions below)
 -r right margin (outer)
 -t top margin
 -b bottom margin
 -L two sided the document is assumed to open on a left page
 -R two sided, the document is assumed to open on a right page
 -n no-tidy

There's some shit I don't understand with getopt, use -- to separate the files from the arguments
EOF
	exit(666);
}

