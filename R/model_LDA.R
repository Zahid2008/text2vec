# // Copyright (C) 2015 - 2017  Dmitriy Selivanov
# // This file is part of text2vec
# //
#   // text2vec is free software: you can redistribute it and/or modify it
# // under the terms of the GNU General Public License as published by
# // the Free Software Foundation, either version 2 of the License, or
# // (at your option) any later version.
# //
#   // text2vec is distributed in the hope that it will be useful, but
# // WITHOUT ANY WARRANTY; without even the implied warranty of
# // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# // GNU General Public License for more details.
# //
#   // You should have received a copy of the GNU General Public License
# // along with text2vec.  If not, see <http://www.gnu.org/licenses/>.

#' @name LatentDirichletAllocation
#' @title Creates Latent Dirichlet Allocation model.
#' @description Creates Latent Dirichlet Allocation model.
#'  At the moment only 'WarpLDA' is implemented.
#'  WarpLDA, an LDA sampler which achieves both the best O(1) time
#'  complexity per token and the best O(K) scope of random access.
#'  Our empirical results in a wide range of testing conditions demonstrate that
#'  WarpLDA is consistently 5-15x faster than the state-of-the-art Metropolis-Hastings
#'  based LightLDA, and is comparable or faster than the sparsity aware F+LDA.
#' @section Usage:
#' For usage details see \bold{Methods, Arguments and Examples} sections.
#' \preformatted{
#' lda = LDA$new(n_topics = 10L, doc_topic_prior = 50 / n_topics, topic_word_prior = 1 / n_topics, verbose = FALSE)
#' lda$fit_transform(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 10, progress = interactive())
#' lda$transform(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 5, progress = FALSE)
#' lda$get_top_words(n = 10, topic_number = 1L:private$n_topics, lambda = 1)
#' }
#' @field verbose \code{logical = FALSE} whether to display more information about internal routines.
#' @field topic_word_distribution distribution of words for each topic. Available after model fitting with
#' \code{model$fit()} or \code{model$fit_transform()} methods.
#' @field doc_topic_distribution distribution of topics for each document. Available after model fitting with
#' \code{model$fit()} or \code{model$fit_transform()} methods.
#' @field components word counts for each topic-word entry. Available after model fitting with
#' \code{model$fit()} or \code{model$fit_transform()} methods.
#' @section Methods:
#' \describe{
#'   \item{\code{$new(n_topics,
#'               doc_topic_prior = 50 / n_topics, # alpha
#'               topic_word_prior = 1 / n_topics, # beta
#'               verbose = FALSE, method = "WarpLDA")}}{Constructor for LDA model.
#'               For description of arguments see \bold{Arguments} section.}
#'   \item{\code{$fit(x, n_iter, convergence_tol = -1,
#'                n_check_convergence = 10)}}{fit LDA model to input matrix \code{x}. Not that useful -
#'                \code{fit_transform} is used under the hood. Implemented just to follow API.}
#'   \item{\code{$fit_transform(x, n_iter, convergence_tol = -1,
#'                n_check_convergence = 0, progress = interactive())}}{fit LDA model to input matrix
#'                \code{x} and transforms input documents to topic space -
#'                model input matrix as a distribution over topic space}
#'   \item{\code{$transform(x, n_iter, convergence_tol = -1,
#'                n_check_convergence = 0, progress = FALSE)}}{ transforms new documents to topic space -
#'                model input matrix as a distribution over topic space}
#'   \item{\code{$get_top_words(n = 10, topic_number = 1L:private$n_topics, lambda = 1)}}{returns "top words"
#'                for a given topic (or several topics). Words for each topic can be
#'                sorted by probability of chance to observe word in a given topic (\code{lambda = 1}) and by
#'                "relevance" wich also takes into account frequency of word in corpus (\code{lambda < 1}).
#'                From our experience in most cases setting \code{ 0.2 < lambda < 0.4} works well.
#'                See \url{http://nlp.stanford.edu/events/illvi2014/papers/sievert-illvi2014.pdf} for details.}
#'   \item{\code{$plot(...)}}{plot LDA model using \url{https://cran.r-project.org/package=LDAvis} package.
#'                \code{...} will be passed to \code{LDAvis::createJSON} and \code{LDAvis::serVis} functions}
#'}
#' @section Arguments:
#' \describe{
#'  \item{lda}{A \code{LDA} object}
#'  \item{x}{An input document-term matrix. \bold{CSR \code{RsparseMatrix} used internally}}.
#'  Should have column names.
#'  \item{n_topics}{\code{integer} desired number of latent topics. Also knows as \bold{K}}
#'  \item{doc_topic_prior}{\code{numeric} prior for document-topic multinomial distribution.
#'    Also knows as \bold{alpha}}
#'  \item{topic_word_prior}{\code{numeric} prior for topic-word multinomial distribution.
#'    Also knows as \bold{eta}}
#'  \item{n_iter}{\code{integer} number of sampling iterations}
#'  \item{n_check_convergence}{ defines how often calculate score to check convergence }
#'  \item{convergence_tol}{{\code{numeric = -1} defines early stopping strategy. We stop fitting
#'     when one of two following conditions will be satisfied: (a) we have used
#'     all iterations, or (b) \code{score_previous_check / score_current < 1 + convergence_tol}}}
#' }
#' @format \code{\link{R6Class}} object.
#' @examples
#' library(text2vec)
#' data("movie_review")
#' N = 500
#' tokens = movie_review$review[1:N] %>% tolower %>% word_tokenizer
#' it = itoken(tokens, ids = movie_review$id[1:N])
#' v = create_vocabulary(it) %>%
#'   prune_vocabulary(term_count_min = 5, doc_proportion_max = 0.2)
#' dtm = create_dtm(it, vocab_vectorizer(v))
#' lda_model = LDA$new(n_topics = 10)
#' doc_topic_distr = lda_model$fit_transform(dtm, n_iter = 20)
#' # run LDAvis visualisation if needed (make sure LDAvis package installed)
#' # lda_model$plot()
#' @export
LatentDirichletAllocation = R6::R6Class(
  classname = c("WarpLDA", "LDA"),
  inherit = mlDecomposition,
  public = list(
    #----------------------------------------------------------------------------
    # members
    verbose = NULL,
    #----------------------------------------------------------------------------
    # methods

    # constructor
    initialize = function(n_topics = 10L,
                          doc_topic_prior = 50 / n_topics,
                          topic_word_prior = 1 / n_topics,
                          verbose = FALSE) {

      self$verbose  = verbose

      private$set_internal_matrix_formats(sparse = "RsparseMatrix")

      private$n_topics = n_topics
      private$doc_topic_prior = doc_topic_prior
      private$topic_word_prior = topic_word_prior

      private$ptr = warplda_create(n = private$n_topics,
                                   doc_topic_prior = private$doc_topic_prior,
                                   topic_word_prior = private$topic_word_prior)

    },
    #---------------------------------------------------------------------------------------------
    fit_transform = function(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 10,
                             progress = interactive(), ...) {
      stopifnot(is.logical(progress))

      private$ptr = warplda_create(n = private$n_topics,
                                   doc_topic_prior = private$doc_topic_prior,
                                   topic_word_prior = private$topic_word_prior)

      # init internal C++ data structures for document-term matrix
      private$init_model_dtm(x, private$ptr)
      # init
      private$vocabulary = colnames(x)

      private$doc_topic_count =
        private$fit_transform_internal(private$ptr, n_iter = n_iter,
                                       convergence_tol = convergence_tol,
                                       n_check_convergence = n_check_convergence,
                                       update_topics = TRUE, progress = progress)

      # got topic word count distribution
      private$components_ = private$get_topic_word_count()

      # doc_topic_distr = self$get_doc_topic_distribution()
      doc_topic_distr = self$doc_topic_distribution
      attributes(doc_topic_distr) = attributes(private$doc_topic_count)
      rownames(doc_topic_distr) = rownames(x)
      doc_topic_distr
    },
    #---------------------------------------------------------------------------------------------
    # not that useful - just to follow API
    fit = function(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 10,
                   progress = interactive(), ...) {
      invisible(self$fit_transform(x = x, n_iter = n_iter, convergence_tol = convergence_tol,
                                   n_check_convergence = n_check_convergence, progress = progress))
    },
    #---------------------------------------------------------------------------------------------
    transform = function(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 5,
                         progress = FALSE, ...) {
      # create model for inferenct (we have to init internal C++ data structures for document-term matrix)
      inference_model_ptr = warplda_create(n = private$n_topics,
                                           doc_topic_prior = private$doc_topic_prior,
                                           topic_word_prior = private$topic_word_prior)

      private$init_model_dtm(x, inference_model_ptr)

      stopifnot(all.equal(colnames(x), private$vocabulary))

      warplda_set_topic_word_count(inference_model_ptr, self$components);

      doc_topic_count =
        private$fit_transform_internal(inference_model_ptr, n_iter = n_iter,
                                       convergence_tol = convergence_tol,
                                       n_check_convergence = n_check_convergence,
                                       update_topics = 0L, progress = progress)
      # add priors and normalize to get distribution
      doc_topic_distr = (doc_topic_count + private$doc_topic_prior) %>% text2vec::normalize("l1")
      attributes(doc_topic_distr) = attributes(doc_topic_count)
      rownames(doc_topic_distr) = rownames(x)
      doc_topic_distr
    },
    # FIXME - depreciated
    get_word_vectors = function() {.Deprecated("model$components")},

    get_top_words = function(n = 10, topic_number = 1L:private$n_topics, lambda = 1) {

      stopifnot(topic_number %in% seq_len(private$n_topics))
      stopifnot(lambda >= 0 && lambda <= 1)
      stopifnot(n >= 1 && n <= length(private$vocabulary ))

      topic_word_distribution = self$topic_word_distribution
      # re-weight by frequency of word in corpus
      # http://nlp.stanford.edu/events/illvi2014/papers/sievert-illvi2014.pdf
      topic_word_freq =
        lambda * log(topic_word_distribution) +
        (1 - lambda) * log(t(t(topic_word_distribution) /  (colSums(self$components) / sum(self$components)) ))

      lapply(topic_number, function(tn) {
        word_by_freq = sort(topic_word_freq[tn, ], decreasing = TRUE, method = "radix")
        names(word_by_freq)[seq_len(n)]
      }) %>% do.call(cbind, .)
    },
    #---------------------------------------------------------------------------------------------
    plot = function(...) {
      if("LDAvis" %in% rownames(installed.packages())) {
        if (!is.null(self$components)) {

          json = LDAvis::createJSON(phi = self$topic_word_distribution,
                                    theta = self$doc_topic_distribution,
                                    doc.length = rowSums(private$doc_topic_count),
                                    vocab = private$vocabulary,
                                    term.frequency = colSums(self$components),
                                    ...)
          # LDAvis::serVis(json, ...)
          text2vec_serVis(json, ...)
        } else {
          stop("Model was not fitted, please fit it first...")
        }
      } else
        stop("To use visualisation, please install 'LDAvis' package first.")
    }
  ),
  active = list(
    # make components read only via active bindings
    #---------------------------------------------------------------------------------------------
    topic_word_distribution = function(value) {
      if (!missing(value)) stop("Sorry this is a read-only field")
      # self$components is topic word count
      else (self$components + private$topic_word_prior) %>% normalize("l1")
    },
    #---------------------------------------------------------------------------------------------
    doc_topic_distribution = function(value) {
      if (!missing(value)) stop("Sorry this is a read-only field")
      if (is.null(private$doc_topic_count)) stop("LDA model was not fitted yet!")
      else (private$doc_topic_count + private$doc_topic_prior) %>% normalize("l1")
    },
    components = function(value) {
      if (!missing(value)) stop("Sorry this is a read-only field")
      else {
        if(is.null(private$components_)) stop("LDA model was not fitted yet!")
        else private$components_
      }
    }
  ),
  private = list(
    #--------------------------------------------------------------
    # components_ inherited from base mlDecomposition class
    # internal_matrix_formats inherited from base mlDecomposition class -
    # need to set it with check_convert_input()
    is_initialized = FALSE,
    doc_topic_prior = NULL, # alpha
    topic_word_prior = NULL, # beta
    n_topics = NULL,
    ptr = NULL,
    doc_topic_count = NULL,
    vocabulary = NULL,
    #--------------------------------------------------------------
    fit_transform_internal = function(model_ptr, n_iter,
                                      convergence_tol = -1,
                                      n_check_convergence = 10,
                                      update_topics = 1L,
                                      progress = FALSE) {
      if(progress)
        pb = txtProgressBar(min = 0, max = n_iter, initial = 0, style = 3)

      loglik_previous = -Inf
      hist_size = ceiling(n_iter / n_check_convergence)
      loglik_hist = vector('list', hist_size)
      j = 1L

      for(i in seq_len(n_iter)) {
        private$run_iter_doc(update_topics)
        private$run_iter_word(update_topics)

        # check convergence
        if(i %% n_check_convergence == 0) {
          loglik = private$calc_pseudo_loglikelihood()

          if(self$verbose)
            message(sprintf("%s iter %d current loglikelihood %.4f", Sys.time(), i, loglik))

          loglik_hist[[j]] = data.frame(iter = i, loglikelihood = loglik)

          if(loglik_previous / loglik - 1 < convergence_tol) {
            if(progress) setTxtProgressBar(pb, n_iter)
            if(self$verbose) message(sprintf("%s early stopping at %d iteration", Sys.time(), i))
            break
          }
          loglik_previous = loglik
          j = j + 1
        }
        if(progress)
          setTxtProgressBar(pb, i)
      }
      if(progress)
        close(pb)

      res = warplda_get_doc_topic_count(model_ptr)
      attr(res, "likelihood") = do.call(rbind, loglik_hist)
      # attr(res, "iter") = i
      res
    },
    #--------------------------------------------------------------
    init_model_dtm = function(x, ptr = private$ptr) {
      x = check_convert_input(x, private$internal_matrix_formats, private$verbose)
      # Document-term matrix should have column names - vocabulary
      stopifnot(!is.null(colnames(x)))

      if(self$verbose)
        message(sprintf("%s converting DTM to internal C++ structure", Sys.time()))

      # random topic assignements for each word
      nnz = sum(x@x)
      # -1L because topics enumerated from 0 in c++ side
      z_old = sample.int(n = private$n_topics, size = nnz, replace = TRUE) - 1L
      z_new = sample.int(n = private$n_topics, size = nnz, replace = TRUE) - 1L
      warplda_init_dtm(ptr, x, z_old, z_new)
    },
    #---------------------------------------------------------------------------------------------
    get_topic_word_count = function() {
      res = warplda_get_topic_word_count(private$ptr);
      colnames(res) = private$vocabulary
      res
    },
    #---------------------------------------------------------------------------------------------
    # helpers for distributed LDA
    #---------------------------------------------------------------------------------------------
    # init_model_dtm2 = function(x) {
    #   private$init_model_dtm(x, private$ptr)
    # },
    set_c_all = function(x) {
      warplda_set_c_global(private$ptr, x);
    },

    get_c_all_local = function() {
      warplda_get_local_diff(private$ptr);
    },
    get_c_all = function() {
      warplda_get_c_global(private$ptr);
    },
    reset_c_local = function() {
      warplda_reset_local_diff(private$ptr);
    },

    # run_iter = function(calc_ll = T) {
    #   run_one_iter(ptr = private$ptr, update_topics = T,  calc_ll = calc_ll)
    # },

    run_iter_doc = function(update_topics = TRUE) {
      run_one_iter_doc(ptr = private$ptr, update_topics = update_topics)
    },

    run_iter_word = function(update_topics = TRUE) {
      run_one_iter_word(ptr = private$ptr, update_topics = update_topics)
    },

    calc_pseudo_loglikelihood = function() {
      warplda_pseudo_loglikelihood(ptr = private$ptr)
    }
  )
)

