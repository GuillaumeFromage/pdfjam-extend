pdfjam-extend
=============

Extensions to pdfjam, a okay package to replace pdfdistiller.

Two tools I hacked from scratch (ish) from the basis in pdfjam:
 * pdfgigantify.pl ; it just takes a pdf of a size that isn't 
   exactly the size of a page and pan it on multiple pages, 
   making sure it works with the margins and other stuff ! I
   think it used to work back in the day, I did used it for 
   some projects.
 * pdfmarginalize.pl (probably a assname for a software ; I
   hate being called marginal, so I like using marginalization
   as a verb to blame society): It just add margins around 
   all pages of a pdf file, so say you had some random layout 
   and a printer wanna bound it, then you can just use this to
   magically add margins around the left pages. 
 * fitshit.pl should be about the same thing as gigantify, but
   when I reached for the code of the "marginalizer" (that one
   was a pain to write :D), I found gigantify. I've used 
   fitshit for a couple of project and it worked fine.

All of this is in a pretty broken/works for me state, but 
there is something really fucking nice about being able to
properly print goddamn pdf, and playing around with them.


