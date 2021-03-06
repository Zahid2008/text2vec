context("hash-corpus construction")

train_ind = 1:1000

txt = movie_review[['review']][train_ind]
tokens = txt %>% tolower %>% word_tokenizer
it = itoken(tokens, progressbar = F)

test_that("Unigram Hash Corpus construction", {
  h_size = 2 ^ 14;

  vectorizer = hash_vectorizer(hash_size = h_size)
  m = create_dtm(it, vectorizer)

  expect_equal( dim(m)[[1]], length(train_ind))
  expect_equal( dim(m)[[2]], h_size)
  expect_equal( length(m@x), 140790L)

  # fit = glmnet::cv.glmnet(x = m, y = movie_review[['sentiment']][train_ind],
  #                          family = 'binomial',
  #                          type.measure = "auc",
  #                          nfolds = 4)
  # expect_gt(max(fit$cvm), 0.8)
})

test_that("trigram hash-corpus construction", {
  h_size = 2 ^ 18;

  vectorizer = hash_vectorizer(hash_size = h_size, ngram = c(1L, 3L))
  # m = create_dtm(get_test_iterator(), vectorizer)
  m = create_dtm(it, vectorizer)

  expect_equal( dim(m)[[1]], length(train_ind))
  expect_equal( dim(m)[[2]], h_size)
  expect_equal( length(m@x), 599667L)
})
