#' Help Me
#'
#' Helps someone.
#'
#' @param x A character vector
#' @return A helpful string
#'
#' @examples
#' \dontrun{
#' help("foo")
#' }
#' @export
help_me <- function(x) {
  paste("help", x)
}
