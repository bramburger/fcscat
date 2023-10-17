##' Get filenames and basenames of repeated samples in a folder
##'
##' Searches a folder for fcs files that come from repeated runs of
##' samples from the same patients and under the same conditions. More
##' specifically, files should end with the following structure: a
##' space, a number, an underscore, the position of the sample on the
##' plate (A-H (or a-h) and two numbers), ".fcs" (or
##' ".FCS"). Everything *before* this sequence is considered the
##' basename for the series of files and will be used as the filename
##' for the output files. That is, if a set of samples are called
##' "Blood 1_C01.fcs" and "Blood 2_C02.fcs", the combined file will be
##' called "Blood.fcs".
##'
##' @param path The folder where to look for fcs files. By default the
##'     working directory.
##' @return A data.table with two columns: `filename`, which is the
##'     full filename of each of the fcs files, and `basename` which
##'     is the part before the sequence of charactes described above.
get.filenames <- function(path = getwd()) {
    ## Get all files in working directory
    files <- dir(path)
    ## Create regular expression
    re.basename <- "^(?<basename>[[:alnum:][:space:][:punct:]]*)"
    re.platespace <- " [[:digit:]+]_[A-Ha-h][[:digit:]][[:digit:]].[Ff][Cc][Ss]$"
    re.string <- paste0(re.basename, re.platespace)
    ## Run regular expression
    rex.set <- regexec(re.string, dir(), perl=TRUE)
    ## Return full file names and base names in a data.table
    data.table::rbindlist(lapply(regmatches(dir(), rex.set), function (x) {
        if(length(x) > 0)
            list(filename = x[1], basename = x[2])
    }))
}

##' Combine the data from a set of fcs files into one combined file
##'
##' Combine the data from a set of fcs files that come from repeated
##' runs of samples from the same patient and under the same
##' conditions, and write a combined file to disk. Only the combined
##' flowFrame is kept in memory after writing the combined flowFrame
##' to disk. During this process all the combined data *plus* the data
##' from the last file needs to fit into memory.
##'
##' @param filenames A character vector containing filenames for each
##'     of the fcs files to combine. This is the order in which the
##'     data will be written to the combined fcs file.
##' @param basename The filename of the new fcs file, without ".fcs"
##' @param inpath The folder/directory where the fcs files are located
##' @param outpath The folder/directory where the combined fcs file
##'     will be written to
##' @return This function returns a flowFrame with the combined data.
combine.set <- function (filenames, basename,
                         inpath = getwd(), outpath = getwd()) {
    ## Read the first file in the set of files that belong together
    first <- 
        flowCore::read.FCS(file.path(inpath, filenames[1]),
                           transformation=FALSE,
                           alter.names=FALSE,
                           truncate_max_range=FALSE)

    ## Combine the data from the different flowFrames into
    ## the `exprs` slot of the first one
    ## One file after another
    for (i in seq(2, length(filenames))) {
        exprs(first) <-
            rbind(exprs(first),
                  exprs(flowCore::read.FCS(file.path(inpath, filenames[i]),
                                           transformation=FALSE,
                                           alter.names=FALSE,
                                           truncate_max_range=FALSE)))
    }
    
    ## Change the filename descriptors
    ## (which should be the only metadata we have to fix?)
    filename.slots <- c("$FIL", "GUID", "FILENAME",
                        "ORIGINALGUID", "GUID.original")
    for (kw in filename.slots) {
        if (keyword(first, kw) == filenames[1]) {
            keyword(first)[[kw]] <- paste0(basename, ".fcs")
        }
    }

    ## Check that output folder exists, otherwise create it
    if (!dir.exists(outpath))
        dir.create(outpath)

    ## Write the combined flowFrame to file
    write.FCS(first, file.path(outpath, paste0(basename, ".fcs")))
    first
}

##' Combine the data from all sets of fcs files into combined files
##'
##' Combine the data from all sets of fcs files that come from
##' repeated runs of samples from the same patient and under the same
##' conditions, and write a set of combined files to disk. Neither the
##' flowSet, nor the combined flowFrame for any of the sets are kept
##' in memory after writing the combined flowFrame to disk, though all
##' the data for a single set needs to be kept in memory to combine
##' it.
##'
##' When specifying \code{returnFlowSet = TRUE}, the combined data
##' sets are read back from disk and returned as a flowSet.
##'
##' The most simple usage would be simply as combine.all.sets(), to
##' automatically combine files in the current working directory. This
##' is equivalent to combine.all.sets(filenames=get.filenames()). To
##' do the same in another folder, one can do
##' e.g. combine.all.sets(path="../fcsFiles/"), which is equivalent
##' again to combine.all.sets(path="../fcsFiles/",
##' filenames=get.filenames(path="../fcsFiles/")).
##'
##' To be able to know which files belong to each other, this function
##' either calls `get.filenames`, or (if \code{!is.null(filenames)})
##' relies on a data.frame which maps filenames to basenames. This
##' data.frame needs two columns, one called `filename`, and another
##' `basename`, where each row contains the name of the file in
##' `filename`, and the name of the set it belongs to in `basename`;
##' all the files with the same `basename` will be combined into one
##' file `basename.fcs`. For an example, see the output of
##' `get.filenames`, when each file in a directory ends with something
##' like ` 1_C04.fcs`, that is a space, a number, an underscore, the
##' place on a plate and ".fcs" to indicate the n-th (here 1st) sample
##' in a set. See the help for `get.filenames` for more details.
##'
##' @param inpath The folder/directory where the fcs files are located
##'     (Defaults to the working directory)
##' @param outpath The folder/directory where the combined fcs file
##'     will be written to (Defaults to the working directory)
##' @param filenames Either NULL (the default), to automatically guess
##'     which files contain repeatedly measured samples and belong to
##'     each other. Otherwise it should be a data.frame which maps
##'     filenames to basenames. This data.frame needs two columns, one
##'     called `filename`, and another `basename`, where each row
##'     contains the name of the file in `filename`, and the name of
##'     the set it belongs to in `basename`; all the files with the
##'     same `basename` will be combined into one file `basename.fcs`.
##' @param returnFlowSet Specify whether the combined data sets should
##'     be returned as a flowSet. (Default = FALSE)
##' @return With returnFlowSet = TRUE this function returns a flowSet
##'     of the just created combined files. Otherwise this function
##'     does not return anything. In both cases a set of fcs files is
##'     created, combining the events from several files with the same
##'     basename. Existing files with that name will be overwritten
##'     without warning.
combine.all.sets <- function (inpath = getwd(),
                              outpath = getwd(),
                              filenames = NULL,
                              returnFlowSet = FALSE) {
    if (is.null(filenames))
        filenames <- get.filenames(inpath)
    ## for every set of files we want to combine
    for (bname in unique(filenames$basename)) {
        fileset <- filenames[filenames$basename == bname, ]$filename
        combine.set(fileset, bname, inpath, outpath)
        gc()
    }
    if (returnFlowSet) {
        return(read.flowSet(files=paste0(unique(filenames$basename),
                                         ".fcs"),
                            path=outpath,
                            alter.names=FALSE,
                            transformation=FALSE,
                            truncate_max_range=FALSE))
    }
}
