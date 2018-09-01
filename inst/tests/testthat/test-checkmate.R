library(botor)
library(testthat)

context('custom checkmate extensions')
test_that('S3 path', {
    expect_true(check_s3_path('s3://foobar'))
    expect_true(check_s3_path('s3://34foobar'))
    expect_error(assert_s3_path('foobar'))
    expect_error(assert_s3_path('https://foobar'))
    expect_error(assert_s3_path('s3://..foobar'))
})
