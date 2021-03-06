#' Return keys nearest to a given statistics or summary. 
#'
#' @param .data data.frame
#' @param key key, which identifies unique observations.
#' @param var variable to summarise
#' @param top_n top number of closest observations to return - default is 1, which will also return ties.
#' @param funs named list of functions to summarise by. Default is a given
#'   list of the five number summary, `l_five_num`.
#' @param ... extra arguments to pass to `mutate_at` when performing the summary
#'   as given by `funs`.
#'
#' @return data.frame containing keys closest to a given statistic.
#' @examples
#' wages %>%
#'   key_slope(ln_wages ~ xp) %>%
#'   keys_near(key = id,
#'             var = .slope_xp)
#'                
#' # Return observations closest to the five number summary of ln_wages
#' wages %>%
#'   keys_near(key = id,
#'             var = ln_wages)
#'                
#' # Specify your own list of summaries
#' l_ranges <- list(min = b_min,
#'                  range_diff = b_range_diff,
#'                  max = b_max,
#'                  iqr = b_iqr)
#'
#' wages %>%
#'   key_slope(formula = ln_wages ~ xp) %>%
#'   keys_near(key = id,
#'               var = .slope_xp,
#'               funs = l_ranges)
#' @export
keys_near <- function(.data,
                      key,
                      var,
                      top_n = 1,
                      funs = l_five_num,
                      ...){
  
  q_var <- rlang::enquo(var)
  q_key <- rlang::enquo(key)
  
  .data %>%
    tibble::as_tibble() %>%
    dplyr::mutate_at(
      .vars = dplyr::vars(!!q_var),
      .funs = funs,
      ...) %>%
    dplyr::select(!!q_key,
                  !!q_var,
                  dplyr::one_of(names(funs))) %>%
    tidyr::gather(key = "stat",
                  value = "stat_value",
           -!!q_key,
           -!!q_var) %>%
    dplyr::mutate(stat_diff = abs(!!q_var - stat_value)) %>%
    dplyr::group_by(stat) %>%
    dplyr::top_n(-top_n,
                 wt = stat_diff) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(stat = forcats::fct_relevel(.f = stat,
                                              levels = names(funs)))
}
