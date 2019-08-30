library(botor)
library(testthat)

context('s3')

test_that('load data from s3', {
    expect_true(s3_exists('s3://botor/example-data/mtcars.csv'))
    expect_error(s3_read('s3://botor/example-data/mtcars.csv', read.csv), NA)
})
