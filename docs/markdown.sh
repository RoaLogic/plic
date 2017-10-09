#!/bin/sh

./lpp.pl tex/preamble.tex      > build/preamble.tex
./lpp.pl tex/setup.tex         > build/setup.tex
./lpp.pl tex/configuration.tex > build/configuration.tex
./lpp.pl tex/introduction.tex  > build/introduction.tex
./lpp.pl tex/history.tex       > build/history.tex
./lpp.pl tex/interfaces.tex    > build/interfaces.tex
./lpp.pl tex/references.tex    > build/references.tex
./lpp.pl tex/resources.tex     > build/resources.tex
./lpp.pl tex/setup.tex         > build/setup.tex
./lpp.pl tex/specification.tex > build/specification.tex

pandoc --default-image-extension=png -t markdown_github -o ../DATASHEET.md "AHB-Lite_PLIC_Markdown.tex"
