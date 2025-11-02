#'Está função serve para criar pontos a partir de de um poligono
#'
#'@description Função gera um grade pontos regulares para realização de análises, informações geradas a partir arquivo vetorial tipo polígono, que pode ser feito pelo Google Esrth Pro com um arquivo KML.
#'
#'@param dir_polygon Caminho do arquivo do polígono vetorial
#'@param dist Valor da distancia entre os pontos em metros
#'@param pt True ou FALSE para ver o plot do arquivo
#'
#'@examples
#'polygon_to_points_grid(dir_polygon = "./Downloads/Demilitacao_Area.kml",
#' dist = 100, pt = TRUE)
#'
#'@author Santos Henrique Brant Dias
#'@return Returns um arquivo vetorial (ex. KML)
#'@export


polygon_to_points_grid <- function(dir_polygon, dist, pt = TRUE, N = TRUE) {

  if (inherits(dir_polygon, "sf")) {
    pol <- dir_polygon
  } else if (is.character(dir_polygon)) {
    if (!file.exists(dir_polygon)) {
      stop(paste("Arquivo não encontrado:", dir_polygon)) }
    pol <- sf::st_read(dir_polygon, quiet = TRUE)
  } else {stop("Input inválido. Deve ser um objeto 'sf' ou um caminho (string) para um arquivo.")}

  if (!st_is_longlat(pol)) { #Verificar se está em coordenadas geográficas (longitude/latitude)
    cat("O KML não está em coordenadas geográficas.\n")
  } else {

    centroide <- base::suppressMessages((sf::st_centroid(sf::st_union(pol))))#Calcular centróide do polígono
    coords <- sf::st_coordinates(centroide) #obter coordenada central

    lon <- coords[1]
    lat <- coords[2]

    utm_zone <- base::floor((lon + 180) / 6) + 1 #Calcular zona UTM

    if (lat >= 0) {#Definir EPSG com base no hemisfério
      epsg_code <- 32600 + utm_zone  # Hemisfério Norte
    } else {
      epsg_code <- 32700 + utm_zone  # Hemisfério Sul
    }
    #    cat("🗺️ Zona UTM:", utm_zone, "\n")
    #    cat("📌 EPSG correspondente:", epsg_code, "\n")

    if (st_is_longlat(pol)) {
      pol <- sf::st_transform(pol, epsg_code)
    }
  }

  grid_spacing <- dist
  grid <- sf::st_make_grid(pol,
                       cellsize = grid_spacing,
                       what = "centers",
                       square = TRUE)

  grid_points <- sf::st_sf(geometry = grid)
  grid_points <- grid_points[st_within(grid_points, pol, sparse = FALSE), ]

  if (pt) {
    plot(sf::st_geometry(pol), border = "blue")
    plot(sf::st_geometry(grid_points), col = "red", pch = 20, add = TRUE)
  }

  if (N) {
    grid_points$ID_Ponto <- sprintf("%02d", seq_len(nrow(grid_points)))
    names(grid_points)[names(grid_points) == "ID_Ponto"] <- "Name"
  }

  return(grid_points)
}





