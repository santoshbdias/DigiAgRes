# #' Gera gráfico de radiação solar diária com base em KML e NASA POWER
# #'
# #' @description
# #' Esta função extrai o centroide de uma área contida em um arquivo .kml e gera um gráfico
# #' de radiação solar diária (W/m²) ao longo do ano, com destaque para uma data específica (evento).
# #'
# #' @param kml_path Caminho para o arquivo .kml com a área geográfica de interesse
# #' @param ano Ano a ser analisado (default = ano atual)
# #' @param data_evento Data do evento climático de interesse para destaque (ex: "2024-08-27")
# #' @param cor_evento Cor do marcador da data do evento (padrão = "red")
# #'
# #' @return Gráfico ggplot com radiação solar diária
# #'
# #' @importFrom sf st_read st_geometry st_centroid st_coordinates
# #' @importFrom httr GET content
# #' @importFrom jsonlite fromJSON
# #' @importFrom dplyr tibble mutate filter arrange
# #' @importFrom lubridate ymd
# #' @importFrom ggplot2 ggplot aes geom_line geom_vline geom_text scale_x_date labs theme_minimal
# #'
# #' @examples
# #' grafico_radiacao_kml("C:/caminho/area.kml", ano = 2024, data_evento = "2024-08-27")
# #'
# #' @author Santos Henrique Brant Dias
# #' @export
#' grafico_radiacao_kml <- function(kml_path,
#'                                  ano = as.numeric(format(Sys.Date(), "%Y")),
#'                                  data_evento,
#'                                  cor_evento = "red") {
#'
#'   if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
#'   pacman::p_load(sf, httr, jsonlite, dplyr, lubridate, ggplot2)
#'
#'   # Ler coordenadas do KML
#'   area <- st_read(kml_path, quiet = TRUE)
#'   coords <- st_centroid(st_geometry(area)) |> st_coordinates()
#'   lat <- coords[2]
#'   lon <- coords[1]
#'
#'   # Baixar radiação da NASA POWER (ALLSKY_SFC_SW_DWN)
#'   url <- paste0(
#'     "https://power.larc.nasa.gov/api/temporal/daily/point?",
#'     "parameters=ALLSKY_SFC_SW_DWN",
#'     "&community=AG",
#'     "&longitude=", lon,
#'     "&latitude=", lat,
#'     "&start=", ano, "0101",
#'     "&end=", ano, "1231",
#'     "&format=JSON"
#'   )
#'
#'   resposta <- httr::GET(url)
#'   dados <- fromJSON(content(resposta, as = "text"))
#'
#'   if (is.null(dados$properties$parameter$ALLSKY_SFC_SW_DWN)) {
#'     stop("❌ Dados de radiação não disponíveis para o local/ano informado.")
#'   }
#'
#'   datas <- as.Date(names(dados$properties$parameter$ALLSKY_SFC_SW_DWN), format = "%Y%m%d")
#'   valores <- as.numeric(dados$properties$parameter$ALLSKY_SFC_SW_DWN)
#'
#'   rad <- tibble(data = datas, radiacao = valores) %>%
#'     filter(!is.na(data), radiacao != -999)
#'
#'   # Dados do evento
#'   rad_evento <- rad %>% filter(data == as.Date(data_evento))
#'
#'   # Gráfico
#'   ggplot(rad, aes(x = data, y = radiacao)) +
#'     geom_line(color = "black", size = 1) +
#'     geom_vline(xintercept = as.Date(data_evento), color = cor_evento, linetype = "dashed", size = 1) +
#'     geom_text(
#'       data = rad_evento,
#'       aes(x = data, y = radiacao, label = paste0(round(radiacao, 1), " W/m²")),
#'       vjust = -1, hjust = -0.05, color = cor_evento, size = 6
#'     ) +
#'     scale_x_date(date_breaks = "1 month", date_labels = "%b") +
#'     labs(
#'       title = paste("Radiação Solar Diária em", ano),
#'       subtitle = paste("Evento climático em", format(as.Date(data_evento), "%d/%m/%Y")),
#'       x = NULL, y = "W/m²"
#'     ) +
#'     theme_minimal(base_size = 14)
#' }
