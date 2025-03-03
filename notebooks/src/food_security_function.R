calculate_food_insecurity <- function(data,
                                      group_vars = NULL,
                                      date_var = NULL,
                                      weight_var = "indw",
                                      food_vars = c("eat_less", "ran_out", "went_hungry", "whole_day",
                                                    "worried", "unhealthy", "low_diversity", "skip_meal")) {

  # Check if input is a data frame
  if (!is.data.frame(data)) {
    stop("Input must be a data frame")
  }

  # Check if weight variable exists
  if (!weight_var %in% names(data)) {
    stop(glue::glue("Weight variable '{weight_var}' not found in data"))
  }

  # Check if food variables exist
  missing_vars <- food_vars[!food_vars %in% names(data)]
  if (length(missing_vars) > 0) {
    stop(glue::glue("Food variables not found in data: {paste(missing_vars, collapse = ', ')}"))
  }

  # Combine date_var and group_vars if date_var is provided
  if (!is.null(date_var)) {
    if (!date_var %in% names(data)) {
      stop(glue::glue("Date variable '{date_var}' not found in data"))
    }

    all_group_vars <- c(date_var, group_vars)
  } else {
    all_group_vars <- group_vars
  }

  # If no grouping variables provided, calculate overall means with an "overall" grouping variable
  if (is.null(all_group_vars) || length(all_group_vars) == 0) {
    return(
      data %>%
        dplyr::summarize(dplyr::across(
          dplyr::all_of(food_vars),
          ~ weighted.mean(.x, w = .data[[weight_var]], na.rm = TRUE)
        )) %>%
        dplyr::mutate(group = "overall") %>%
        dplyr::select(group, dplyr::everything())
    )
  }

  # Check if grouping variables exist
  missing_group_vars <- all_group_vars[!all_group_vars %in% names(data)]
  if (length(missing_group_vars) > 0) {
    stop(glue::glue("Variables not found in data: {paste(missing_group_vars, collapse = ', ')}"))
  }

  # Calculate grouped weighted means
  data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(all_group_vars))) %>%
    dplyr::summarize(dplyr::across(
      dplyr::all_of(food_vars),
      ~ weighted.mean(.x, w = .data[[weight_var]], na.rm = TRUE)
    )) %>%
    dplyr::ungroup()
}

