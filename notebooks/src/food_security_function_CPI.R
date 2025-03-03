calculate_FIES_concerns_and_CPI <- function(data,
                                        group_vars = "region",
                                        date_var = "mofd",
                                        weight_var = "popw",
                                        concern_vars = c("eat_less", "ran_out", "went_hungry", "whole_day",
                                                         "worried", "unhealthy", "low_diversity", "skip_meal"),
                                        cpi_var = "cpi_prov") {
  # Check if input is a data frame
  if (!is.data.frame(data)) {
    stop("Input must be a data frame")
  }

  # Check if required variables exist
  required_vars <- c(date_var, weight_var, cpi_var)
  if (!is.null(group_vars)) {
    required_vars <- c(required_vars, group_vars)
  }

  missing_vars <- required_vars[!required_vars %in% names(data)]
  if (length(missing_vars) > 0) {
    stop(glue::glue("Variables not found in data: {paste(missing_vars, collapse = ', ')}"))
  }

  # Check if concern variables exist
  available_concern_vars <- concern_vars[concern_vars %in% names(data)]
  if (length(available_concern_vars) == 0) {
    stop("None of the specified concern variables found in data")
  }

  # Transform data with date variables
  transformed_data <- data %>%
    dplyr::mutate(
      # Convert mofd to an actual date (first day of the month)
      date = as.Date("1960-01-01") %m+% months(.data[[date_var]]),
      # Create a formatted year-month column
      month_year = format(date, "%Y-%m"),
      # Create a more readable format like "2024m3"
      mofd_label = format(date, "%Ym%m")
    )

  # If no grouping variables, group only by date
  if (is.null(group_vars)) {
    result <- transformed_data %>%
      dplyr::group_by(date) %>%
      dplyr::summarise(
        # Calculate weighted means for all available concern variables
        dplyr::across(
          dplyr::all_of(available_concern_vars),
          ~ weighted.mean(.x, .data[[weight_var]], na.rm = TRUE),
          .names = "{.col}"
        ),
        CPI = mean(.data[[cpi_var]])
      )
  } else {
    # Group by date and specified group variables
    result <- transformed_data %>%
      dplyr::group_by(date, .data[[group_vars]]) %>%
      dplyr::summarise(
        # Calculate weighted means for all available concern variables
        dplyr::across(
          dplyr::all_of(available_concern_vars),
          ~ weighted.mean(.x, .data[[weight_var]], na.rm = TRUE),
          .names = "{.col}"
        ),
        CPI = mean(.data[[cpi_var]])
      )
  }

  return(result %>% dplyr::ungroup())
}
