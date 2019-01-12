clients <- new.env()
python_builtins <- NULL

.onLoad <- function(libname, pkgname) {

    utils::assignInMyNamespace(
        'boto3',
        reticulate::import(
            module = 'boto3',
            delay_load = list(
                on_error = function(e) stop(e$message)
            )))
    utils::assignInMyNamespace(
        'python_builtins',
        reticulate::import_builtins())

    ## although glue would be more convenient,
    ## but let's use the always available sprintf formatter function for logging
    logger::log_formatter(logger::formatter_sprintf, namespace = pkgname)
    logger::log_threshold(logger::DEBUG, namespace = pkgname)

    ## options('reticulate.traceback' = FALSE)

}
