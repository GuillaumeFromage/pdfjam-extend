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

getopt("nEOl:r:t:b:");

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

# print "width = $width\n";
# This is the ugly mathematical part: we calculate which percentage we must 
# chop from each pages which is equal to the (the first one mean 100%) 

# 1 - ((space in inches) * 2 * 72) / (total page # width in pt). 

print $pgNb;

$width2 = $width;
$width2 =~ s/(.*)pt/\1/;

$paperwidth=8.5;
$paperheight=11;

$offX = $marginsize; # that should be double 
$offY = $marginsize*$paperheight/$paperwidth;

print $off;
#print "trimmedwidth = $width\n";
$scale = 1 - ($marginsize * 144) / ($width2);
print "final scale = $scale\n";
# Hack around, but double your \
print TEMP <<EOF;
\\documentclass[$orientation]{article}
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
 -l Left margin
 -r right margin
 -t top margin
 -b bottom margin
 -E even pages only
 -O odd pages only (-EO will do both - its a feature :D)
 -n no-tidy
EOF
	exit(666);
}

