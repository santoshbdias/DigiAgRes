% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/polygon_to_random_points.R
\name{polygon_to_random_points}
\alias{polygon_to_random_points}
\title{Está função serve para criar pontos a partir de de um poligono}
\usage{
polygon_to_random_points(dir_polygon, Npoints, min_dist, plot = FALSE)
}
\arguments{
\item{dir_polygon}{Caminho do arquivo do polígono vetorial}

\item{plot}{True ou FALSE para ver o plot do arquivo}

\item{dist}{Valor da distancia entre os pontos em metros}
}
\value{
Returns um arquivo vetorial (ex. KML)
}
\description{
Função gera um grade pontos regulares para realização de análises, informações geradas a partir arquivo vetorial tipo polígono, que pode ser feito pelo Google Esrth Pro com um arquivo KML.
}
\examples{
polygon_to_random_points(dir_polygon = "./Downloads/Demilitacao_Area.kml",
dist = 100, plot = TRUE)

}
\author{
Santos Henrique Brant Dias
}
