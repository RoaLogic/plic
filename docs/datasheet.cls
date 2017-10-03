%define new document type
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{datasheet}[2017/10/01 Roa Logic Datasheet Class]
\LoadClass[a4paper]{article} % Inherit std article class
\usepackage[utf8]{inputenc}
\usepackage[english]{babel}

% Load Roalogic Title Page Generator
\usepackage{roalogictitle}

% Define Roa Logic Colour Scheme
\RequirePackage[table]{xcolor}
\newcommand{\headlinecolor}{\normalcolor}
\definecolor{rlsection}{HTML}{3D5986}
\definecolor{rlsubsection}{HTML}{5B80B8}
\definecolor{rltable}{HTML}{D5DFED}

% Load packages
\usepackage{lmodern} % Font Library
\usepackage{amssymb,amsmath} % Math Fonts
\usepackage{ifxetex,ifluatex}
\usepackage{graphicx,grffile} % Graphics support
\usepackage{longtable} % Long table supprot
\usepackage{vmargin} % Margin control  
\usepackage{tabularx} % Table support

\usepackage{booktabs} % For \toprule, \midrule and \bottomrule
\usepackage{csvsimple} % Import CSV files

\usepackage{layout} % Show summary of page layout
\usepackage{hyperref} % Hyperlink support
    
\usepackage{titlesec} %Headings Syliser

\usepackage{fancyhdr} % Header & Footer control
\pagestyle{fancy}

% Page Layout Control

% Paragraph formatting
\setlength{\parindent}{0.5em}
\setlength{\parskip}{0.5em}

% Long table formatting
\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}                  
\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}                        
\newcolumntype{R}[1]{>{\raggedleft\arraybackslash}p{#1}}

% Hyperlink formatting
\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    filecolor=magenta,      
    urlcolor=blue,
}
 
\urlstyle{same}


% Font & Colour control
\renewcommand{\familydefault}{\rmdefault}
 
\DeclareOption{green}{\renewcommand{\headlinecolor}{\color{green}}}
\DeclareOption{blue}{\renewcommand{\headlinecolor}{\color{rlcolor}}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

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

% Table Numbering
\makeatletter
\renewcommand{\thetable}{\thesection.\@arabic\c@table}
\@addtoreset{table}{section}
\makeatother

% Figure Numbering
\usepackage{amsmath}
\numberwithin{figure}{section}

