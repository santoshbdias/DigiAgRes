#'Está função serve para fazer o download de dados de estações da wunderground
#'
#'@description Função faz o download do TOPODATA INPE. Pode ser feito o download das seguintes variavéis: Altitude, Declividade, RelevoSombreado, Orientação, FormaTerreno, DivisoresTalvegues, Curv.Vertical, Curv.Horizontal
#'
#'@param vector Caminho do arquivo do polígono vetorial
#'@param layer Valor da distancia entre os pontos em metros
#'
#'@importFrom sf st_read
#'@importFrom dplyr %>%
#'@importFrom terra rast
#'@importFrom rstac stac
#'@importFrom rstac stac_search
#'@importFrom rstac post_request
#'@importFrom rstac items_fetch
#'@importFrom rstac items_length
#'@importFrom rstac assets_url
#'@importFrom rstac assets_select
#'
#'@examples
#' if (interactive()) {
#'Altitude <- TopoData_download_to_vector(vector = "C:/User/Downloads/area.kml", layer = "Altitude")
#'}
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


  # ============================================================
  # Consultar tiles TOPODATA diretamente pelo STAC do INPE
  # ============================================================

  # STAC trabalha com coordenadas geográficas
  area_wgs84 <- sf::st_transform(
    vector,
    sf::st_crs(4326)
  )

  # Bounding box da área
  bb <- sf::st_bbox(area_wgs84)

  bbox <- c(
    unname(bb["xmin"]),
    unname(bb["ymin"]),
    unname(bb["xmax"]),
    unname(bb["ymax"])
  )

  message(
    "📍 Bounding box: ",
    paste(round(bbox, 6), collapse = " | ")
  )

  # Catálogo STAC do INPE
  catalog <- rstac::stac(
    "https://data.inpe.br/bdc/stac/v1/"
  )

  # Buscar tiles TOPODATA que intersectam a área
  consulta <- catalog |>
    rstac::stac_search(
      collections = "topodata-1",
      bbox = bbox,
      limit = 1000
    ) |>
    rstac::post_request()

  # Carregar os itens encontrados
  consulta <- rstac::items_fetch(
    consulta
  )

  n_tiles <- rstac::items_length(consulta)

  if (n_tiles == 0) {
    stop(
      "❌ Nenhum tile TOPODATA encontrado para a área informada."
    )
  }

  message("✅ Tiles encontrados: ", n_tiles)






  # Mapear layers para os sufixos
  sufixos <- c(
    Altitude = "ZN",
    Declividade = "SN",
    RelevoSombreado = "RS",
    Orientacao = "ON",
    FormaTerreno = "FT",
    DivisoresTalvegues = "DD",
    Curv.Vertical = "VN",
    Curv.Horizontal = "HN"
  )








  # Asset correspondente à variável escolhida
  asset <- sufixos[[layer]]

  message("🗺️ Variável TOPODATA: ", layer)
  message("🔹 Asset STAC: ", asset)

  # Selecionar o asset nos tiles encontrados
  consulta_asset <- rstac::assets_select(
    consulta,
    asset_names = asset
  )

  # Obter URLs dos arquivos
  link_tif <- rstac::assets_url(
    consulta_asset,
    asset_names = asset
  )

  link_tif <- unique(link_tif)

  if (length(link_tif) == 0 || all(is.na(link_tif))) {
    stop(
      "❌ Não foi encontrado o asset ",
      asset,
      " para os tiles selecionados."
    )
  }

  message(
    "⬇️ Assets encontrados: ",
    length(link_tif)
  )


  # Detectar pasta de Downloads
  downloads_dir <- switch(Sys.info()[["sysname"]],
                          "Windows" = file.path(Sys.getenv("USERPROFILE"), "Downloads"),
                          "Darwin"  = file.path(Sys.getenv("HOME"), "Downloads"),  # macOS
                          "Linux"   = file.path(Sys.getenv("HOME"), "Downloads")   # Linux
  )

  pasta_saida <- file.path(
    downloads_dir,
    "TOPODATA"
  )

  if (!dir.exists(pasta_saida)) {
    dir.create(
      pasta_saida,
      recursive = TRUE
    )
  }

  # ============================================================
  # Download dos tiles
  # ============================================================

  destino <- file.path(
    pasta_saida,
    basename(
      sub("\\?.*$", "", link_tif)
    )
  )

  for (px in seq_along(link_tif)) {

    # Garantir nome do arquivo
    destino[px] <- file.path(
      pasta_saida,
      basename(
        sub("\\?.*$", "", link_tif[px])
      )
    )

    if (!file.exists(destino[px])) {

      message(
        "⬇️ Baixando tile: ",
        basename(destino[px])
      )

      utils::download.file(
        link_tif[px],
        destfile = destino[px],
        mode = "wb",
        quiet = TRUE
      )

    } else {

      message(
        "✔ Tile já existe: ",
        basename(destino[px])
      )
    }
  }



  arquivos_tifs_Vector <- destino[
    file.exists(destino)
  ]


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