#' @rdname LatentDirichletAllocation
#' @export
LDA = LatentDirichletAllocation

#' @rdname LatentDirichletAllocation
#' @export
LatentDirichletAllocationDistributed = R6::R6Class(
  classname = c("WarpLDA", "LDA"),
  inherit = LatentDirichletAllocation,
  public = list(
    initialize = function(n_topics = 10L,
                          doc_topic_prior = 50 / n_topics,
                          topic_word_prior = 1 / n_topics,
                          cl = NULL,
                          verbose = FALSE) {

      foreach(seq_len(foreach::getDoParWorkers())) %dopar% {
        text2vec.environment <<- new.env(parent = emptyenv())
        text2vec.environment$lda = LatentDirichletAllocation$new(n_topics, doc_topic_prior, topic_word_prior, FALSE)
        TRUE
      }
      #   parallel::clusterMap(cl, function(x) {
      #     text2vec.environment <<- new.env(parent = emptyenv())
      #     text2vec.environment$lda = LatentDirichletAllocation$new(n_topics, doc_topic_priortopic_word_prior, FALSE)
      #     TRUE
      # })
    },
    fit_transform = function(x, n_iter = 1000, convergence_tol = 1e-3, n_check_convergence = 10,
                             progress = interactive(), ...) {
      stopifnot(inherits(x, "RowDistributedMatrix"))
      stopifnot(is.logical(progress))
      # sun_counts = function(...) do.call(`+`, ...)
      # ii = parallel::splitIndices(nrow(x), foreach::getDoParWorkers())
      global_counts =
        foreach(x_ref = x,
                .combine = list, .inorder = FALSE, .multicombine = TRUE) %dopar% {
                  lda = text2vec.environment$lda
                  lda$.__enclos_env__$private$init_model_dtm(get(x_ref$env)[[x_ref$key]])
                  lda$.__enclos_env__$private$get_c_all()
        }
      global_counts = Reduce(`+`, global_counts)
      # stat = foreach(x_ref = x,
      #         .combine = c, .inorder = FALSE, .multicombine = TRUE) %dopar% {
      #           nnz = sprintf("pid %d sum_nnz %d nnz %d", Sys.getpid(), sum(get(x_ref$env)[[x_ref$key]]@x),
      #                         length(get(x_ref$env)[[x_ref$key]]@x))
      #           nnz
      #         }
      # lapply(stat, message)
      for(i in seq_len(n_iter)) {

        iter_data =
          foreach(seq_len(foreach::getDoParWorkers()), .combine = list,
                  .inorder = FALSE, .multicombine = TRUE) %dopar% {

                    # extract
                    # lda = text2vec.environment$lda
                    t0 = Sys.time()
                    # sync
                    text2vec.environment$lda$.__enclos_env__$private$set_c_all(global_counts)

                    # sampling
                    text2vec.environment$lda$.__enclos_env__$private$run_iter_doc(TRUE)
                    text2vec.environment$lda$.__enclos_env__$private$run_iter_word(TRUE)

                    local_counts = text2vec.environment$lda$.__enclos_env__$private$get_c_all_local()

                    text2vec.environment$lda$.__enclos_env__$private$reset_c_local()
                    ll = text2vec.environment$lda$.__enclos_env__$private$calc_pseudo_loglikelihood()
                    stat = sprintf("pid %d %.3f", Sys.getpid(), difftime( Sys.time(), t0, units = "sec"))
                    list(ll = ll, local_counts = local_counts, stat = stat)
                  }
        lapply(iter_data, function(x) message(x[['stat']]))
        global_counts = lapply(iter_data, function(x) x[['local_counts']]) %>%
          Reduce(`+`,  ., init = global_counts)

        ll = lapply(iter_data, function(x) x[['ll']]) %>%
          do.call(sum, .)
        message(sprintf("%s %d loglik = %.3f", Sys.time(), i, ll))

        # iter_doc =
        #   foreach(seq_len(foreach::getDoParWorkers()), .combine = list,
        #           .inorder = FALSE, .multicombine = TRUE) %dopar% {
        #             lda = text2vec.environment$lda
        #
        #             lda$.__enclos_env__$private$set_c_all(global_counts)
        #
        #             lda$.__enclos_env__$private$run_iter_doc(TRUE)
        #
        #             local_counts = lda$.__enclos_env__$private$get_c_all_local()
        #
        #             lda$.__enclos_env__$private$reset_c_local()
        #             local_counts
        #           }
        #
        # global_counts =  Reduce(`+`, iter_doc , init = global_counts)
        #
        # iter_word =
        #   foreach(seq_len(foreach::getDoParWorkers()), .combine = list,
        #           .inorder = FALSE, .multicombine = TRUE) %dopar% {
        #             lda = text2vec.environment$lda
        #
        #             lda$.__enclos_env__$private$set_c_all(global_counts)
        #
        #             lda$.__enclos_env__$private$run_iter_word(TRUE)
        #
        #             local_counts = lda$.__enclos_env__$private$get_c_all_local()
        #
        #             lda$.__enclos_env__$private$reset_c_local()
        #             local_counts
        #           }
        # global_counts =  Reduce(`+`, iter_word , init = global_counts)

        # calculate loglikelyhood
        # ll =
        #   foreach(seq_len(foreach::getDoParWorkers()), .combine = sum,
        #           .inorder = FALSE, .multicombine = TRUE) %dopar% {
        #             text2vec.environment$lda$.__enclos_env__$private$calc_pseudo_loglikelihood()
        #           }
        # message(sprintf("%s %d loglik = %.3f", Sys.time(), i, ll))
      }
    }
  )
)



