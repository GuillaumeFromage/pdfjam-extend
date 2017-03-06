#!/usr/bin/perl

use Cwd;
use Getopt::Long;
use File::Copy;

sub usage() {
  print "$0 [--booked] [--split-horizontally] [--duplicated-vertically] [--verbose] --file=patate.pdf";
  print <<EOF
--booked   rearrange the page as they were bound in signature (by default, signatures
           are assumed to be half of the document page)
--split-{horizontally|vertically} the document is split (in half by default) on the
                                  specified axis.
--duplicated-{horizontally|vertically} the document is duplicated (in half by 
                                       default) on the specified axis.
--verbose is obvious
--file  the file.

The output will be patate-unbooked.pdf ; the pages will be singular and in their 
original order.

Not all options specified are currently implemented.
           

EOF
;
  exit 0;
}

GetOptions ('booked' => \$booked, 'split-horizontally' => \$splitVert, 'duplicated-vertically' => \$dupVert, 'verbose' => \$verbose, 'file=s' => \$file) or usage();

if ($file eq '') {
  usage();
}

my $pdfinfo = 'pdfinfo';

my $nbPage = `$pdfinfo "$file" | grep Pages | cut -d ':' -f 2 | tr -d ' '`;
my %units = ("pts", 0.013836);
my $info = `$pdfinfo "$file" | grep 'Page size:' | cut -d ':' -f 2`;
(my $width, my $height, my $unit) = ($info =~ /\s*(\d+)\s{1}x\s{1}(\d+)\s*(\w+)/);

print "Document is $width by $height in $unit and has $nbPage\n";

# Step 0::
#
# Let's see in which directions the pages are laid
#
my $iterDir = 'hori';

if ($splitVert) {
  my $iterDir = 'verti';
  my $iterOffset = $width / 2;
} 
# we'd need to code in case we want to split horizontally


# Step 0.1::
#
# Let's see if part of the pages are junk
#
my $selectHeight = $height;
my $selectWidth = $width;

if ($dupVert) {
  $selectHeight = $height / 2;
}

# Step 0.2::
#
# Let's initialize some shit 
#
my $currentDir = &Cwd::cwd();
my $tempfileDir='/var/tmp';   #  /var/tmp is standard on most unix systems

my $temp_dir = ($tempfileDir . '/fitshit-' . int(rand() *10000000));
while ( -e $temp_dir) {
	$temp_dir = $tempfileDir . '/fitshit-' . int(rand() *10000000);
	print "You're not lucky";
}

# File moving
mkdir($temp_dir) or die("Can't create temporary directory for file processing\n");
copy($file, $temp_dir) or die("Can't copy file to temporary directory");
chdir($temp_dir);
	


# Step 1
# 
# Split all the pages
#
for (my $i ; $i<$nbPage ; $i++) {
   my $futurePageNumber = $i*2-1;
   `pdfjoin "$file" $i -o "$file$futurePageNumber.pdf"`;
}

# lets just not worry about the args, and assume its split horizontally and dupped vertically


# first


#patate.pdf contient genre 2 pages par page, genre page 1 pi 2 sur la page 1, page 3 pi 4 sur la page 2
#pdfinfo patate.pdf
# ca vous donne le nombre de page ($NBPG) pi la taille ($SIZE)
#for i in $(seq 1 $NBPG) ; do pdfjoin brochure-anticap_final.pdf $i -o page$(echo $i*2-1 | bc).pdf; done



# vv Ca, c'est si on rasterize, ca arrive qu'on aille pas le choix de prendre le pdf tel quel...

# ca sépare toute les pages en pdf d'une page (de deux pages)
#for i in $(seq 1 $NBPG) ; do convert -density 300 page$(echo $i*2-1 | bc).pdf -units PixelsPerInch -resample 300 -crop $UNFUCKEDSIZE +repage +adjoin page$(echo $i*2-1 | bc)-%d.png; done
# ici, vous avez calculé $UNFUCKEDSIZE  à partir de la taille de la page 
# (en pts, crisse de formats de vidange 'méricaine, c'est 1/72ème de pouce, 
# unfuckedsize est en pixel, fake multiplié par 300 (parce qu'on a resamplé 
# à 300dpi)), pi ca splitte un pdf en plus petit boutte. 
#
# C'te commande là, c'est quand même de la bombe, parce que ca démonte un pdf
# en boutte toute égal, sauf que, si t'a chié dans ta commande ou t'as mal
# arrondi, ca va te sortir genre 3 pages, avec la dernière qui est la 
# dernière slice de 3 pixel. Ca vaut la peine itou de checker si les deux 
# morceaux que ca chie en png sont de la même taille en pixel, parce que ca
# se peux que le deuxième est plus mince si le premier est plus gros.
#A=0; for i in $(ls -t *png) ; do A=$(echo $A+1 | bc); mv $i page-$(echo $NBPG-$A|bc).png ; done
# ca icitte, ca marche, mais c'est wizard en sale, en faisant ls -t, ca sort
# les fichiers dans l'ordre qui se sont fait vomir par la commande précédente,
# fake comme on itérait dans le bon ordre des pages, ca "marche" ; mais on
# "inverse" l'ordre en commençant de la fin
#for i in $(ls -t page*png) ; do convert $i $(echo $(echo $i | cut -d '.' -f 1)).pdf ; done
# icitte on reconverti toute la shit en pdf
#A= ; for i in $(ls -t page-*pdf) ; do A=$A echo -n "$i " ; done ; pdfjoin $A
# pi on crisse tout ca d'un tapon !
