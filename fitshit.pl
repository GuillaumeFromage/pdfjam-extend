#!/usr/bin/perl

use warnings;
use strict;
use File::Copy;
use Cwd;
my $pdfinfo='pdfinfo';
my $pdflatex='pdflatex';
#TODO: Check if those exists

# File processing
my $file = 'tableausynthèse.pdf'; # file to cut
my $currentDir = &Cwd::cwd();
my $tempfileDir='/home/assoupis/projets!/clac/get';   #  /var/tmp is standard on most unix systems

my $temp_dir = ($tempfileDir . '/fitshit-' . int(rand() *10000000));
while ( -e $temp_dir) {
	$temp_dir = $tempfileDir . '/fitshit-' . int(rand() *10000000);
	print "You're not lucky";
}

# File moving
mkdir($temp_dir) or die("Can't create temporary directory for file processing\n");
copy($file, $temp_dir) or die("Can't copy file to temporary directory");
chdir($temp_dir);
	
# All sizes in inches
# All dimensions starts by width then height
my %margin = ("left", 0.5, "top", 0.5); # margins, in inches
my $fit_on = 'any'; # at the moment only any is supported. It will find the best fitting paper.
my $res = 144; # as this is a hack we convert the file to a bitmap ; this is the final res
my $direction = 'any'; # paper direction ; lanscape or portrait or any (any will find best fit)
my %units = ("pts", 0.013836);

# Feel free to add all paper sizes supported by yer printer
# Usually similar ratio paper will lead to similar square inchage ;
# but the printing margins are fixed on a printer no matter how
# wide the paper is.
my $papers = {'letter' => {"width" => 8.5, "height" => 11},
'ledger' => {"width" => 11, "height" => 17},
'legal' => {"width" => 8.5, "height" => 14}};

my $info = `$pdfinfo $file | grep 'Page size:' | cut -d ':' -f 2`;

(my $width, my $height, my $unit) = ($info =~ /\s*(\d+)\s{1}x\s{1}(\d+)\s*(\w+)/);
print "$width by $height in $unit\n";

# Fitting paper
# Iwidth = Initial file width 
my $Iwidth = $width * $units{$unit};
my $minimalSetup = {};
my $Iheight = $height * $units{$unit};
if ($fit_on eq 'any') { # if we fit on any paper
	my $minimalSIAmount = 999999;
	foreach my $value (sort keys %$papers) { # we try 'em all
		my $thispaper = $papers->{$value};
		my $Pwidth = $thispaper->{"width"} - 2 * $margin{"left"}; 
		my $Pheight = $thispaper->{"height"} - 2 * $margin{"top"}; 
		my $paperSI = $Pheight * $Pwidth; # find their Squareinchage
		my $portraitSheetsW = int($Iwidth / $Pwidth) + (($Iwidth%$Pwidth>0)?1:0); # and the numbers we'd need to fit on
		my $portraitSheetsH = int($Iheight / $Pheight) + (($Iheight%$Pheight>0)?1:0); # the source in each directions 
		my $landscapeSheetsW = int($Iwidth / $Pheight) + (($Iwidth%$Pheight>0)?1:0);
		my $landscapeSheetsH = int($Iheight / $Pwidth) + (($Iheight%$Pwidth>0)?1:0); 
		print "so with paper " . $value . " we'd use " . $portraitSheetsW . " by " .
			$portraitSheetsH . " in portrait mode, or " . $landscapeSheetsW . " by ".
			$landscapeSheetsH . "in lanscape mode... TotalSI Landscape=".$landscapeSheetsW * $landscapeSheetsH * $paperSI.
			" TotalSI Portrait=" . $portraitSheetsW * $portraitSheetsH * $paperSI . "\n\n";
		if ($portraitSheetsW * $portraitSheetsH * $paperSI < $minimalSIAmount) {	# so we weight sort
			$minimalSetup = {"paper" => $value, "direction" => "portrait", "numW" => $portraitSheetsW, "numH" => $portraitSheetsH};
			$minimalSIAmount = $portraitSheetsW * $portraitSheetsH * $paperSI;
		}
		if ($landscapeSheetsW * $landscapeSheetsH * $paperSI < $minimalSIAmount) {	# so we weight sort
			$minimalSetup = {"paper" => $value, "direction" => "landscape", "numW" => $landscapeSheetsW, "numH" => $landscapeSheetsH};
;
			$minimalSIAmount = $landscapeSheetsW * $landscapeSheetsH * $paperSI;
		}
	}
}
# Maths to pass to ImageMagick
print "So we'll got with " . $minimalSetup->{"paper"} . " paper in";		
print $minimalSetup->{"direction"} . " direction\n";
my $outputSizeWidth = my $outputSizeHeight = 0;
my $paper = $papers->{$minimalSetup->{"paper"}};
if ($minimalSetup->{"direction"} eq "portrait") {
	$outputSizeWidth = $paper->{"width"};
	$outputSizeHeight = $paper->{"height"};
}
if ($minimalSetup->{"direction"} eq "landscape") {
	$outputSizeWidth = $paper->{"height"};
	$outputSizeHeight = $paper->{"width"};
}
print "That means that it will be $outputSizeWidth by $outputSizeHeight\n";
my $Pwidth = $a->{"width"};
my $Pheight = $a->{"height"};
print "in inches: " . $Iwidth . " by " . $Iheight . " ... \n";
$direction = $minimalSetup->{"direction"};
$width = ($outputSizeWidth - (2 * $margin{"left"})) * $res;
$height = ($outputSizeHeight - (2 * $margin{"top"})) * $res;
my $size = ($width) . 'x' . ($height);
print "convert $file -units PixelsPerInch -resample $res -crop $size +repage +adjoin \"fichier_%d.pdf\"";
`convert $file -units PixelsPerInch -resample $res -crop $size +repage +adjoin \"fichier_%d.pdf\"`;

my $pdfjoinofdeath = "";
for(my $y = 0 ; $y < $minimalSetup->{"numH"} ; $y++) { # unecessary, but more visual way to code
	for(my $x = 0 ; $x < $minimalSetup->{"numW"} ; $x++) {
		$pdfjoinofdeath .= "fichier_" . ($x + $y * $minimalSetup->{"numW"}) . ".pdf,";
	}
}

$pdfjoinofdeath .= '-';
my $output = "\\batchmode
\\documentclass[$paper,$direction]{article}
\\usepackage[utf8]{inputenc}
\\usepackage{pdfpages}
\\usepackage[left=" . $margin{"left"} . "in,bottom=" . $margin{"top"} ." in,top=" . $margin{"top"} . "in,right=" . $margin{"left"} . "in,nohead,nofoot]{geometry}
\\begin{document}
";

$output .=  "\\includepdfmerge[offset=0in 0in,fitpaper=false, noautoscale=true, rotateoversize=false]{$pdfjoinofdeath}
\\end{document}
";

print "puking filexxx.latex \n";
open (OUTFILE, '>>filexxx.latex');
print OUTFILE $output;
close OUTFILE;

`pdflatex filexxx.latex`;
copy($temp_dir . '/filexxx.pdf', $currentDir) or die("Can't copy file to temporary directory");
exit(0);
