run_linear_models <- function(data, dep_vars) {
  # Create and run models for each dependent variable
  models <- purrr::map(dep_vars, function(y_var) {
    # First check if variable exists and has non-missing values
    if (!y_var %in% names(data)) {
      message(glue::glue("Variable {y_var} not found in data. Skipping."))
      return(NULL)
    }

    non_missing_count <- sum(!is.na(data[[y_var]]))
    message(glue::glue("Variable {y_var} has {non_missing_count} non-missing values"))

    if (non_missing_count == 0) {
      message(glue::glue("Variable {y_var} has no non-missing values. Skipping."))
      return(NULL)
    }

    # Create model formulas
    f1 <- as.formula(glue::glue("{y_var} ~ pdef3"))
    f2 <- as.formula(glue::glue("{y_var} ~ i(loc_cost_quint)"))
    f3 <- as.formula(glue::glue("{y_var} ~ ln_pc_def_inc + pdef3"))
    f4 <- as.formula(glue::glue("{y_var} ~ hhag + ln_pc_def_inc + pdef3"))

    # Create safer filtering approach - without using get()
    # Model 1: Filter for model 1 variables
    data_m1 <- data
    data_m1 <- data_m1[!is.na(data_m1[[y_var]]) & !is.na(data_m1$pdef3) & !is.na(data_m1$popw), ]
    message(glue::glue("Model 1 has {nrow(data_m1)} complete cases"))

    # Model 2: Filter for model 2 variables
    data_m2 <- data
    data_m2 <- data_m2[!is.na(data_m2[[y_var]]) & !is.na(data_m2$loc_cost_quint) & !is.na(data_m2$popw), ]
    message(glue::glue("Model 2 has {nrow(data_m2)} complete cases"))

    # Model 3: Filter for model 3 variables
    data_m3 <- data
    data_m3 <- data_m3[!is.na(data_m3[[y_var]]) & !is.na(data_m3$ln_pc_def_inc) &
                         !is.na(data_m3$pdef3) & !is.na(data_m3$popw), ]
    message(glue::glue("Model 3 has {nrow(data_m3)} complete cases"))

    # Model 4: Filter for model 4 variables
    data_m4 <- data
    data_m4 <- data_m4[!is.na(data_m4[[y_var]]) & !is.na(data_m4$ln_pc_def_inc) &
                         !is.na(data_m4$pdef3) & !is.na(data_m4$hhag) & !is.na(data_m4$popw), ]
    message(glue::glue("Model 4 has {nrow(data_m4)} complete cases"))

    # Only run models if there are enough cases
    models_list <- list()

    if (nrow(data_m1) > 0) {
      models_list$m1 <- tryCatch({
        fixest::feols(f1, data = data_m1, weights = ~popw, vcov = "HC1")
      }, error = function(e) {
        message(glue::glue("Error in model 1 for {y_var}: {e$message}"))
        return(NULL)
      })
    }

    if (nrow(data_m2) > 0) {
      models_list$m2 <- tryCatch({
        fixest::feols(f2, data = data_m2, weights = ~popw, vcov = "HC1")
      }, error = function(e) {
        message(glue::glue("Error in model 2 for {y_var}: {e$message}"))
        return(NULL)
      })
    }

    if (nrow(data_m3) > 0) {
      models_list$m3 <- tryCatch({
        fixest::feols(f3, data = data_m3, weights = ~popw, vcov = "HC1")
      }, error = function(e) {
        message(glue::glue("Error in model 3 for {y_var}: {e$message}"))
        return(NULL)
      })
    }

    if (nrow(data_m4) > 0) {
      models_list$m4 <- tryCatch({
        fixest::feols(f4, data = data_m4, weights = ~popw, vcov = "HC1")
      }, error = function(e) {
        message(glue::glue("Error in model 4 for {y_var}: {e$message}"))
        return(NULL)
      })
    }

    return(models_list)
  })

  # Name the models list
  names(models) <- dep_vars

  return(models)
}
summarize_linear_models <- function(linear_models, food_insec) {
 # Create etables for each food insecurity outcome
  model_tables <- purrr::map(food_insec, function(y_var) {
    models <- linear_models[[y_var]]

    if (is.null(models) || length(models) == 0) {
      return(NULL)
    }

    # Get valid models for this outcome
    valid_models <- models[!sapply(models, is.null)]

    if (length(valid_models) == 0) {
      return(NULL)
    }

    # Generate etable
    fixest::etable(
      valid_models,
      title = glue::glue("Models for {y_var}"),
      digits = 3,
      signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1)
    )
  })

  names(model_tables) <- food_insec
  return(model_tables)
}

