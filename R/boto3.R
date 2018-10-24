#' Raw access to the boto3 module imported at package load time
#' @note You may rather want to use \code{\link{botor}} instead, that provides a fork-safe \code{boto3} session.
#' @export
boto3 <- NULL


#' boto3 version
#' @return string
#' @export
boto3_version <- function() {
    botor$`__version__`
}
