#' The default, fork-safe Kinesis client on the top of \code{botor}
#' @return \code{botocore.client.Kinesis}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html}
kinesis <- function() {
    botor_client('kinesis', type = 'client')
}


#' Describes the specified Kinesis data stream
#' @param stream the name of the stream to describe
#' @export
#' @return list
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.describe_stream}
kinesis_describe_stream <- function(stream) {
    kinesis()$describe_stream(StreamName = stream)
}


#' Writes a single data record into an Amazon Kinesis data stream
#' @inheritParams kinesis_describe_stream
#' @param data the data blob (<1 MB) to put into the record, which is base64-encoded when the blob is serialized
#' @param partition_key Unicode string with a maximum length limit of 256 characters determining which shard in the stream the data record is assigned to
#' @export
#' @return list of \code{ShardId}, \code{SequenceNumber} and \code{EncryptionType}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.put_record}
kinesis_put_record <- function(stream, data, partition_key) {
    kinesis()$put_record(StreamName = stream, Data = data, PartitionKey = partition_key)
}