# summarize_linear_models <- function(linear_models, food_insec) {
#   # Create HTML tables for each food insecurity outcome
#   model_tables <- purrr::map(food_insec, function(y_var) {
#     models <- linear_models[[y_var]]
#     if (is.null(models) || length(models) == 0) {
#       return(NULL)
#     }
#
#     # Get valid models for this outcome
#     valid_models <- models[!sapply(models, is.null)]
#     if (length(valid_models) == 0) {
#       return(NULL)
#     }
#
#     # Create a modelsummary table with kableExtra output
#     # This works well with HTML output in Quarto
#     model_table <- modelsummary::modelsummary(
#       valid_models,
#       title = paste("Models for", y_var),
#       stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
#       gof_map = c("nobs", "r.squared", "adj.r.squared"),
#       fmt = 3,  # Round to 3 decimal places
#       output = "kableExtra"
#     ) %>%
#       kableExtra::kable_styling(
#         bootstrap_options = c("striped", "hover", "condensed", "responsive"),
#         full_width = FALSE,
#         position = "center"
#       ) %>%
#       kableExtra::add_header_above(c(" " = 1, "Model Results" = length(valid_models)))
#
#     return(model_table)
#   })
#
#   names(model_tables) <- food_insec
#   return(model_tables)
# }
#



# summarize_linear_models <- function(linear_models, food_insec) {
#   # Using DT for better HTML tables in Quarto
#
#   # First, we need to ensure the DT package is loaded
#   if (!requireNamespace("DT", quietly = TRUE)) {
#     stop("Please install the DT package: install.packages('DT')")
#   }
#
#   # Create HTML tables for each food insecurity outcome
#   for (y_var in food_insec) {
#     models <- linear_models[[y_var]]
#     if (is.null(models) || length(models) == 0) {
#       next
#     }
#
#     # Get valid models for this outcome
#     valid_models <- models[!sapply(models, is.null)]
#     if (length(valid_models) == 0) {
#       next
#     }
#
#     # Print section header for this outcome
#     cat("\n\n### Models for", y_var, "\n\n")
#
#     # Create a tidy dataframe of model results
#     model_df <- purrr::map_dfr(names(valid_models), function(model_name) {
#       model <- valid_models[[model_name]]
#
#       # Extract coefficients
#       coefs <- broom::tidy(model)
#
#       # Add model name and significance stars
#       coefs <- coefs %>%
#         dplyr::mutate(
#           model = model_name,
#           p_stars = dplyr::case_when(
#             p.value < 0.01 ~ "***",
#             p.value < 0.05 ~ "**",
#             p.value < 0.1 ~ "*",
#             TRUE ~ ""
#           ),
#           estimate_formatted = sprintf("%.3f%s", estimate, p_stars)
#         )
#
#       return(coefs)
#     })
#
#     # Reshape to wide format for display
#     model_wide <- model_df %>%
#       dplyr::select(term, model, estimate_formatted) %>%
#       tidyr::pivot_wider(
#         names_from = model,
#         values_from = estimate_formatted
#       )
#
#     # Add model fit statistics
#     model_stats <- purrr::map_dfr(names(valid_models), function(model_name) {
#       model <- valid_models[[model_name]]
#
#       # Get model statistics
#       glance_data <- broom::glance(model)
#
#       # Create rows for R-squared and observations
#       data.frame(
#         term = c("R-squared", "Adj. R-squared", "Observations"),
#         model = model_name,
#         estimate_formatted = c(
#           sprintf("%.3f", glance_data$r.squared),
#           sprintf("%.3f", glance_data$adj.r.squared),
#           as.character(glance_data$nobs)
#         )
#       )
#     })
#
#     # Add statistics to the wide format
#     stats_wide <- model_stats %>%
#       dplyr::select(term, model, estimate_formatted) %>%
#       tidyr::pivot_wider(
#         names_from = model,
#         values_from = estimate_formatted
#       )
#
#     # Combine coefficients and statistics
#     full_table <- dplyr::bind_rows(model_wide, stats_wide)
#
#     # Create the interactive datatable
#     DT::datatable(
#       full_table,
#       options = list(
#         pageLength = 20,
#         dom = 't',  # Just show the table without search/pagination
#         ordering = FALSE
#       ),
#       rownames = FALSE,
#       caption = paste("Models for", y_var),
#       class = 'cell-border stripe'
#     ) %>%
#       DT::formatStyle(
#         columns = 1:ncol(full_table),
#         textAlign = 'center',
#         color = 'black',
#         backgroundColor = ifelse(seq_len(nrow(full_table)) %% 2 == 0, "#f5f5f5", "white")
#       ) %>%
#       print()
#   }
#
#   # Return invisible to avoid printing NULL at the end
#   return(invisible(NULL))
# }


