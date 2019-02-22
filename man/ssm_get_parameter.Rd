% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ssm.R
\name{ssm_get_parameter}
\alias{ssm_get_parameter}
\title{Create an S3 Object reference from an URI}
\usage{
ssm_get_parameter(path, decrypt = TRUE)
}
\arguments{
\item{uri}{string, URI of an S3 object, should start with \code{s3://}, then bucket name and object key}
}
\value{
\code{s3$Object}
}
\description{
Create an S3 Object reference from an URI
}