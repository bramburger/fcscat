% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combinesamples.R
\name{get.filenames}
\alias{get.filenames}
\title{Get filenames and basenames of repeated samples in a folder}
\usage{
get.filenames(path = getwd())
}
\arguments{
\item{path}{The folder where to look for fcs files. By default the
working directory.}
}
\value{
A data.table with two columns: `filename`, which is the
    full filename of each of the fcs files, and `basename` which
    is the part before the sequence of charactes described above.
}
\description{
Searches a folder for fcs files that come from repeated runs of
samples from the same patients and under the same conditions. More
specifically, files should end with the following structure: a
space, a number, an underscore, the position of the sample on the
plate (A-H (or a-h) and two numbers), ".fcs" (or
".FCS"). Everything *before* this sequence is considered the
basename for the series of files and will be used as the filename
for the output files. That is, if a set of samples are called
"Blood 1_C01.fcs" and "Blood 2_C02.fcs", the combined file will be
called "Blood.fcs".
}