create_comparative_table <- function(linear_models, outcome_vars, model_num = "m3",
                                     se_type = "Heterosked.-rob.") {
  # Load required packages if not already loaded
  if (!requireNamespace("purrr", quietly = TRUE)) {
    stop("Please install purrr: install.packages('purrr')")
  }

  # Create a list of models across different outcomes but same model number
  model_list <- list()

  for (outcome in outcome_vars) {
    if (!is.null(linear_models[[outcome]]) && !is.null(linear_models[[outcome]][[model_num]])) {
      model_list[[outcome]] <- linear_models[[outcome]][[model_num]]
    }
  }

  # Only proceed if we have models
  if (length(model_list) == 0) {
    return(NULL)
  }

  # Format the column names to be more readable
  names(model_list) <- gsub("_", " ", names(model_list))
  names(model_list) <- stringr::str_to_title(names(model_list))

  # Create S.E. type row as a data frame
  se_type_df <- data.frame(
    term = "S.E. type",
    stringsAsFactors = FALSE
  )

  # Add the same SE type for each model (manually specified)
  for (model_name in names(model_list)) {
    se_type_df[[model_name]] <- se_type
  }

  # Get all unique coefficients from all models
  all_terms <- unique(unlist(lapply(model_list, function(model) {
    names(coef(model))
  })))

  # Create improved coefficient mapping with better labels
  coef_mapping <- c(
    # Standard variables
    "(Intercept)" = "Constant",
    "pdef3" = "Spatial deflator",
    "ln_pc_def_inc" = "Log per-capita income",
    "hhag" = "Agricultural household",
    "base_ln_pc_def_inc" = "Baseline spatially deflated log per capita income"
  )

  # Inspect all terms for debugging purposes
  # print(all_terms)

  # Add any remaining coefficients to the mapping
  for (term in all_terms) {
    if (!(term %in% names(coef_mapping))) {
      # Special handling for quintile variables - need to match exactly what appears in the model
      if (grepl("loc_cost_quint", term)) {
        # Extract the quintile number
        quint_num <- gsub(".*([0-9])$", "\\1", term)
        coef_mapping[term] <- paste("Location cost quintile", quint_num)
      } else {
        # Apply basic cleaning for other unmapped variables:
        clean_term <- gsub("_", " ", term)
        clean_term <- stringr::str_to_title(clean_term)
        coef_mapping[term] <- clean_term
      }
    }
  }

  # Create a comparative table showing all coefficients
  modelsummary(
    model_list,
    coef_map = coef_mapping,      # Use our improved coefficient mapping
    coef_omit = NULL,             # Don't omit any coefficients
    #add_rows = se_type_df,       # cant figure this out for now, will ignore for now
    stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
    gof_map = c("nobs", "r.squared", "adj.r.squared"),
    title = paste("Comparison of", model_num, "across different food insecurity outcomes"),
    notes = "* p < 0.1, ** p < 0.05, *** p < 0.01",
    estimate = "{estimate}{stars} ({std.error})",  # Explicitly format coefficients
    statistic = NULL,  # Don't show t-statistics
    output = "kableExtra"
  ) %>%
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      position = "center"
    ) %>%
    kableExtra::add_header_above(c(" " = 1, "Food Insecurity Outcomes" = length(model_list)))
}

