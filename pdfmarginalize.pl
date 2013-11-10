#!/usr/bin/perl
#
# THIS IS LICENSED UNDER  GPL YOU CORPORATE SCUM ! IF MODIFY THIS YOU MUST
# DISTRIBUTE IT ! 
#
# http://www.gnu.org/licenses/gpl-3.0.html
#
# Copyright Guillaume Beaulieu 2008
# 
# A lot inspired of David Firth's psnup
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

getopt("lrh");

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

$width2 = $width;
$width2 =~ s/(.*)pt/\1/;

#print "trimmedwidth = $width\n";
$scale = 1 - ($marginsize * 144) / ($width2);
print "final scale = $scale\n";
# Hack around, but double your \
print TEMP <<EOF;
\\documentclass[$orientation]{article}
\\usepackage[vcentering,dvips]{geometry}
\\geometry{papersize={$width,$height}}
\\usepackage{pdfpages}
\\begin{document}
\\includepdf[fitpaper=$fitpaper,pages=-, scale=$scale]{$infile}
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
-sXX : XX being the number of pages per signatures.
-q : ask this software to shut up
-b : insert a blank page at the beginning of the document
EOF
	exit(666);
}

