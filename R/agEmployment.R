#' @title agEmployment
#' @description returns employment in crop+livestock production from MAgPIE results
#'
#' @export
#'
#' @param gdx GDX file
#' @param type "absolute" for total number of people employed, "share" for share out of working age population
#' @param detail if TRUE, employment is disaggregated to crop and livestock production, if FALSE only aggregated
#' employment is reported
#' @param level spatial aggregation to report employment ("iso", "reg", "glo" or "regglo",
#' if type is "absolute" also "grid")
#' @param file a file name the output should be written to using write.magpie
#' @param dir for gridded outputs: magpie output directory which contains a mapping file (rds or spam) disaggregation
#' @return employment in agriculture as absolute value or as percentage of working age population
#' @author Debbora Leip
#' @importFrom luscale superAggregate
#' @examples
#' \dontrun{
#' x <- agEmployment(gdx)
#' }

agEmployment <- function(gdx, type = "absolute", detail = TRUE, level = "reg", file = NULL, dir = ".") {

  agEmpl <- readGDX(gdx, "ov36_employment", select = list(type = "level"), react = "silent")

  if (level != "grid") {
    workingAge <- c("15--19", "20--24", "25--29", "30--34", "35--39", "40--44", "45--49", "50--54", "55--59", "60--64")
    population <- dimSums(population(gdx, level = level, age = TRUE, dir = dir)[, , workingAge], dim = 3)
  }

  # split into crop and livestock
  if (isTRUE(detail)) {
    laborCostsKcr <- setNames(factorCosts(gdx, products = "kcr", level = "reg")[, , "labor_costs", drop = TRUE], "kcr")
    laborCostsKli <- setNames(factorCosts(gdx, products = "kli", level = "reg")[, , "labor_costs", drop = TRUE], "kli")
    shares <- mbind(laborCostsKcr, laborCostsKli) / collapseDim(laborCostsKcr + laborCostsKli)

    agEmpl <- agEmpl * shares
  }

  # labor costs as disaggregation weight
  if (level %in% c("grid", "iso")) {
    weightKcr <- dimSums(laborCosts(gdx, products = "kcr", level = level, dir = dir), dim = 3)
    weightKli <- dimSums(laborCosts(gdx, products = "kli", level = level, dir = dir), dim = 3)
    if (isTRUE(detail)) {
      weight <- mbind(setNames(weightKcr, "kcr"), setNames(weightKli, "kli"))
    } else {
      weight <- weightKcr + weightKli
    }
  } else {
    weight <- NULL
  }

  if (!is.null(agEmpl)) {
    x <- gdxAggregate(gdx, agEmpl, weight = weight, to = level, absolute = TRUE, dir = dir)
    if (type == "share") {
      if (level == "grid") x <- NULL else x <- (x / population) * 100
    }
  } else { # for MAgPIE versions before implementation of employment return NULL
    x <- NULL
  }

  out(x, file)
}