# Enhanced version with model numbers in facets and Tableau colors
create_coef_plots <- function(linear_models, food_insec) {
  # Create coefficient plots for selected variables across outcomes

  # For model 1 (Spatial deflator only)
  m1_coef_data <- purrr::map_dfr(food_insec, function(y_var) {
    models <- linear_models[[y_var]]
    if (is.null(models) || length(models) == 0 || is.null(models$m1)) {
      return(NULL)
    }
    # Get Model 1 for each outcome
    model <- models$m1
    # Extract coefficient data using broom::tidy()
    coefs <- broom::tidy(model)
    coefs %>%
      dplyr::filter(term != "(Intercept)") %>%
      dplyr::mutate(
        dependent_var = y_var,
        model = "m1"
      )
  })

  # For model 2 (Location cost quintiles)
  m2_coef_data <- purrr::map_dfr(food_insec, function(y_var) {
    models <- linear_models[[y_var]]
    if (is.null(models) || length(models) == 0 || is.null(models$m2)) {
      return(NULL)
    }
    # Get Model 2 for each outcome
    model <- models$m2
    # Extract coefficient data using broom::tidy()
    coefs <- broom::tidy(model)
    coefs %>%
      dplyr::filter(term != "(Intercept)") %>%
      dplyr::mutate(
        dependent_var = y_var,
        model = "m2"
      )
  })

  # For model 3 (Income + spatial deflator)
  m3_coef_data <- purrr::map_dfr(food_insec, function(y_var) {
    models <- linear_models[[y_var]]
    if (is.null(models) || length(models) == 0 || is.null(models$m3)) {
      return(NULL)
    }
    # Get Model 3 for each outcome
    model <- models$m3
    # Extract coefficient data using broom::tidy()
    coefs <- broom::tidy(model)
    coefs %>%
      dplyr::filter(term != "(Intercept)") %>%
      dplyr::mutate(
        dependent_var = y_var,
        model = "m3"
      )
  })

  # For model 4 (Agriculture + income + spatial deflator)
  m4_coef_data <- purrr::map_dfr(food_insec, function(y_var) {
    models <- linear_models[[y_var]]
    if (is.null(models) || length(models) == 0 || is.null(models$m4)) {
      return(NULL)
    }
    # Get Model 4 for each outcome
    model <- models$m4
    # Extract coefficient data using broom::tidy()
    coefs <- broom::tidy(model)
    coefs %>%
      dplyr::filter(term != "(Intercept)") %>%
      dplyr::mutate(
        dependent_var = y_var,
        model = "m4"
      )
  })

  # Combine coefficient data from all models
  coef_data <- dplyr::bind_rows(m1_coef_data, m2_coef_data, m3_coef_data, m4_coef_data)

  # Only create plot if we have data
  if (nrow(coef_data) == 0) {
    message("No coefficient data available for plotting")
    return(NULL)
  }

  # Create coefficient plot with facets for models
  coef_plot <- coef_data %>%
    dplyr::mutate(
      term = dplyr::case_when(
        term == "ln_pc_def_inc" ~ "Log per-capita income",
        term == "pdef3" ~ "Spatial deflator",
        term == "hhag" ~ "Agricultural household",
        grepl("loc_cost_quint", term) ~ paste("Location cost quintile", gsub(".*([0-9])$", "\\1", term)),
        TRUE ~ term
      ),
      model_desc = dplyr::case_when(
        model == "m1" ~ "Model 1: Spatial Deflator Only",
        model == "m2" ~ "Model 2: Location Cost Quintiles",
        model == "m3" ~ "Model 3: Income + Spatial Deflator",
        model == "m4" ~ "Model 4: Agriculture + Income + Spatial Deflator"
      ),
      # Create nicer labels for food insecurity measures
      dependent_var = forcats::fct_reorder(dependent_var, estimate),
      dependent_var = dplyr::case_when(
        dependent_var == "worried" ~ "Worried",
        dependent_var == "unhealthy" ~ "Unhealthy",
        dependent_var == "low_diversity" ~ "Low Diversity",
        dependent_var == "skip_meal" ~ "Skip Meal",
        dependent_var == "eat_less" ~ "Eat Less",
        dependent_var == "ran_out" ~ "Ran Out",
        dependent_var == "went_hungry" ~ "Went Hungry",
        dependent_var == "whole_day" ~ "Whole Day",
        dependent_var == "totfoodinsec" ~ "Total Food Insecurity",
        TRUE ~ dependent_var
      )
    ) %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = estimate,
        y = dependent_var,
        xmin = estimate - 1.96 * std.error,
        xmax = estimate + 1.96 * std.error,
        color = term
      )
    ) +
    ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    # Add faceting by model, now with 4 models displayed in a 2x2 grid
    ggplot2::facet_wrap(~ model_desc, ncol = 2) +
    # Use Tableau color palette
    ggthemes::scale_colour_tableau() +
    ggplot2::labs(
      title = "Effect of Key Predictors on Food Insecurity Measures",
      x = "Coefficient (95% CI)",
      y = "Food Insecurity Measure",
      color = "Predictor"
    ) +
    ggplot2::theme_minimal() +
    # Improve readability of facet labels
    ggplot2::theme(
      strip.background = ggplot2::element_rect(fill = "lightgray", color = NA),
      strip.text = ggplot2::element_text(face = "bold"),
      panel.spacing = ggplot2::unit(1, "lines"),
      legend.position = "bottom",
      legend.box = "horizontal"
    )

  return(coef_plot)
}
extract_model_stats <- function(linear_models, food_insec) {
  # Extract model statistics for comparison
  model_stats <- purrr::map_dfr(food_insec, function(y_var) {
    models <- linear_models[[y_var]]

    if (is.null(models) || length(models) == 0) {
      return(NULL)
    }

    # Get valid models
    valid_models <- models[!sapply(models, is.null)]

    if (length(valid_models) == 0) {
      return(NULL)
    }

    # Extract statistics for each model
    purrr::map_dfr(names(valid_models), function(model_name) {
      model <- valid_models[[model_name]]

      # Check if model is a valid fixest object with the expected structure
      if (!inherits(model, "fixest")) {
        message(glue::glue("Model {model_name} for {y_var} is not a fixest object"))
        return(NULL)
      }

      # Get model stats using fixest
      stats <- fixest::fitstat(model, ~ aic + bic + r2)

      # Get number of observations safely
      # Use different ways to access observations depending on model structure
      n_observations <- tryCatch({
        # Try length of residuals first
        if (!is.null(model$residuals)) {
          length(model$residuals)
        } else if (!is.null(model$fitted.values)) {
          length(model$fitted.values)
        } else {
          # Get from summary
          sum_model <- summary(model)
          if (!is.null(sum_model$nobs)) {
            sum_model$nobs
          } else {
            NA_integer_  # If all else fails
          }
        }
      }, error = function(e) {
        message(glue::glue("Error getting nobs for {model_name} ({y_var}): {e$message}"))
        NA_integer_
      })

      tibble::tibble(
        dependent_var = y_var,
        model = model_name,
        model_desc = dplyr::case_when(
          model_name == "m1" ~ "Spatial deflator",
          model_name == "m2" ~ "Cost quintiles",
          model_name == "m3" ~ "Income + spatial deflator",
          model_name == "m4" ~ "Agriculture + income + spatial deflator",
          TRUE ~ model_name
        ),
        aic = stats$aic,
        bic = stats$bic,
        r_squared = stats$r2,
        n_obs = n_observations
      )
    })
  })

  return(model_stats)
}


