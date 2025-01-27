
# Analysis of Central Bank Speeches

> [!NOTE]
> This is a work in progress.

This repository documents the analysis of central bank speeches,
obtained from [Bank for International Settlements (BIS) Central Bankers'
Speeches](https://www.bis.org/cbspeeches/index.htm?m=60). The rendered
documentation files can be viewed
[here](https://adamoshen.github.io/cbspeeches/).

## Installing dependencies

First download or clone this repository and then activate the .Rproj
file.

To install all dependencies required to replicate the analysis:

``` r
# install.packages("pak")
pak::local_install_deps()
```

To install all dependencies required to replicate the analysis and
compile documentation:

``` r
# install.packages("pak")
pak::local_install_dev_deps()
```

## Data stats

|Member             |G7 |G10 |G20 |    #|First date |Last date  |
|:------------------|:--|:---|:---|----:|:----------|:----------|
|Argentina          |─  |─   |✔   |   34|2004-09-24 |2023-07-05 |
|Australia          |─  |─   |✔   |  547|1997-02-11 |2023-12-14 |
|Belgium            |─  |✔   |─   |   36|2000-05-12 |2022-11-08 |
|Brazil             |─  |─   |✔   |   11|1999-01-26 |2015-06-10 |
|Canada             |✔  |✔   |✔   |  484|1997-03-06 |2024-02-01 |
|China              |─  |─   |✔   |  142|1996-09-10 |2023-11-28 |
|France             |✔  |✔   |✔   |  444|1996-12-17 |2023-09-15 |
|Germany            |✔  |✔   |✔   |  809|1996-12-28 |2024-01-31 |
|India              |─  |─   |✔   |  910|1996-12-28 |2024-01-24 |
|Indonesia          |─  |─   |✔   |   65|1999-02-04 |2022-11-30 |
|Italy              |✔  |✔   |✔   |  391|1997-01-25 |2024-01-26 |
|Japan              |✔  |✔   |✔   |  753|1996-11-06 |2023-12-25 |
|Korea, Republic of |─  |─   |✔   |   94|1998-10-08 |2023-06-20 |
|Mexico             |─  |─   |✔   |   95|2003-04-04 |2023-01-27 |
|Netherlands        |─  |✔   |─   |  200|1997-04-16 |2023-12-05 |
|Other_ECB          |─  |─   |✔   | 2535|1997-03-03 |2024-01-17 |
|Russian Federation |─  |─   |✔   |   39|2007-06-04 |2021-12-17 |
|Saudi Arabia       |─  |─   |✔   |   28|2006-05-06 |2014-09-25 |
|South Africa       |─  |─   |✔   |  402|1997-02-18 |2023-12-01 |
|Sweden             |─  |✔   |─   |  492|1987-08-29 |2023-12-20 |
|Switzerland        |─  |✔   |─   |  404|1998-03-09 |2023-12-14 |
|Turkiye            |─  |─   |✔   |   98|1997-04-03 |2023-07-27 |
|United Kingdom     |✔  |✔   |✔   |  861|1996-12-16 |2023-12-19 |
|United States      |✔  |✔   |✔   | 2296|1996-12-19 |2024-02-02 |
