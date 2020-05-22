#' The default, fork-safe AWS Systems Manager (SecretManager) client on the top of \code{botor}
#' @return \code{botocore.client.secretsmanager}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html}
sm <- function() {
  botor_client('secretsmanager', type = 'client')
}


#' Read AWS System Manager's Secrets Manager via Secret Manager
#' @param path name/path of the key to be read
#' @param key single key or a vector of keys. 
#' @param parse_json logical. Default TRUE
#' @importFrom checkmate assert_vector assert_logical
#' @importFrom jsonlite fromJSON
#' @importFrom logger log_warn
#' @return (optionally decrypted) value
#' @export
sm_get_secret <- function(path, key = NULL, parse_json = TRUE) {
  assert_logical(parse_json)
  assert_vector(key, null.ok = TRUE)

  if (!is.null(key) && parse_json == FALSE) {
    stop('Key(s) must be provided if parse_json = TRUE')
  }

  log_trace("Looking up SecretId %s in AWS Secrets Manager", path)

  resp <- trypy(sm()$get_secret_value(SecretId = path))$SecretString

  if (parse_json) {
    resp <- fromJSON(resp)[[key]]
    if (is.null(resp)) log_warn("Key %s does not exist", key)
    resp
  } else {
    resp
  }
}
