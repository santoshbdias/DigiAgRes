#'Está função serve para fazer o download de dados de estações da wunderground
#'
#'@description Função faz o download do TOPODATA INPE. Pode ser feito o download das seguintes variavéis: Altitude, Declividade, RelevoSombreado, Orientação, FormaTerreno, DivisoresTalvegues, Curv.Vertical, Curv.Horizontal
#'
#'@param vector Caminho do arquivo do polígono vetorial
#'@param pathdow Valor da distancia entre os pontos em metros
#'
#'@importFrom sf st_read
#'@importFrom dplyr %>%
#'@importFrom terra rast
#'
#'@examples
#'Altitude <- TopoData_download_to_vector(vector = "C:/User/Downloads/area.kml", layer = "Altitude")
#'
#'@author Santos Henrique Brant Dias
#'@return Raster do TopoData
#'@export

TopoData_download_to_vector <- function(vector, layer = "Altitude"){

  if (inherits(vector, "sf")) {
    area <- vector
  } else {
    area <- sf::st_read(vector, quiet = TRUE)
  }

  kml_url <- "https://www.google.com/maps/d/u/0/kml?mid=1Yle0c2VU4waXo-Kzn0RBONZG9NgSYas&resourcekey&forcekml=1"

  kml_file <- tempfile(fileext = ".kml")
  if (!file.exists(kml_file)) {
    download.file(kml_url, destfile = kml_file, mode = "wb")
    tiles <- sf::st_read(kml_file, quiet = TRUE)
    message("✅ Arquivo  tiles baixado com sucesso.")
  } else {
    message("⚠️ Arquivo já existe. Pulando o download.")
    tiles <- sf::st_read(kml_file, quiet = TRUE)
  }

  if (sf::st_crs(area) != sf::st_crs(tiles)) {#Garantir que ambos estejam no mesmo CRS
    area <- sf::st_transform(area, sf::st_crs(tiles))
  }

  tiles_intersectados <- suppressMessages(tiles[sf::st_intersects(tiles, area, sparse = FALSE), ])#Fazer interseção espacial

  html_text <- tiles_intersectados$Description

  # Mapear layers para os sufixos
  sufixos <- c(
    Altitude = "ZN.zip",
    Declividade = "SN.zip",
    RelevoSombreado = "RS.zip",
    Orientacao = "ON.zip",
    FormaTerreno = "FT.zip",
    DivisoresTalvegues = "DD.zip",
    Curv.Vertical = "VN.zip",
    Curv.Horizontal = "HN.zip"
  )

  if (!layer %in% names(sufixos)) {
    stop("❌ Layer inválido. Use um dos nomes: ", paste(names(sufixos), collapse = ", "))
  }

  # Link ZIP certo
  link_zip <- stringr::str_extract(html_text, paste0("http[^<]*", sufixos[layer]))

  # Detectar pasta de Downloads
  downloads_dir <- switch(Sys.info()[["sysname"]],
                          "Windows" = file.path(Sys.getenv("USERPROFILE"), "Downloads"),
                          "Darwin"  = file.path(Sys.getenv("HOME"), "Downloads"),  # macOS
                          "Linux"   = file.path(Sys.getenv("HOME"), "Downloads")   # Linux
  )

  destino <- file.path(downloads_dir, basename(link_zip))#Definir caminho para salvar
  pasta_saida <- file.path(downloads_dir, "TOPODATA")

  if (!dir.exists(pasta_saida)) dir.create(pasta_saida, recursive = TRUE)

  # Nome base para buscar .tif
  prefixo <- tools::file_path_sans_ext(basename(destino))
  arquivo_tif <- list.files(
    pasta_saida,
    pattern = paste0("^", prefixo, "\\.tif$"),
    full.names = TRUE
  )

  # Se não existe o ZIP → baixa
  if (!file.exists(destino)) {
    message("⬇️ Baixando tile: ", basename(link_zip))
    download.file(link_zip, destfile = destino, mode = "wb", quiet = TRUE)
  } else {
    message("✅ Arquivo ZIP já existe. Download ignorado.")
  }

  # Se não existe o TIF correspondente → descompacta
  if (length(arquivo_tif) == 0) {
    message("📂 Descompactando: ", basename(destino))
    unzip(destino, exdir = pasta_saida)

    arquivo_tif <- list.files(
      pasta_saida,
      pattern = paste0("^", prefixo, "\\.tif$"),
      full.names = TRUE
    )
  }

  if (length(arquivo_tif) == 0) {
    stop("❌ Nenhum .tif correspondente foi encontrado após descompactar.")
  }

  # Abrir o raster certo
  dem <- terra::rast(arquivo_tif)#Abrir o raster

  return(dem)
}




