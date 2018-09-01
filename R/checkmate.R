#' Check if an argument looks like an S3 bucket
#' @param x string
#' @export
#' @importFrom checkmate makeAssertionFunction makeTestFunction makeExpectationFunction makeAssertion check_string vname
#' @examples \dontrun{
#' check_s3_path('s3://foo/bar')
#' check_s3_path('https://foo/bar')
#' assert_s3_path('https://foo/bar')
#' }
check_s3_path <- function(x) {
    regex <- '^s3://[a-z0-9][a-z0-9\\.-]+[a-z0-9](/(.*)?)?$'
    check <- check_string(x, pattern = regex)
    if (isTRUE(check)) {
        return(TRUE)
    }
    paste('Does not seem to be an S3 path as per regular expression:', shQuote(regex))
}
#' @export
assert_s3_path <- makeAssertionFunction(check_s3_path)
#' @export
test_s3_path   <- makeTestFunction(check_s3_path)
#' @export
expect_s3_path <- makeExpectationFunction(check_s3_path)
