% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tokenizers.R
\name{tokenizers}
\alias{tokenizers}
\alias{word_tokenizer}
\alias{regexp_tokenizer}
\alias{char_tokenizer}
\alias{space_tokenizer}
\title{Simple tokenization functions, which performs string splitting}
\usage{
word_tokenizer(strings, ...)

regexp_tokenizer(strings, pattern, ...)

char_tokenizer(strings, ...)

space_tokenizer(strings, ...)
}
\arguments{
\item{strings}{\code{character} vector}

\item{...}{other parameters to \link{strsplit} function, which is used under the hood.}

\item{pattern}{\code{character} pattern symbol.}
}
\value{
\code{list} of \code{character} vectors.
Each element of list containts vector of tokens.
}
\description{
simple wrappers around \code{base} regular expressions.
For much more faster and functional tokenizers see \code{tokenizers} package:
\url{https://cran.r-project.org/package=tokenizers}.
Also see \code{str_split_*} functions in \code{stringi} and \code{stringr} packages.
The reason for not including this packages to \code{text2vec} dependencies is our
desare to keep number of dependencies as small as possible.
}
\examples{
doc = c("first  second", "bla, bla, blaa")
# split by words
word_tokenizer(doc)
#faster, but far less general - perform split by a fixed single whitespace symbol.
regexp_tokenizer(doc, " ", TRUE)
}