run_logit_models <- function(data, dep_vars) {
  logit_models <- purrr::map(dep_vars, function(y_var) {
    # Create formula
    f_logit <- as.formula(glue::glue("{y_var} ~ ln_pc_def_inc + pdef3"))

    # Filter data for this specific model - only include complete cases
    data_filtered <- data %>%
      dplyr::filter(!is.na(get(y_var)), !is.na(ln_pc_def_inc), !is.na(pdef3), !is.na(hhid))

    # Skip if too few observations
    if (nrow(data_filtered) < 10) {
      message(glue::glue("Insufficient data for logistic model of {y_var}"))
      return(NULL)
    }

    # For totfoodinsec, check if it's a count variable and use appropriate model
    if (y_var == "totfoodinsec") {
      # Check range of values
      min_val <- min(data_filtered[[y_var]], na.rm = TRUE)
      max_val <- max(data_filtered[[y_var]], na.rm = TRUE)

      message(glue::glue("{y_var} range: {min_val} to {max_val}"))

      # If it's a count variable with range > 1, use Poisson regression instead
      if (max_val > 1) {
        message(glue::glue("Using Poisson regression for {y_var} instead of logistic"))
        poisson_model <- tryCatch({
          fixest::feglm(f_logit, data = data_filtered, family = "poisson", vcov = ~hhid)
        }, error = function(e) {
          message(glue::glue("Error in Poisson model for {y_var}: {e$message}"))
          return(NULL)
        })

        if (!is.null(poisson_model)) {
          message(glue::glue("Poisson model for {y_var}: {nrow(data_filtered)} observations"))
        }

        return(poisson_model)
      }
    }

    # For binary outcomes, use logistic regression
    model <- tryCatch({
      fixest::feglm(f_logit, data = data_filtered, family = "logit", vcov = ~hhid)
    }, error = function(e) {
      message(glue::glue("Error in logistic model for {y_var}: {e$message}"))
      return(NULL)
    })

    if (!is.null(model)) {
      message(glue::glue("Logistic model for {y_var}: {nrow(data_filtered)} observations"))
    }

    return(model)
  })

  # Name the models list
  names(logit_models) <- dep_vars

  return(logit_models)
}

# Function to create a summary table for logistic/Poisson food insecurity models
create_logit_summary_table <- function(logit_models, outcome_vars, se_type = "by: hhid") {
  # Create a list of models across different outcomes
  model_list <- list()

  for (outcome in outcome_vars) {
    if (!is.null(logit_models[[outcome]])) {
      model_list[[outcome]] <- logit_models[[outcome]]
    }
  }

  # Only proceed if we have models
  if (length(model_list) == 0) {
    return(NULL)
  }

  # Format the column names to be more readable
  names(model_list) <- gsub("_", " ", names(model_list))
  names(model_list) <- stringr::str_to_title(names(model_list))

  # Create S.E. type row as a data frame
  se_type_df <- data.frame(
    term = "S.E. type",
    stringsAsFactors = FALSE
  )

  # Add the same SE type for each model (manually specified)
  for (model_name in names(model_list)) {
    se_type_df[[model_name]] <- se_type
  }

  # Get all unique coefficients from all models
  all_terms <- unique(unlist(lapply(model_list, function(model) {
    names(coef(model))
  })))

  # Create improved coefficient mapping with better labels
  coef_mapping <- c(
    # Standard variables
    "(Intercept)" = "Constant",
    "pdef3" = "Spatial deflator",
    "ln_pc_def_inc" = "Log per-capita income"
  )

  # Add any remaining coefficients to the mapping
  for (term in all_terms) {
    if (!(term %in% names(coef_mapping))) {
      # Apply basic cleaning for unmapped variables
      clean_term <- gsub("_", " ", term)
      clean_term <- stringr::str_to_title(clean_term)
      coef_mapping[term] <- clean_term
    }
  }

  # Create a comparative table showing all coefficients
  modelsummary(
    model_list,
    coef_map = coef_mapping,
    coef_omit = NULL,
    stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
    gof_map = c(
      "nobs",
      "logLik",
      "BIC",
      "r.squared" = "Squared Cor."
    ),
    title = "Logistic and Poisson Regression Models for Food Insecurity Measures",
    notes = "* p < 0.1, ** p < 0.05, *** p < 0.01",
    estimate = "{estimate}{stars} ({std.error})",
    statistic = NULL,
    output = "kableExtra"
  ) %>%
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      position = "center"
    ) %>%
    kableExtra::add_header_above(c(" " = 1, "Food Insecurity Outcomes" = length(model_list)))
}



