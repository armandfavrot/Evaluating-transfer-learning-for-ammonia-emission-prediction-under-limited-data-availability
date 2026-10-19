# TikZ figures

Each figure has its own directory and `Makefile`. To compile a figure, run
`make` from its directory, for example:

```bash
cd fig_2
make
```

The PDF is created both in the figure directory and in `../../pdf/`. The
figures are compiled with `pdflatex`.

To remove the auxiliary `.aux` and `.log` files while keeping the PDFs, run:

```bash
make clean
```
