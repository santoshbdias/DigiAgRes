#'Está função serve para fazer o download de dados de estações da wunderground
#'
#'@description Função faz o download de dados meteorológicos wunderground.
#'
#'@param vector Caminho do arquivo do polígono vetorial
#'@param pathdow Valor da distancia entre os pontos em metros
#'
#'@examples
#'TopoData_download_to_vector("C:/Users/server_SantosDias/Downloads/Demilitacao_Area.kml",
#' "C:/Users/server_SantosDias/Downloads")
#'
#'
#'@author Santos Henrique Brant Dias
#'@return Raster do TopoData
#'@export


#rm(list = ls()); gc()

#vector <- "C:/Users/server_SantosDias/Downloads/Demilitacao_Area.kml"
#pathdow <- "C:/Users/server_SantosDias/Downloads"

TopoData_download_to_vector <- function(vector,pathdow){


  #sf, dplyr, stringr, terra)  # Instalar/ativar pacotes

  area <- st_read(vector, quiet = TRUE)

  kml_url <- "https://www.google.com/maps/d/u/0/kml?mid=1Yle0c2VU4waXo-Kzn0RBONZG9NgSYas&resourcekey&forcekml=1"

  kml_file <- tempfile(fileext = ".kml")
  if (!file.exists(kml_file)) {
    download.file(kml_url, destfile = kml_file, mode = "wb")
    tiles <- st_read(kml_file, quiet = TRUE)
    message("✅ Arquivo baixado com sucesso.")
  } else {
    message("⚠️ Arquivo já existe. Pulando o download.")
    tiles <- st_read(kml_file, quiet = TRUE)
  }

  if (st_crs(area) != st_crs(tiles)) {#Garantir que ambos estejam no mesmo CRS
    area <- st_transform(area, st_crs(tiles))
  }

  tiles_intersectados <- suppressMessages(tiles[st_intersects(tiles, area, sparse = FALSE), ])#Fazer interseção espacial

  result <- tiles_intersectados %>% #Mostrar resultado: código dos tiles + links de download
    select(tile_id = 1, link = 2)   # ajuste os nomes dos campos conforme seu shapefile

  html_text <- result$link[1] #Extrair texto HTML do campo "link"

  link_altitude <- str_extract(html_text, "http[^<]*ZN\\.zip")#Buscar o link que termina com "ZN.zip" (altitude)

  destino <- file.path(pathdow, basename(link_altitude))#Definir caminho para salvar

  if (!file.exists(destino)) {
    download.file(link_altitude, destfile = destino, mode = "wb")#Fazer o download
    unzip(destino, exdir = paste0(pathdow, "/TOPODATA_ALTITUDE"))#Descompactar o ZIP

  } else {
    message("✅ Arquivo ZIP já existe. Download ignorado.")
  }


  pasta_saida <- "C:/Users/server_SantosDias/Downloads/TOPODATA_ALTITUDE" #Caminho da pasta onde foi extraído

  arquivo_tif <- list.files(pasta_saida, pattern = "\\.tif$", full.names = TRUE) #Encontrar o arquivo .tif extraído

  if (length(arquivo_tif) == 0) { #Verificar se encontrou e abrir o raster
    stop("❌ Nenhum arquivo .tif foi encontrado na pasta descompactada.")
  }

  dem <- rast(arquivo_tif[1])#Abrir o raster

  plot(dem, main = "Modelo de Elevação (Topodata - Altitude)") #Visualizar

}