# Fixed version of extract_logit_results function
extract_logit_results <- function(logit_models) {
  logit_results <- purrr::map_dfr(names(logit_models), function(y_var) {
    model <- logit_models[[y_var]]

    if (is.null(model)) {
      return(NULL)
    }

    # Extract coefficients using broom::tidy
    coefs <- broom::tidy(model)

    # Get number of observations more reliably
    n_observations <- tryCatch({
      # Try different ways to get observation count
      if (!is.null(model$nobs)) {
        model$nobs
      } else if (!is.null(model$nobst)) {
        model$nobst
      } else if (!is.null(model$N)) {
        model$N
      } else if (!is.null(model$n)) {
        model$n
      } else if (!is.null(model$residuals)) {
        length(model$residuals)
      } else if (!is.null(model$fitted.values)) {
        length(model$fitted.values)
      } else {
        NA_integer_
      }
    }, error = function(e) {
      NA_integer_
    })

    # Add model info
    coefs_with_info <- coefs %>%
      dplyr::mutate(
        # Get exponentiated coefficients (odds ratios for logit, incidence rate ratios for Poisson)
        exp_estimate = exp(estimate),
        exp_lower_ci = exp(estimate - 1.96 * std.error),
        exp_upper_ci = exp(estimate + 1.96 * std.error),
        dependent_var = y_var,
        # Get model family (logit or poisson)
        model_family = model$family$family,
        # Add number of observations
        n_observations = n_observations
      )

    return(coefs_with_info)
  })

  return(logit_results)
}
# Create enhanced plot of odds ratios / incidence rate ratios
create_effect_plot <- function(logit_results) {
  # Only proceed if we have results
  if (is.null(logit_results) || nrow(logit_results) == 0) {
    message("No results available for plotting")
    return(NULL)
  }

  # Create plot with enhanced styling
  effect_plot <- logit_results %>%
    dplyr::filter(term != "(Intercept)") %>%
    dplyr::mutate(
      # Improve variable labels
      term = dplyr::case_when(
        term == "ln_pc_def_inc" ~ "Log per-capita income",
        term == "pdef3" ~ "Spatial deflator",
        term == "hhag" ~ "Agricultural household",
        TRUE ~ term
      ),
      # Create model type label
      model_type = ifelse(model_family == "binomial", "Odds Ratio", "Incidence Rate Ratio"),
      # Create better labels for food insecurity measures
      dependent_var = dplyr::case_when(
        dependent_var == "worried" ~ "Worried about food",
        dependent_var == "unhealthy" ~ "Unable to eat healthy",
        dependent_var == "low_diversity" ~ "Low food diversity",
        dependent_var == "skip_meal" ~ "Skipped meals",
        dependent_var == "eat_less" ~ "Ate less than needed",
        dependent_var == "ran_out" ~ "Ran out of food",
        dependent_var == "went_hungry" ~ "Went hungry",
        dependent_var == "whole_day" ~ "Whole day without food",
        dependent_var == "totfoodinsec" ~ "Total food insecurity",
        TRUE ~ dependent_var
      ),
      # Create a factor for sorting outcomes by severity (most to least severe)
      dependent_var = forcats::fct_relevel(
        dependent_var,
        "Whole day without food", "Went hungry", "Skipped meals",
        "Ran out of food", "Ate less than needed", "Low food diversity",
        "Unable to eat healthy", "Worried about food", "Total food insecurity"
      )
    ) %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = exp_estimate,
        y = dependent_var,
        xmin = exp_lower_ci,
        xmax = exp_upper_ci,
        color = term,
        shape = model_type
      )
    ) +
    ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.5), size = 0.8) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
    ggplot2::scale_x_log10(
      breaks = c(0.5, 0.75, 1, 1.5, 2, 3, 4, 5),
      labels = c("0.5", "0.75", "1.0", "1.5", "2.0", "3.0", "4.0", "5.0")
    ) +
    # Use Tableau color palette for better differentiation
    ggthemes::scale_colour_tableau() +
    ggplot2::labs(
      title = "Effects of Economic Factors on Food Insecurity Measures",
      subtitle = "Values < 1 indicate reduced risk of food insecurity",
      x = "Effect Size (95% CI, log scale)",
      y = NULL, # Remove y-axis label since the categories are self-explanatory
      color = "Predictor",
      shape = "Model Type",
      caption = "Note: Odds ratios for binary outcomes, incidence rate ratio for count outcome"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 11, color = "gray40"),
      plot.caption = ggplot2::element_text(size = 9, color = "gray40"),
      axis.title.x = ggplot2::element_text(size = 12),
      axis.text.y = ggplot2::element_text(size = 11, face = "bold"),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.title = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = NA, color = "gray90")
    ) +
    # Add annotation to explain interpretation
    ggplot2::annotate(
      "text", x = 0.55, y = 1,
      label = "Lower risk",
      color = "darkgreen",
      fontface = "bold",
      size = 3.5
    ) +
    ggplot2::annotate(
      "text", x = 1.8, y = 1,
      label = "Higher risk",
      color = "darkred",
      fontface = "bold",
      size = 3.5
    )

  return(effect_plot)
}


