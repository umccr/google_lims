#!/usr/bin/env Rscript

# Run this script from the root of the workflowr project to add the dashboard to the workflowr website.

library(rmarkdown)
render("dashboard/dashboard.Rmd")
file.rename("dashboard/dashboard.html", "docs/dashboard.html")