text2vec_serVis = function (json, out.dir = tempfile(), open.browser = interactive(),
          as.gist = FALSE, language = "english", ...) { # nocov start
  stopifnot(is.character(language), length(language) == 1,
            language %in% c("english", "polish"))
  dir.create(out.dir)
  src.dir <- system.file("htmljs", package = "LDAvis")
  to.copy <- Sys.glob(file.path(src.dir, "*"))
  file.copy(to.copy, out.dir, overwrite = TRUE, recursive = TRUE)
  if (language != "english") {
    ldavis.js <- readLines(file.path(out.dir, "ldavis.js"))
    lang.dict <- read.csv(system.file("languages/dictionary.txt",
                                      package = "LDAvis"))
    for (i in 1:nrow(lang.dict)) {
      ldavis.js <- gsub(x = ldavis.js, pattern = lang.dict[i,
                                                           1], replacement = lang.dict[i, language], fixed = TRUE)
    }
    if (language == "polish") {
      ldavis.js[674] <- gsub(ldavis.js[674], pattern = "80",
                             replacement = "175", fixed = TRUE)
    }
    write(ldavis.js, file = file.path(out.dir, "ldavis.js"))
  }
  con = file(file.path(out.dir, "lda.json"), encoding = "UTF-8")
  on.exit(close.connection(con))
  cat(json, file = con)
  if (as.gist) {
    gistd <- requireNamespace("gistr")
    if (!gistd) {
      warning("Please run `devtools::install_github('rOpenSci/gistr')` \n              to upload files to https://gist.github.com")
    }
    else {
      gist <- gistr::gist_create(file.path(out.dir, list.files(out.dir)),
                                 ...)
      if (interactive())
        gist
      url_name <- paste("http://bl.ocks.org", gist$id,
                        sep = "/")
      if (open.browser)
        utils::browseURL(url_name)
    }
    return(invisible())
  }
  servd <- requireNamespace("servr")
  if (open.browser) {
    if (!servd) {
      message("If the visualization doesn't render, install the servr package\n",
              "and re-run serVis: \n install.packages('servr') \n",
              "Alternatively, you could configure your default browser to allow\n",
              "access to local files as some browsers block this by default")
      utils::browseURL(sprintf("%s/index.html", out.dir))
    }
    else {
      servr::httd(dir = out.dir)
    }
  }
  return(invisible())
} # nocov end