run_fe_models <- function(data, dep_vars, id_var = "hhid", time_var = "mofd", cpi_var = "cpi_prov") {
  # Check for required packages
  if (!requireNamespace("survival", quietly = TRUE)) {
    install.packages("survival")
  }
  if (!requireNamespace("fixest", quietly = TRUE)) {
    install.packages("fixest")
  }

  # Load required packages
  library(survival)
  library(fixest)
  library(dplyr)
  library(purrr)
  library(glue)
  library(broom)

  # Check if required variables exist
  if (!all(c(id_var, time_var, cpi_var) %in% names(data))) {
    missing_vars <- setdiff(c(id_var, time_var, cpi_var), names(data))
    message(glue::glue("Variables not found: {paste(missing_vars, collapse = ', ')}"))
    return(NULL)
  }

  # Create and run models for each dependent variable
  fe_models <- purrr::map(dep_vars, function(y_var) {
    # Check if dependent variable exists
    if (!y_var %in% names(data)) {
      message(glue::glue("Variable {y_var} not found in data. Skipping."))
      return(NULL)
    }

    # Create formulas
    # For clogit (survival)
    f_clogit <- as.formula(glue::glue("{y_var} ~ {cpi_var} + strata({id_var})"))
    # For linear model (fixest)
    f_linear <- as.formula(glue::glue("{y_var} ~ {cpi_var} | {id_var}"))

    # Filter data for this specific variable
    data_filtered <- data %>%
      dplyr::filter(!is.na(!!rlang::sym(y_var)), !is.na(!!rlang::sym(cpi_var)))

    # Skip if too few observations
    if (nrow(data_filtered) < 10) {
      message(glue::glue("Insufficient data for fixed effects models of {y_var}"))
      return(NULL)
    }

    # Run logistic fixed effects model using clogit (equivalent to xtlogit with fe)
    logit_model <- tryCatch({
      survival::clogit(f_clogit, data = data_filtered)
    }, error = function(e) {
      message(glue::glue("Error in conditional logistic model for {y_var}: {e$message}"))
      return(NULL)
    })

    # Run linear fixed effects model (equivalent to xtreg with fe)
    linear_model <- tryCatch({
      fixest::feols(f_linear, data = data_filtered)
    }, error = function(e) {
      message(glue::glue("Error in linear FE model for {y_var}: {e$message}"))
      return(NULL)
    })

    # Return models as a list
    return(list(
      logit = logit_model,
      linear = linear_model
    ))
  })

  # Name the models list
  names(fe_models) <- dep_vars

  return(fe_models)
}

create_fe_linear_summary <- function(fe_models, food_insec) {
  # Create a list of linear models across different outcomes
  model_list <- list()

  for (outcome in food_insec) {
    if (!is.null(fe_models[[outcome]]) && !is.null(fe_models[[outcome]]$linear)) {
      model_list[[outcome]] <- fe_models[[outcome]]$linear
    }
  }

  # Only proceed if we have models
  if (length(model_list) == 0) {
    return(NULL)
  }

  # Format the column names to be more readable
  names(model_list) <- gsub("_", " ", names(model_list))
  names(model_list) <- stringr::str_to_title(names(model_list))

  # Create coefficient mapping with better labels
  coef_mapping <- c(
    "(Intercept)" = "Constant",
    "cpi_prov" = "Consumer Price Index"
  )

  # Create a comparative table for linear fixed effects models
  modelsummary(
    model_list,
    coef_map = coef_mapping,
    stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
    gof_map = c(
      "nobs",
      "adj.r.squared" = "Adj. R²",
      "within.r.squared" = "Within R²"
    ),
    title = "Household Fixed Effects Linear Models",
    notes = c(
      "* p < 0.1, ** p < 0.05, *** p < 0.01",
      "Standard errors clustered at household level"
    ),
    estimate = "{estimate}{stars} ({std.error})",
    statistic = NULL,
    output = "kableExtra"
  ) %>%
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      position = "center"
    ) %>%
    kableExtra::add_header_above(c(" " = 1, "Food Insecurity Outcomes" = length(model_list)))
}

