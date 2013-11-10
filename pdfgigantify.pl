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

$width2 = $width;
$width2 =~ s/(.*)pt/\1/;
$input_width = $width2 / 72;

$height2 = $height;
$height2 =~ s/(.*)pt/\1/;
$input_height = $height2 / 72;

$output_width = 8.5;
$output_height = 11;

$gigantifyx = $input_width / $output_width;
$gigantifyy = $input_height / $output_height;

if ($gigantifyx > $gigantifyy) {
	$gigantify = $gigantifyx;
} else {
	$gigantify = $gigantifyy;
}
$gigantify = int($gigantify) + 1;
# print "width = $width\n";
# In this one, there is no evil mathematical part: we just multiply and move

$deltax = $output_width;
$offsetx = $input_width / 2;
$deltay = $output_height;
$offsety = $input_height / 2 - 4;



for ($i = 0; $i < $gigantify; $i++) {
	$top = ($gigantify - $i - 1) * $deltay - $offsety;
	push(@top_offset_array, "-$top"."in");
	$right = ($i) * $deltax - $offsetx;
	push(@right_offset_array, "-$right"."in");
}

#print "trimmedwidth = $width\n";
#$scale = 1 - ($marginsize * 144) / ($width2);
# Hack around, but double your \
$output_height .= "in";
$output_width .= "in";
print TEMP <<EOF;
\\documentclass[$orientation]{article}
\\usepackage[vcentering,dvips]{geometry}
\\geometry{papersize={$output_width,$output_height}}
\\usepackage{pdfpages}
\\begin{document}
EOF
foreach $top (@top_offset_array) {
	foreach $right (@right_offset_array) {
		print TEMP "\\includepdf[offset= $right $top, pages=-, scale=$gigantify]{$infile}\n\n";
	}
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
	# This part will flake at some point 
	if ($unit eq "pts") {
		$unit = "pt";
	}
	$width = "$width$unit";
	$height = "$height$unit";
}
sub help {
	print <<EOF;
pdfmarginalize 0.01

This software just rearrange pdf document pages into signatures.

pdfbook Options infile.pdf [outfile.pdf]
Options:
-sXX : XX being the number of pages per signatures.
-q : ask this software to shut up
-b : insert a blank page at the beginning of the document
EOF
	exit(666);
}

