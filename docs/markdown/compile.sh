#!/bin/bash

./lpp.pl ../tex/preamble.tex      > preamble.tex
./lpp.pl ../tex/setup.tex         > setup.tex
./lpp.pl ../tex/configuration.tex > configuration.tex
./lpp.pl ../tex/introduction.tex  > introduction.tex
./lpp.pl ../tex/history.tex       > history.tex
./lpp.pl ../tex/interfaces.tex    > interfaces.tex
./lpp.pl ../tex/references.tex    > references.tex
./lpp.pl ../tex/resources.tex     > resources.tex
./lpp.pl ../tex/setup.tex         > setup.tex
./lpp.pl ../tex/specification.tex > specification.tex

pandoc --default-image-extension=png -t markdown_github -B frontmatter -o ../../DATASHEET.md "AHB-Lite_PLIC_Markdown.tex"

#echo '---' > /tmp/frontmatter
#echo 'Title: PLIC Datasheet' >> /tmp/frontmatter
#echo '---' >> /tmp/frontmatter
#cat ../DATASHEET.md >> /tmp/frontmatter
#cp /tmp/frontmatter ../DATASHEET.md
