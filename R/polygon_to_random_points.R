#'Está função serve para criar pontos a partir de de um poligono
#'
#'@description Função gera um grade pontos regulares para realização de análises, informações geradas a partir arquivo vetorial tipo polígono, que pode ser feito pelo Google Esrth Pro com um arquivo KML.
#'
#'@param dir_polygon Caminho do arquivo do polígono vetorial
#'@param dist Valor da distancia entre os pontos em metros
#'@param pt True ou FALSE para ver o plot do arquivo
#'
#'@importFrom units set_units
#'@import sf
#'
#'@examples
#'polygon_to_random_points(dir_polygon = "./Downloads/Demilitacao_Area.kml",
#' dist = 100, pt = TRUE)
#'
#'@author Santos Henrique Brant Dias
#'@return Returns um arquivo vetorial (ex. KML)
#'@export

polygon_to_random_points <- function(polygon, Npoints, min_dist, borda=20, pt = TRUE, N = TRUE) {

  if (inherits(vector, "sf")) {
    pol <- vector
  } else {
    pol <- sf::st_read(vector, quiet = TRUE)
  }

  max_pontos_teoricos <- suppressMessages(base::as.numeric(sf::st_area(pol))/(pi*(min_dist^2))+5)

  if (Npoints > floor(max_pontos_teoricos)) {
    stop(paste0('Número de pontos solicitado (',Npoints,
                ') excede o máximo teórico possível (',floor(max_pontos_teoricos),
                ") para a distância mínima definida."))
  }

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

    if (sf::st_is_longlat(pol)) {
      pol <- sf::st_transform(pol, epsg_code)
    }
  }


  generate_random_points <- function(polygon, n, min_dist, max_attempts = 10000) {
    min_dist <- units::set_units(min_dist, "m")
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

  pol2 <- sf::st_buffer(pol, -borda)
  #set.seed(251292)
  pontos_aleatorios <- generate_random_points(pol2, n = Npoints, min_dist)

  if (plot) {
    plot(sf::st_geometry(pol), border = "blue")
    plot(sf::st_geometry(pontos_aleatorios), col = "red", pch = 20, add = TRUE)
  }

  if (N) {
    grid_points$ID_Ponto <- sprintf("%02d", seq_len(nrow(grid_points)))
    names(grid_points)[names(grid_points) == "ID_Ponto"] <- "Name"
  }

  return(pontos_aleatorios)
}





