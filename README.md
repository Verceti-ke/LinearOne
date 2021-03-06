#   LinearOne

:copyright: 2015-2019 [CNRS](http://www.cnrs.fr)

:copyright: 2015-2019 Richard Moot (@RichardMoot)

This research has received financial support from the ANR CONTINT, project POLYMNIE (ANR-12-CORD-0004). 

LinearOne is a prototype theorem prover/parser for first-order (multiplicative, intuitionistic) linear logic. It also supports (by translation) parsing of hybrid type-logical grammars and Displacement calculus grammars.

LinearOne is provided under the GNU Lesser General Public License (see the included file LICENSE for details).

LinearOne is a set of SWI Prolog files, which optional graph output to LuaLaTeX (using the TikZ 3.0.0 graph drawing libraries) and proof output to LaTeX/pdfLaTeX/luaLaTeX.

#  Quick start

### Starting Prolog

After downloading, enter the LinearOne directory and type.

```
swipl    # (or the name of SWI Prolog on your system)
```

This will start SWI Prolog.

### Loading the source and the grammars

In SWI Prolog, type

```
[mill1,d_grammar].
```

to load the library files and the example Displacement calculus grammar, there is a hybrid type-logical grammar available as well.

```
[hybrid_grammar].
```

### Parsing

To try one of the examples in either grammar, use

```
test(1).   % (check the grammar files to see the available examples).
```

You can also use

```
parse([john,ate,more,donuts,than,mary,bought,bagels], s).
```

to directly parse a sentence. Check the lexicon and experiment a bit with the grammars yourself.

### Viewing the output

When a parse is found, it is output to the file `latex_proofs.tex` and a pdf file `latex_proofs.pdf` is automatically produced. View `latex_proofs.pdf` with your favorite previewer. You will probably need to zoom in for larger proofs.

# Troubleshooting


### No LaTeX output is produced!

Make sure that you have write permissions in the LinearOne directory and that Prolog can find your LaTeX installation. To find the location of pdflatex type the following in a shell terminal

```
where pdflatex
```

Add the required path to the file `mill1.pl`. For example, the path `/usr/texbin/` is added as follows.

```
user:file_search_path(path, '/usr/texbin/').
```

It is also possible that LaTeX aborts with an error (verify the file `latex_proofs.tex`).

### The proofs don't fit the page!

The `geometry/1` predicate in the file `latex.pl` can be modified to the desired page size. Comment out all but the desired page size (or add your own preferred page size). Zooming will be necessary!

### I don't see any graph output

Graph output is optional. In the file mill1.pl, comment out the line

```
  use_module(portray_graph_none,...)
```

and remove the comments from line

```
  use_module(portray_graph_tikz,...)
```

Also make sure your LaTeX installation includes lualatex and Tikz 3.0.0 or later (that is, you need a 2014 or later LaTeX installation).
