\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{datasheet}[2017/10/01 Roa Logic Datasheet Class]

\LoadClass[a4paper]{article}

\usepackage{roalogictitle}

\newcommand{\headlinecolor}{\normalcolor}
\RequirePackage[table]{xcolor}
\definecolor{rlsection}{HTML}{3D5986}
\definecolor{rlsubsection}{HTML}{5B80B8}
\definecolor{rltable}{HTML}{D5DFED}

\usepackage[utf8]{inputenc}
\usepackage[english]{babel}
\usepackage{lmodern}
\usepackage{amssymb,amsmath}
\usepackage{ifxetex,ifluatex}
\usepackage{graphicx,grffile}
\usepackage{longtable}
\usepackage{vmargin}   
\usepackage{tabularx}

\usepackage{booktabs} % For \toprule, \midrule and \bottomrule
\usepackage{csvsimple}

\usepackage{layout}
\usepackage{hyperref}
    
\usepackage{titlesec}

\usepackage{fancyhdr}
\pagestyle{fancy}

\setlength{\parindent}{0.5em}
\setlength{\parskip}{0.5em}

\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}                  
\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}                        
\newcolumntype{R}[1]{>{\raggedleft\arraybackslash}p{#1}}

\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    filecolor=magenta,      
    urlcolor=blue,
}
 
\urlstyle{same}


\renewcommand{\familydefault}{\rmdefault}
 
\DeclareOption{green}{\renewcommand{\headlinecolor}{\color{green}}}
\DeclareOption{blue}{\renewcommand{\headlinecolor}{\color{rlcolor}}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
 


%\titleformat{\section}
%{\color{rlcolor}\sffamily\huge\bfseries}
%{\color{rlcolor}\thesection}{1em}{\hrule}

\titleformat{\section}
  {\color{rlsection}\sffamily\Huge\bfseries}{\thesection}{1em}{}[{\titlerule[0.8pt]}]

\titleformat{\subsection}
  {\color{rlsubsection}\sffamily\LARGE\bfseries}{\thesubsection}{1em}{}
  
\titleformat{\subsubsection}
  {\color{rlsubsection}\sffamily\large\bfseries}{\thesubsubsection}{1em}{}
  
\titlespacing*{\chapter}     {0pt}{50pt}{40pt}
\titlespacing*{\section}     {0pt}{3.5ex plus 1ex minus .2ex}{2.3ex plus .2ex}
\titlespacing*{\subsection}   {0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
\titlespacing*{\subsubsection}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
\titlespacing*{\paragraph}   {0pt}{3.25ex plus 1ex minus .2ex}{1em}
\titlespacing*{\subparagraph} {\parindent}{3.25ex plus 1ex minus .2ex}{1em}

\makeatletter
\renewcommand{\thetable}{\thesection.\@arabic\c@table}
\@addtoreset{table}{section}
\makeatother

\usepackage{amsmath}
\numberwithin{figure}{section}

 
%\let\oldlongtable\longtable
%\let\endoldlongtable\endlongtable
%\renewenvironment{longtable}{\rowcolors{2}{rltable}{white}\oldlongtable} {
%\endoldlongtable}


% \renewcommand{\normalsize}{\fontsize{9}{10}\selectfont}

% \setcounter{secnumdepth}{0}



