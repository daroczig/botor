#' The default, fork-safe KMS client on the top of \code{botor}
#' @return \code{botocore.client.KMS}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kms.html}
kms <- function() {
    botor_client('kms', type = 'client')
}


#' Encrypt plain text via KMS
#' @param key the KMS customer master key identifier as a fully specified Amazon Resource Name (eg \code{arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012}) or an alias with the \code{alias/} prefix (eg \code{alias/foobar})
#' @param text max 4096 bytes long string, eg an RSA key, a database password, or other sensitive customer information
#' @param simplify returns Base64-encoded text instead of raw list
#' @return string or \code{list}
#' @export
#' @seealso \code{\link{kms_decrypt}}
kms_encrypt <- function(key, text, simplify = TRUE) {
    assert_string(key)
    assert_string(text)
    assert_flag(simplify)
    res <- kms()$encrypt(KeyId = key, Plaintext = charToRaw(text))
    if (simplify == TRUE) {
        res <- res$CiphertextBlob
        res <- base64_enc(res)
        res <- coerce_bytes_literals_to_string(res)
    }
    res
}


#' Decrypt cipher into plain text via KMS
#' @param cipher Base64-encoded ciphertext
#' @param simplify returns decrypted plain-text instead of raw list
#' @return decrypted text as string or \code{list}
#' @export
#' @seealso \code{\link{kms_encrypt}}
kms_decrypt <- function(cipher, simplify = TRUE) {
    assert_string(cipher)
    assert_flag(simplify)
    res <- kms()$decrypt(CiphertextBlob = base64_dec(cipher))
    if (simplify == TRUE) {
        res <- res$Plaintext
        res <- coerce_bytes_literals_to_string(res)
    }
    res
}


#' Generate a data encryption key for envelope encryption via KMS
#' @param bytes the required length of the data encryption key in bytes (so provide eg \code{64L} for a 512-bit key)
#' @return \code{list} of the Base64-encoded encrypted version of the data encryption key (to be stored on disk), the \code{raw} object of the encryption key and the KMS customer master key used to generate this object
#' @inheritParams kms_encrypt
#' @export
#' @importFrom checkmate assert_integer
kms_generate_data_key <- function(key, bytes = 64L) {

    assert_string(key)
    assert_integer(bytes)

    data_key <- kms()$generate_data_key(KeyId = key, NumberOfBytes = bytes)

    list(
        cipher = coerce_bytes_literals_to_string(base64_enc(data_key$CiphertextBlob)),
        key    = data_key$KeyId,
        text   = require_python_builtins()$bytearray(data_key$Plaintext))

}


#' Encrypt file via KMS
#' @param file file path
#' @return two files created with \code{enc} (encrypted data) and \code{key} (encrypted key) extensions
#' @inheritParams kms_encrypt
#' @export
#' @seealso \code{\link{kms_encrypt}} \code{\link{kms_decrypt_file}}
#' @importFrom checkmate assert_file_exists
kms_encrypt_file <- function(key, file) {

    assert_string(key)
    assert_file_exists(file)
    if (!requireNamespace('digest', quietly = TRUE)) {
        stop('The digest package is required to encrypt files')
    }

    ## load the file to be encrypted
    msg <- readBin(file, 'raw', n = file.size(file))
    ## the text length must be a multiple of 16 bytes
    ## so let's Base64-encode just in case
    msg <- charToRaw(base64_enc(msg))
    msg <- c(msg, as.raw(rep(as.raw(0), 16 - length(msg) %% 16)))

    ## generate encryption key
    key <- kms_generate_data_key(key, bytes = 32L)

    ## encrypt file using the encryption key
    aes <- digest::AES(key$text, mode = 'ECB')
    writeBin(aes$encrypt(msg), paste0(file, '.enc'))

    ## store encrypted key
    cat(key$cipher, file = paste0(file, '.key'))

    ## return file paths
    list(
        file = file,
        encrypted = paste0(file, '.enc'),
        key = paste0(file, '.key')
    )

}


#' Decrypt file via KMS
#' @param file base file path (without the \code{enc} or \code{key} suffix)
#' @param return where to place the encrypted file (defaults to \code{file})
#' @return decrypted file path
#' @export
#' @seealso \code{\link{kms_encrypt}} \code{\link{kms_encrypt_file}}
kms_decrypt_file <- function(file, return = file) {

    if (!file.exists(paste0(file, '.enc'))) {
        stop(paste('Encrypted file does not exist:', paste0(file, '.enc')))
    }
    if (!file.exists(paste0(file, '.key'))) {
        stop(paste('Encryption key does not exist:', paste0(file, '.key')))
    }
    if (file.exists(return)) {
        stop(paste('Encrypted file already exists:', return))
    }
    if (!requireNamespace('digest', quietly = TRUE)) {
        stop('The digest package is required to encrypt files')
    }

    ## load the encryption key
    key <- charToRaw(kms_decrypt(paste(readLines(paste0(file, '.key'), warn = FALSE), collapse = '')))

    ## load the encrypted file
    msg <- readBin(paste0(file, '.enc'), 'raw', n = file.size(paste0(file, '.enc')))

    ## decrypt the file using the encryption key
    aes <- digest::AES(key, mode = 'ECB')
    msg <- aes$decrypt(msg, raw = TRUE)

    msg <- base64_dec(rawToChar(msg))

    ## Base64-decode and return
    writeBin(msg, return)

    ## return file paths
    return

}
