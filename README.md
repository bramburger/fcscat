# fcscat
Catenate fcs files containing data from the same samples

Combine the data from all sets of fcs files that come from repeated runs of samples from the same patient and under the same conditions, and write a set of combined files to disk. 

When one set of files is combined, this flowFrame is retained in memory so it can be used without having to read it from disk again. When multiple sets of files are combined, these will not automatically be retained in memory.

## Installation

There is only a development version available, which depends on the packages `flowCore`[^1], which is a bioconductor package that can be installed with 

```
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("flowCore")
```

This package can be installed directly from GitHub by

```
remotes::install_github("bramburger/fcscat")
```

After installation, load the library in the usual way:

```
library("fcscat")
```

## Usage

There are only two functions that combine several files containing data from the same sample into one combined file. Additionally, there si a function that searches a folder for files with a particularly structured filename.

### Filename matching

The function `get.filenames()` searches for specifically formatted filenames and creates a data.frame mapping filenames to derived identifiers for the samples (assuming multiple files will map to one sample, and multiple samples can be in the same folder).

The default place this function will search is the working directory, but can be specified like `get.filenames("path/to/folder")`.

Here we assume that all files containing data from one sample are in the same folder. That folder can also contain files with data from other samples. Additionally, we assume the filenames follow a set structure.

```
Sample-identifier Run-identifier_Plate-position.fcs
```

That is, first we have a `Sample-identifier`, which can contain any alphabetical character, number, space, or punctuation.
This is followed by a `space`, a `Run-identifier` which has to be a number, then an underscore `_`, the `Plate-position` which has to be a single character (A-H or a-h) followed by two numbers (e.g. `A01`, `B11`, `H12`), and ends with `.fcs`.

Filenames with the same `Sample-identifier` are assumed to belong together.

Thus, if a folder contains the following files:
```
'Blood 1_0-1 1_C04.fcs'  'Blood 1_10 1_C07.fcs'  'Blood 1_10 four_C10.fcs'
'Blood 1_0-1 2_C05.fcs'  'Blood 1_10 2_C08.fcs'  combine.R
'Blood 1_0-1 3_C06.fcs'  'Blood 1_10 3_C09.fcs'
```

`Blood 1_0-1 1_C04.fcs`, `Blood 1_0-1 2_C05.fcs`, and `Blood 1_0-1 3_C06.fcs` are assumed to belong together to the sample `Blood 1_0-1`, and `Blood 1_10 1_C07.fcs`, `Blood 1_10 2_C08.fcs`, and `Blood 1_10 3_C09.fcs` are assumed to belong together to the sample `Blood 1_10`. Both `Blood 1_10 four_C10.fcs` and `combine.R` are ignored as they do not follow the pattern above.

The output generated is a data.frame with two columns: `filename` and `basename`. `filename` is the name of the file, e.g. `Blood 1_0-1 1_C04.fcs`, and `basename` the `Sample-identifier`, in this example `Blood 1_0-1`.

For the example above the output would be 

```
                   filename        basename
1     Blood 1_0-1 1_C04.fcs     Blood 1_0-1
2     Blood 1_0-1 2_C05.fcs     Blood 1_0-1
3     Blood 1_0-1 3_C06.fcs     Blood 1_0-1
4      Blood 1_10 1_C07.fcs      Blood 1_10
5      Blood 1_10 2_C08.fcs      Blood 1_10
6      Blood 1_10 3_C09.fcs      Blood 1_10
```

### Catenating files belonging to the same sample for all samples in a folder

With the function `combine.all.sets()` one can automatically find files to catenate together in the working directory (this function internally calls `get.filenames()`), and writes the combined files to the working directory.

**Please beware, if an output file already exists it is overwritten without warning.**

If the input files are not in the working directory, this can be specified with the `inpath` parameter (e.g. `combine.all.sets(inpath = "files")`).
Similarly, if the output files are not in the working directory, this can be specified with the `outpath` parameter (e.g. `combine.all.sets(outpath = "combined")`). These can be combined with, e.g. `combine.all.sets(inpath = "files", outpath="files/combined")`.

By default this function internally calls `get.filenames()`. If this does not combine the desired files, the filenames and the new filenames for the combined files can be given explicitly. For example with `combine.all.sets(filenames = mapping)`, where `mapping` is a data.frame with the same structure (column names) as the one that would be created by calling `get.filenames()`.


### Catenating files belonging to the same sample for a single sample

If the folder contains files belonging to only a single sample, or you want to combine just the files belonging to one sample, this can be done with the function `combine.set(filenames, basename)`.
Here `filenames` is a vector of strings containing all the filenames for the files that need to be combined into one (similar to the *column* `filename` in the output of `get.filenames()`), and `basename` is the filename for the output file *without* the trailing ".fcs" (`basename = "combined"` would produce the file `combined.fcs`).

Again, all files are assumed to be in (and written to) the working directory, to specify where the input files are, use the `inpath` parameter, and to specify where the output files are, use the `outpath` parameter.

Thus, with the example above, `combine.set(c("Blood 1_0-1 1_C04.fcs", "Blood 1_0-1 2_C05.fcs", "Blood 1_0-1 3_C06.fcs"), "Blood 1_0-1")` would combine those three files into the one file `Blood 1_0-1.fcs`. This version also returns a `flowFrame` with the combined data.

**Please beware, if the output file already exists it is overwritten without warning.**


[^1]:  Ellis B, Haaland P, Hahne F, Le Meur N, Gopalakrishnan N, Spidlen J, Jiang M, Finak G (2023). flowCore: flowCore: Basic structures for flow cytometry data. R package version 2.12.2.
