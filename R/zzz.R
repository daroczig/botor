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

    ## options('reticulate.traceback' = FALSE)

}
