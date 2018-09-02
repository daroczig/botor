#' Check if an argument looks like an S3 bucket
#' @param x string, URI of an S3 object, should start with \code{s3://}, then bucket name and object key
#' @export
#' @importFrom checkmate makeAssertionFunction makeTestFunction makeExpectationFunction makeAssertion check_string vname
#' @examples \dontrun{
#' check_s3_path('s3://foo/bar')
#' check_s3_path('https://foo/bar')
#' assert_s3_path('https://foo/bar')
#' }
check_s3_uri <- function(x) {
    regex <- '^s3://[a-z0-9][a-z0-9\\.-]+[a-z0-9](/(.*)?)?$'
    check <- check_string(x, pattern = regex)
    if (isTRUE(check)) {
        return(TRUE)
    }
    paste('Does not seem to be an S3 URI as per regular expression:', shQuote(regex))
}
#' @export
assert_s3_uri <- makeAssertionFunction(check_s3_uri)
#' @export
test_s3_uri   <- makeTestFunction(check_s3_uri)
#' @export
expect_s3_uri <- makeExpectationFunction(check_s3_uri)
