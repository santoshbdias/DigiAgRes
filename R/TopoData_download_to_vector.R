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

TopoData_download_to_vector <- function(vector, layer = "Declividade"){

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

  for (px in 1:length(destino)) {
    prefixo <- tools::file_path_sans_ext(basename(destino[px]))

    arquivo_tif <- list.files(
      pasta_saida,
      pattern = paste0("^", prefixo, "\\.tif$"),
      full.names = TRUE
    )

    if (length(arquivo_tif) == 0) {
    # Excluir arquivos zip corrompidos
    if (file.exists(destino[px])) {
      base::file.remove(destino[px])
      base::message("Arquivo ",prefixo,'.zip'," removido")
    }

    # Se não existe o ZIP → baixa
    if (!file.exists(destino[px])) {
      message("⬇️ Baixando tile: ", basename(link_zip[px]))
      utils::download.file(link_zip[px], destfile = destino[px], mode = "wb", quiet = TRUE)
    }

    # Se não existe o TIF correspondente → descompacta

    message("📂 Descompactando: ", basename(destino[px]))
    utils::unzip(destino[px], exdir = pasta_saida)
    }
  }

  arquivos_tifs_Vector <- list.files(
    pasta_saida,
    pattern = paste0("^(", paste0(tools::file_path_sans_ext(basename(destino)), collapse = "|"), ")\\.tif$"),
    full.names = TRUE
  )

  # Abre todos como lista de SpatRaster
  rasters <- lapply(arquivos_tifs_Vector, terra::rast)

  # Verifica quantidade e faz merge se necessário
  if (length(rasters) > 1) {
    # Mais de um raster → faz merge
    dem <- do.call(terra::merge, rasters)
  } else if (length(rasters) == 1) {
    # Apenas um raster → usa direto
    dem <- rasters[[1]]
  } else {
    stop("Nenhum arquivo raster encontrado na pasta destino, TOPODATA em download!")
  }

  terra::crs(dem) <- "EPSG:4618"

  return(dem)
}




