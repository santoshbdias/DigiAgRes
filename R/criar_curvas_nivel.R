#' Gera curvas de nível a partir de um raster de altitude e um polígono (KML/SF)
#'
#' @title Curvas de nível com buffer automático (em metros) e recorte pelo polígono
#'
#' @description
#' Esta função gera curvas de nível (contornos) de um raster de altitude.
#' Aplica buffer em torno da área de interesse, corta e mascara o raster,
#' e retorna um objeto `sf` com as curvas de nível no CRS WGS84 UTM.
#'
#' @param raster_altitude Raster de entrada (`SpatRaster`) ou caminho para arquivo raster (.tif)
#' @param kml Objeto `sf` ou caminho/URL para arquivo KML com a área de interesse
#' @param buffer_dist Distância do buffer em metros (padrão = 200)
#' @param intervalo Intervalo das curvas de nível em metros (padrão = 5)
#'
#' @return Objeto `sf` com as curvas de nível e atributo `elev`
#'
#' @importFrom terra rast crs vect crop mask as.contour global project
#' @importFrom sf st_read st_transform st_buffer st_union st_geometry st_centroid st_coordinates
#'
#' @examples
#'  \dontrun{
#' curvas <- criar_curvas_nivel(raster_altitude="dem_sad69.tif", kml="area.kml", intervalo=10, buffer_dist=500, ajust = T)
#'}
#'
#' @section Requisitos:
#' Pacotes: `sf`, `terra`.
#'
#' @note
#' - Para rasters muito grandes, considere recortar previamente para melhorar desempenho.
#' - Se o raster tiver valores `NA` extensos na área, alguns níveis podem não gerar linhas.
#'
#' @seealso [terra::as.contour()], [sf::st_buffer()], [terra::mask()]
#'
#' @author Santos Henrique Brant Dias
#' @export

criar_curvas_nivel <- function(raster_altitude, kml, intervalo = 1, buffer_dist = 200, ajust = T) {

  if (inherits(raster_altitude, "SpatRaster")) {
    r <- raster_altitude
  } else if (is.character(raster_altitude)){
    r <- terra::rast(raster_altitude)
  } else {
    stop("O objeto informado não é um raster válido nem um caminho para arquivo raster.")
  }

  terra::crs(r) <- "EPSG:4618"

  r_wgs84 <- terra::project(r, "EPSG:4326")# Reprojetar para WGS84

  # --- Ler área (sf ou KML) ---
  if (inherits(kml, "sf")) {
    area <- kml
  } else if (is.character(kml)) {
    area <- sf::st_read(kml, quiet = TRUE)
  } else {
    stop("`kml` deve ser caminho/URL para .kml ou um objeto `sf`.")
  }
  if (nrow(area) == 0) stop("Área vazia no KML/sf.")

  area <- sf::st_transform(area, terra::crs(r_wgs84))

  # --- Transformar área para mesmo CRS do raster (UTM WGS84) e aplicar buffer ---
  area_buf <- sf::st_buffer(area, buffer_dist)

  # --- Cortar e mascarar raster ---
  buf_vect <- terra::vect(area_buf)
  r_crop <- terra::crop(r_wgs84, buf_vect)
  r_buf <- terra::mask(r_crop, buf_vect)

  r_buf <- terra::project(r_buf, "EPSG:32722")

  r_buf <- terra::disagg(r_buf, fact = c(30,30), method = "bilinear")

  if (ajust==T){
    area <- sf::st_transform(area, terra::crs(r_buf))

    vect.area <- terra::vect(area)
    r_mask <- terra::crop(r_buf, vect.area)
    r_mask <- terra::mask(r_mask, vect.area)
  } else {
    r_mask <- r_buf
  }

  # Níveis das curvas de nível
  min_val <- terra::global(r_mask, "min", na.rm = TRUE)[1,1]
  max_val <- terra::global(r_mask, "max", na.rm = TRUE)[1,1]

  if (is.na(min_val) || is.na(max_val)) stop("Sem valores válidos no raster após máscara.")
  if (max_val <= min_val) stop("Intervalo de elevação inválido no raster recortado.")

  from <- floor(min_val / intervalo) * intervalo
  to   <- ceiling(max_val / intervalo) * intervalo
  lvls <- seq(from, to, by = intervalo)

  # Gerar curvas de nível
  cont_spv <- terra::as.contour(r_mask, levels = lvls)
  curvas_sf <- sf::st_as_sf(cont_spv)

  # Padronizar nome do atributo de cota
  if ("level" %in% names(curvas_sf)) {
    names(curvas_sf)[names(curvas_sf) == "level"] <- "elev"
  } else if ("value" %in% names(curvas_sf)) {
    names(curvas_sf)[names(curvas_sf) == "value"] <- "elev"
  }
  return(curvas_sf)
}
