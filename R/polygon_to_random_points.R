#'Está função serve para criar pontos a partir de de um poligono
#'
#'@description Função gera um grade pontos regulares para realização de análises, informações geradas a partir arquivo vetorial tipo polígono, que pode ser feito pelo Google Esrth Pro com um arquivo KML.
#'
#'
#'@param dir_polygon Caminho do arquivo do polígono vetorial
#'@param dist Valor da distancia entre os pontos em metros
#'@param plot True ou FALSE para ver o plot do arquivo
#'
#'@importFrom sf st_read
#'@importFrom sf st_transform
#'@importFrom sf st_make_grid
#'@importFrom sf st_sf
#'@importFrom sf st_write
#'@importFrom sf st_read
#'
#'@examples
#'polygon_to_random_points(dir_polygon = "./Downloads/Demilitacao_Area.kml",
#' dist = 100, plot = TRUE)
#'
#'@export
#'@return Returns um arquivo vetorial (ex. KML)
#'@author Santos Henrique Brant Dias

polygon_to_random_points <- function(dir_polygon,Npoints,min_dist, plot = FALSE) {

  pol <- sf::st_read(dir_polygon, quiet = TRUE)

  max_pontos_teoricos <- suppressMessages(as.numeric(sf::st_area(pol) / (pi * (min_dist^2))))

  if (Npoints > floor(max_pontos_teoricos)) {
    stop(paste0('Número de pontos solicitado (',Npoints,
                ') excede o máximo teórico possível (',floor(max_pontos_teoricos),
                ") para a distância mínima definida."))
  }

  if (!st_is_longlat(pol)) { #Verificar se está em coordenadas geográficas (longitude/latitude)
    cat("O KML não está em coordenadas geográficas.\n")
  } else {

    centroide <- suppressMessages((st_centroid(st_union(pol))))#Calcular centróide do polígono
    coords <- st_coordinates(centroide) #obter coordenada central

    lon <- coords[1]
    lat <- coords[2]

    utm_zone <- floor((lon + 180) / 6) + 1 #Calcular zona UTM

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

  generate_random_points <- function(polygon, n, min_dist, max_attempts = 10000) {
    min_dist <- set_units(min_dist, "m")
    selected <- list()
    attempts <- 0

    while (length(selected) < n && attempts < max_attempts) {
      attempts <- attempts + 1
      p <- st_sample(polygon, size = 1, type = "random")

      if (length(selected) == 0 || all(st_distance(p, do.call(rbind, selected)) > min_dist)) {
        selected[[length(selected) + 1]] <- st_sf(geometry = p)
      }
    }

    if (length(selected) < n) {
      warning(sprintf("Apenas %d pontos foram gerados após %d tentativas.", length(selected), max_attempts))
    }

    sf::st_as_sf(do.call(rbind, selected))
  }

  set.seed(251292)
  pontos_aleatorios <- generate_random_points(pol, n = Npoints, min_dist)

  if (plot) {
    plot(st_geometry(pol), border = "blue")
    plot(st_geometry(pontos_aleatorios), col = "red", pch = 20, add = TRUE)
  }
}





