.iam <- NULL

#' The default, fork-safe IAM client on the top of \code{botor}
#' @return \code{botocore.client.IAM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html}
iam <- function() {
    if (is.null(.iam) || attr(.iam, 'uuid') != botor_session_uuid()) {
        utils::assignInMyNamespace('.iam', structure(
            botor()$client('iam'),
            uuid = botor_session_uuid()))
    }
    .iam
}
