#' The default, fork-safe AWS Systems Manager (SSM) client on the top of \code{botor}
#' @return \code{botocore.client.SSM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html}
ssm <- function() {
    botor_client('ssm', type = 'client')
}


#' Read AWS System Manager's Parameter Store
#' @param path name/path of the key to be read
#' @param decrypt decrypt the value or return the raw ciphertext
#' @return (optionally decrypted) value
#' @export
ssm_get_parameter <- function(path, decrypt = TRUE) {
    log_trace("Looking up %s in AWS System Manager's Parameter Store", path)
    trypy(ssm()$get_parameter(
        Name = path,
        WithDecryption = decrypt)$Parameter$Value)
}

#' The default, fork-safe AWS Systems Manager (SecretManager) client on the top of \code{botor}
#' @return \code{botocore.client.secretsmanager}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html}
sm <- function() {
    botor_client('secretsmanager', type = 'client')
}


#' Read AWS System Manager's Secrets Manager via Parameter Store
#' @param path name/path of the key to be read
#' @param key keyID
#' @param decrypt decrypt the value or return the raw ciphertext
#' @importFrom checkmate assert_string
#' @importFrom jsonlite fromJSON
#' @return (optionally decrypted) value
#' @export
ssm_get_secrets <- function(path, key = NULL, decrypt = TRUE) {
    # Usage: path = your/secretname/keyID
    # or 
    # path = your/seretname, key = keyID
    
    assert_string(path, pattern = "^/aws/reference/secretsmanager/")

    if (is.null(key)) {
        parts <- unlist(strsplit(path, "/"))
        key <- tail(parts, 1)
        path <- paste(parts[1:length(parts) - 1], collapse = "/")
    }

    log_trace("Looking up keyID %s from SecretId %s in AWS Secrets Manager", key, path)
    
    resp <- trypy(ssm()$get_parameter(
                Name = path,
                WithDecryption = decrypt)$Parameter$Value)

    fromJSON(resp)[[key]]
}


#' Read AWS System Manager's Secrets Manager via Secret Manager
#' @param path name/path of the key to be read
#' @param keyinpath logical. Default TRUE
#' @param output_format return format. Either as raw_string or value
#' @importFrom checkmate assert_string assert_logical
#' @importFrom jsonlite fromJSON
#' @return (optionally decrypted) value
#' @export
sm_get_secrets <- function(path, keyinpath = TRUE, output_format = c("raw_string", "value")) {
    match.arg(output_format)
    assert_logical(keyinpath)
    
    if (keyinpath) {
        parts <- unlist(strsplit(path, "/"))
        key <- tail(parts, 1)
        path <- paste(parts[1:length(parts) - 1], collapse = "/")
    }
        
    resp <- trypy(sm()$get_secret_value(
        SecretId = path))$SecretString
    
    log_trace("Looking up SecretId %s in AWS Secrets Manager", path)
    
    if (output_format == "raw_string") {
        resp
    } else if (output_format == "value" & !is.null(key)) {
        fromJSON(resp)[[key]]
    } else {
        stop("Invalid output format or missing key!")
    }

}