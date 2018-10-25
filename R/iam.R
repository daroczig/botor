#' The default, fork-safe IAM client on the top of \code{botor}
#' @return \code{botocore.client.IAM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html}
iam <- function() {
    botor_client('iam', type = 'client')
}


#' Get the current AWS username
#' @return string
#' @export
iam_whoami <- function() {
    iam()$get_user()$User$UserName
}
