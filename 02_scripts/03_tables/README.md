# Article tables

The script `data_description.R` reads
`../00_data_preparation/data.csv` and summarizes the number of trials and
plots by fertilizer origin and measurement method.

Run it from this directory:

```sh
Rscript data_description.R
```

The script writes two supplementary tables to `csv/`:

- `table_A1.csv`: numbers of trials and plots by fertilizer origin and
  measurement method;
- `table_A2.csv`: numbers of trials by measurement method.

Additional summary counts used in the main article are printed in the R
console.
