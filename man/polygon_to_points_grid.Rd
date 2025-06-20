% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/polygon_to_points_grid.R
\name{polygon_to_points_grid}
\alias{polygon_to_points_grid}
\title{Está função serve para criar pontos a partir de de um poligono}
\usage{
polygon_to_points_grid(dir_polygon, dist, plot = FALSE)
}
\arguments{
\item{dir_polygon}{Caminho do arquivo do polígono vetorial}

\item{dist}{Valor da distancia entre os pontos em metros}

\item{plot}{True ou FALSE para ver o plot do arquivo}
}
\value{
Returns um arquivo vetorial (ex. KML)
}
\description{
Função gera um grade pontos regulares para realização de análises, informações geradas a partir arquivo vetorial tipo polígono, que pode ser feito pelo Google Esrth Pro com um arquivo KML.
}
\examples{
polygon_to_points_grid(dir_polygon = "./Downloads/Demilitacao_Area.kml",
dist = 100, plot = TRUE)

}
\author{
Santos Henrique Brant Dias
}
