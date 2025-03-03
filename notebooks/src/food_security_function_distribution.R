calculate_food_insecurity_distribution <- function(data,
                                                   score_var = "totfoodinsec",
                                                   group_vars = NULL,
                                                   date_var = NULL,
                                                   weight_var = "indw",
                                                   capitalize_labels = TRUE,
                                                   pivot_wider_output = TRUE,
                                                   pivot_on = NULL,
                                                   pivot_on_score = FALSE,
                                                   score_prefix = "score_") {
  # Check if input is a data frame
  if (!is.data.frame(data)) {
    stop("Input must be a data frame")
  }

  # Check if required variables exist
  required_vars <- c(score_var, weight_var)
  missing_vars <- required_vars[!required_vars %in% names(data)]
  if (length(missing_vars) > 0) {
    stop(glue::glue("Required variables not found in data: {paste(missing_vars, collapse = ', ')}"))
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

  # If no grouping variables provided, calculate overall distribution
  if (is.null(all_group_vars) || length(all_group_vars) == 0) {
    result <- data %>%
      dplyr::group_by(!!rlang::sym(score_var)) %>%
      dplyr::summarise(
        weighted_count = sum(!!rlang::sym(weight_var), na.rm = TRUE),
        raw_count = dplyr::n(),
        .groups = "drop"
      ) %>%
      dplyr::mutate(
        total_weighted_count = sum(weighted_count),
        weighted_percentage = (weighted_count / total_weighted_count) * 100,
        total_raw_count = sum(raw_count)
      ) %>%
      dplyr::arrange(!!rlang::sym(score_var)) %>%
      dplyr::mutate(group = "overall")

    # Return early for overall case since it doesn't need pivot_wider
    return(result)
  }

  # Check if grouping variables exist
  missing_group_vars <- all_group_vars[!all_group_vars %in% names(data)]
  if (length(missing_group_vars) > 0) {
    stop(glue::glue("Variables not found in data: {paste(missing_group_vars, collapse = ', ')}"))
  }

  # Create grouped query
  result <- data %>%
    # Group by all grouping variables and score variable
    dplyr::group_by(dplyr::across(dplyr::all_of(c(all_group_vars, score_var)))) %>%
    # Calculate weighted and raw counts
    dplyr::summarise(
      weighted_count = sum(!!rlang::sym(weight_var), na.rm = TRUE),
      raw_count = dplyr::n(),
      .groups = "drop"
    ) %>%
    # Group by just the grouping variables to calculate percentages
    dplyr::group_by(dplyr::across(dplyr::all_of(all_group_vars))) %>%
    # Calculate percentages
    dplyr::mutate(
      total_weighted_count = sum(weighted_count),
      weighted_percentage = (weighted_count / total_weighted_count) * 100,
      total_raw_count = sum(raw_count)
    ) %>%
    # Arrange for readability
    dplyr::arrange(dplyr::across(dplyr::all_of(c(all_group_vars, score_var)))) %>%
    dplyr::ungroup()

  # Capitalize labels if requested
  if (capitalize_labels && !is.null(date_var)) {
    result <- result %>%
      dplyr::mutate(!!rlang::sym(date_var) := stringr::str_to_upper(!!rlang::sym(date_var)))
  }

  # Pivot wider if requested
  if (pivot_wider_output) {
    # If pivoting on score variable is requested
    if (pivot_on_score) {
      # Create pivoted output with score variable as columns
      result <- result %>%
        dplyr::select(dplyr::all_of(c(all_group_vars, score_var, "weighted_percentage"))) %>%
        tidyr::pivot_wider(
          names_from = !!rlang::sym(score_var),
          values_from = "weighted_percentage",
          names_prefix = score_prefix
        )
    } else {
      # Determine which variable to pivot on (original behavior)
      pivot_on_var <- if (!is.null(pivot_on)) {
        pivot_on
      } else if (!is.null(date_var)) {
        date_var
      } else if (!is.null(group_vars) && length(group_vars) > 0) {
        group_vars[1]
      } else {
        NULL
      }

      # If we have a variable to pivot on
      if (!is.null(pivot_on_var)) {
        # Construct list of grouping variables excluding the pivot variable
        group_vars_no_pivot <- all_group_vars[all_group_vars != pivot_on_var]

        # Create pivoted output
        result <- result %>%
          dplyr::select(dplyr::all_of(c(all_group_vars, score_var, "weighted_percentage"))) %>%
          tidyr::pivot_wider(
            names_from = !!rlang::sym(pivot_on_var),
            values_from = "weighted_percentage"
          )
      }
    }
  }

  return(result)
}

# Example usage:
#
# # Basic usage with just date variable
# monthly_distribution <- calculate_food_insecurity_distribution(
#   data = individual_level_data_clean,
#   date_var = "mofd_label"
# )
#
# # With additional grouping variable
# region_month_distribution <- calculate_food_insecurity_distribution(
#   data = individual_level_data_clean,
#   date_var = "mofd_label",
#   group_vars = "region"
# )
#
# # Custom pivot
# distribution_by_region <- calculate_food_insecurity_distribution(
#   data = individual_level_data_clean,
#   date_var = "mofd_label",
#   group_vars = c("region", "area"),
#   pivot_on = "region"
# )
#
# # Pivot on score variable instead of date/group variable
# score_distribution_by_month <- calculate_food_insecurity_distribution(
#   data = individual_level_data_clean,
#   date_var = "mofd_label",
#   pivot_on_score = TRUE
# )
#
# # Score distribution by region with custom score prefix
# score_distribution_by_region <- calculate_food_insecurity_distribution(
#   data = individual_level_data_clean,
#   group_vars = "region",
#   pivot_on_score = TRUE,
#   score_prefix = "FIES_"  # Use FIES_ instead of score_
# )

