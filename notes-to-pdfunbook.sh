#!/bin/sh
#patate.pdf contient genre 2 pages par page, genre page 1 pi 2 sur la page 1, page 3 pi 4 sur la page 2
pdfinfo patate.pdf
# ca vous donne le nombre de page ($NBPG) pi la taille ($SIZE)
for i in $(seq 1 $NBPG) ; do pdfjoin brochure-anticap_final.pdf $i -o page$(echo $i*2-1 | bc).pdf; done
# ca sépare toute les pages en pdf d'une page (de deux pages)
for i in $(seq 1 $NBPG) ; do convert -density 300 page$(echo $i*2-1 | bc).pdf -units PixelsPerInch -resample 300 -crop $UNFUCKEDSIZE +repage +adjoin page$(echo $i*2-1 | bc)-%d.png; done
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
A=0; for i in $(ls -t *png) ; do A=$(echo $A+1 | bc); mv $i page-$(echo $NBPG-$A|bc).png ; done
# ca icitte, ca marche, mais c'est wizard en sale, en faisant ls -t, ca sort
# les fichiers dans l'ordre qui se sont fait vomir par la commande précédente,
# fake comme on itérait dans le bon ordre des pages, ca "marche" ; mais on
# "inverse" l'ordre en commençant de la fin
for i in $(ls -t page*png) ; do convert $i $(echo $(echo $i | cut -d '.' -f 1)).pdf ; done
# icitte on reconverti toute la shit en pdf
A= ; for i in $(ls -t page-*pdf) ; do A=$A echo -n "$i " ; done ; pdfjoin $A
# pi on crisse tout ca d'un tapon !
