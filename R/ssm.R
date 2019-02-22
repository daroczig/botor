#' The default, fork-safe AWS Systems Manager (SSM) client on the top of \code{botor}
#' @return \code{botocore.client.SSM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html}
ssm <- function() {
    botor_client('ssm', type = 'client')
}


#' Create an S3 Object reference from an URI
#' @param uri string, URI of an S3 object, should start with \code{s3://}, then bucket name and object key
#' @return \code{s3$Object}
#' @export
ssm_get_parameter <- function(path, decrypt = TRUE) {
    trypy(ssm()$get_parameter(
        Name = path,
        WithDecryption = decrypt)$Parameter$Value)
}