create_fe_logit_summary_final <- function(fe_models, food_insec) {
  # Create a list to store model data
  model_results <- list()

  # Loop through each outcome
  for (outcome in food_insec) {
    if (!is.null(fe_models[[outcome]]) && !is.null(fe_models[[outcome]]$logit)) {
      # Get the model
      model <- fe_models[[outcome]]$logit

      # Try to extract directly from the model print output
      model_text <- capture.output(print(model))

      # Look for the coefficient line (typically contains "cpi_prov")
      coef_line <- model_text[grep("cpi_prov", model_text)]

      if (length(coef_line) > 0) {
        # Extract values using regular expressions
        coef_parts <- strsplit(trimws(coef_line), "\\s+")[[1]]

        if (length(coef_parts) >= 5) {
          # Typically format is: cpi_prov, coef, exp(coef), se(coef), z, p
          coef_val <- as.numeric(coef_parts[2])
          exp_coef <- as.numeric(coef_parts[3])
          se_val <- as.numeric(coef_parts[4])
          z_val <- as.numeric(coef_parts[5])
          p_val <- as.numeric(coef_parts[6])

          # Calculate 95% CI
          lower_ci <- exp(coef_val - 1.96 * se_val)
          upper_ci <- exp(coef_val + 1.96 * se_val)

          # Store results
          model_results[[outcome]] <- list(
            variable = outcome,
            estimate = coef_val,
            std.error = se_val,
            p.value = p_val,
            exp_estimate = exp_coef,
            exp_lower_ci = lower_ci,
            exp_upper_ci = upper_ci
          )
        }
      }
    }
  }

  # Convert results to a data frame
  or_data <- do.call(rbind, lapply(model_results, function(x) {
    data.frame(
      variable = x$variable,
      estimate = x$estimate,
      std.error = x$std.error,
      p.value = x$p.value,
      exp_estimate = x$exp_estimate,
      exp_lower_ci = x$exp_lower_ci,
      exp_upper_ci = x$exp_upper_ci,
      stringsAsFactors = FALSE
    )
  }))

  # Only proceed if we have data
  if (nrow(or_data) == 0) {
    return("No valid models found for table creation")
  }

  # Format the odds ratio table
  or_data <- or_data %>%
    dplyr::mutate(
      # Create more readable outcome names
      readable_var = dplyr::case_when(
        variable == "worried" ~ "Worried about food",
        variable == "unhealthy" ~ "Unable to eat healthy",
        variable == "low_diversity" ~ "Low food diversity",
        variable == "skip_meal" ~ "Skipped meals",
        variable == "eat_less" ~ "Ate less than needed",
        variable == "ran_out" ~ "Ran out of food",
        variable == "went_hungry" ~ "Went hungry",
        variable == "whole_day" ~ "Whole day without food",
        variable == "totfoodinsec" ~ "Total food insecurity",
        TRUE ~ variable
      ),
      # Add significance stars
      significance = dplyr::case_when(
        is.na(p.value) ~ "",
        p.value < 0.01 ~ "***",
        p.value < 0.05 ~ "**",
        p.value < 0.1 ~ "*",
        TRUE ~ ""
      ),
      # Format the odds ratio and CI
      odds_ratio_formatted = sprintf("%.2f%s (%.2f-%.2f)",
                                     exp_estimate, significance,
                                     exp_lower_ci, exp_upper_ci),
      # Format the standard error
      std_error_formatted = sprintf("%.3f", std.error)
    ) %>%
    # Only select the Food Insecurity Measure, Odds Ratio, and Std Error columns
    dplyr::select(readable_var, odds_ratio_formatted, std_error_formatted)

  # Rename columns for presentation
  names(or_data) <- c("Food Insecurity Measure", "Odds Ratio (95% CI)", "Std. Error")

  # Create table with row.names=FALSE to remove row numbers
  kableExtra::kable(
    or_data,
    caption = "Effect of Consumer Price Index (CPI) on Food Insecurity: Household Fixed Effects Logistic Models",
    row.names = FALSE  # This is the key change to remove row names
  ) %>%
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      position = "center"
    ) %>%
    kableExtra::add_footnote(
      c("* p < 0.1, ** p < 0.05, *** p < 0.01",
        "Odds ratios represent the effect of a one-unit increase in CPI on the likelihood of experiencing each food insecurity outcome",
        "Standard errors are robust and clustered at household level",
        "Models estimated using conditional logistic regression (clogit)"),
      notation = "symbol"
    )
}
