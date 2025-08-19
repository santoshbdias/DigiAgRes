# #' Gera gráfico com temperaturas diárias (mínima, média e máxima) com base em KML e NASA POWER
# #'
# #' @description
# #' Esta função lê um arquivo KML da área de interesse, extrai as coordenadas do centroide
# #' e baixa dados de temperatura diária da NASA POWER, gerando um gráfico com linhas de temperatura
# #' mínima, média e máxima ao longo do ano, destacando uma data de evento.
# #'
# #' @param kml_path Caminho para o arquivo .kml da área
# #' @param ano Ano para o qual os dados serão obtidos (default: ano atual)
# #' @param data_evento Data do evento climático para destaque
# #'
# #' @return Gráfico ggplot com temperaturas mín, média e máxima
# #'
# #' @importFrom sf st_read st_geometry st_centroid st_coordinates
# #' @importFrom httr GET content
# #' @importFrom jsonlite fromJSON
# #' @importFrom dplyr tibble mutate filter arrange
# #' @importFrom lubridate ymd
# #' @importFrom ggplot2 ggplot aes geom_line geom_vline scale_x_date labs theme_minimal
# #'
# #' @examples
# #' grafico_temperatura_kml("area.kml", ano = 2024, data_evento = "2024-08-27")
# #'
# #' @author Santos Henrique Brant Dias
# #' @export
#'
#' grafico_temperatura_kml <- function(kml_path, ano = as.numeric(format(Sys.Date(), "%Y")), data_evento) {
#'   if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
#'   pacman::p_load(sf, httr, jsonlite, dplyr, lubridate, ggplot2)
#'
#'   # Coordenadas do centroide
#'   area <- st_read(kml_path, quiet = TRUE)
#'   coords <- st_centroid(st_geometry(area)) |> st_coordinates()
#'   lat <- coords[2]
#'   lon <- coords[1]
#'
#'   # Consulta de temperatura diária (mín, média, máx)
#'   url <- paste0(
#'     "https://power.larc.nasa.gov/api/temporal/daily/point?",
#'     "parameters=T2M,T2M_MIN,T2M_MAX",
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
#'   if (is.null(dados$properties$parameter$T2M)) {
#'     stop("❌ Dados de temperatura não disponíveis para o ano e local.")
#'   }
#'
#'   # Construção do data.frame
#'   datas <- as.Date(names(dados$properties$parameter$T2M), format = "%Y%m%d")
#'   # Construção do data.frame com remoção de valores inválidos (-999)
#'   temp <- tibble(
#'     data = datas,
#'     Tmin = as.numeric(dados$properties$parameter$T2M_MIN),
#'     Tmed = as.numeric(dados$properties$parameter$T2M),
#'     Tmax = as.numeric(dados$properties$parameter$T2M_MAX)
#'   ) %>%
#'     filter(
#'       !is.na(data),
#'       Tmin != -999, Tmed != -999, Tmax != -999
#'     )
#'
#'   # Filtra as temperaturas no dia do evento
#'   temp_evento <- temp %>% filter(data == as.Date(data_evento))
#'
#'   # Gráfico
#'   ggplot(temp, aes(x = data)) +
#'     geom_line(aes(y = Tmin), color = "blue", size = 1, linetype = "dashed") +
#'     geom_line(aes(y = Tmed), color = "black", size = 1) +
#'     geom_line(aes(y = Tmax), color = "red", size = 1, linetype = "twodash") +
#'     geom_vline(xintercept = as.Date(data_evento), color = "darkred", linetype = "longdash", size = 1) +
#'     # ➕ Adiciona texto com os valores
#'     geom_text(
#'       data = temp_evento,
#'       aes(x = data, y = Tmin, label = paste0("Tmin: ", round(Tmin, 1), "°C")),
#'       hjust = -0.1, vjust = 1.5, color = "blue", size = 5
#'     ) +
#'     geom_text(
#'       data = temp_evento,
#'       aes(x = data, y = Tmed, label = paste0("Tmed: ", round(Tmed, 1), "°C")),
#'       hjust = -0.1, vjust = -0.5, color = "black", size = 5
#'     ) +
#'     geom_text(
#'       data = temp_evento,
#'       aes(x = data, y = Tmax, label = paste0("Tmax: ", round(Tmax, 1), "°C")),
#'       hjust = -0.1, vjust = -1.5, color = "red", size = 5
#'     ) +
#'     scale_x_date(date_breaks = "1 month", date_labels = "%b") +
#'     labs(
#'       title = paste("Temperaturas diárias em", format(as.Date(data_evento), "%Y")),
#'       subtitle = paste("Evento climático em", format(as.Date(data_evento), "%d/%m/%Y")),
#'       x = NULL, y = "Temperatura (°C)"
#'     ) +
#'     theme_minimal(base_size = 14)
#'
#' }
