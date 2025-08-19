# #' Gera gráfico de precipitação diária comparando múltiplos anos com base em um KML
# #'
# #' @description
# #' Esta função lê um arquivo KML contendo a área de interesse, extrai o centroide, consulta
# #' os dados climáticos diários da NASA POWER (precipitação) e gera um gráfico com colunas diárias
# #' de precipitação comparando os anos selecionados em uma mesma linha temporal (jan a dez).
# #'
# #' @param kml_path Caminho completo para o arquivo .kml da área de interesse
# #' @param data_evento Data do evento para destacar no gráfico (ex: geada)
# #' @param anos Vetor com os anos a serem comparados (default: últimos 6 anos)
# #' @param cor_evento Cor do ponto do evento no gráfico (padrão = "red")
# #'
# #' @return Gráfico ggplot2 com precipitação diária colorida por ano
# #'
# #' @importFrom sf st_read st_geometry st_centroid st_coordinates
# #' @importFrom httr GET content
# #' @importFrom jsonlite fromJSON
# #' @importFrom dplyr filter arrange mutate %>% tibble
# #' @importFrom ggplot2 ggplot aes geom_col geom_point scale_x_date scale_fill_manual labs theme_minimal theme
# #' @importFrom lubridate ymd
# #' @importFrom purrr map_dfr
# #'
# #' @examples
# #' grafico_precipitacao_diaria_kml(
# #'   kml_path = "C:/caminho/area.kml",
# #'   data_evento = "2025-06-20"
# #' )
# #'
# #' @author Santos Henrique Brant Dias
# #' @export
#
# grafico_precipitacao_diaria_kml <- function(kml_path, data_evento,
#                                             anos = (as.numeric(format(Sys.Date(), "%Y")) - 5):as.numeric(format(Sys.Date(), "%Y")),
#                                             cor_evento = "red") {
#   if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
#   pacman::p_load(sf, httr, jsonlite, lubridate, dplyr, ggplot2, purrr)
#
#'   # Leitura do KML e centroide
#'   area <- st_read(kml_path, quiet = TRUE)
#'   centroide <- st_centroid(st_geometry(area)) |> st_coordinates()
#'   lat <- centroide[2]
#'   lon <- centroide[1]
#'
#'   # Função interna de coleta de dados
#'   baixar_precipitacao <- function(ano, lat, lon) {
#'     url <- paste0(
#'       "https://power.larc.nasa.gov/api/temporal/daily/point?",
#'       "parameters=PRECTOT",
#'       "&community=AG",
#'       "&longitude=", lon,
#'       "&latitude=", lat,
#'       "&start=", ano, "0101",
#'       "&end=", ano, "1231",
#'       "&format=JSON"
#'     )
#'
#'     resposta <- tryCatch(httr::GET(url), error = function(e) return(NULL))
#'     if (is.null(resposta)) return(NULL)
#'
#'     dados <- tryCatch(fromJSON(content(resposta, as = "text")), error = function(e) return(NULL))
#'     if (is.null(dados$properties$parameter$PRECTOT)) return(NULL)
#'
#'     chuva_raw <- dados$properties$parameter$PRECTOT
#'     datas <- as.Date(names(chuva_raw), format = "%Y%m%d")
#'     chuva_valores <- as.numeric(chuva_raw)
#'
#'     tibble(
#'       data = datas,
#'       ano = ano,
#'       precipitacao = chuva_valores
#'     ) %>%
#'       filter(!is.na(data), precipitacao != -999)
#'   }
#'
#'   # Baixar dados
#'   dados_clima <- map_dfr(anos, ~baixar_precipitacao(.x, lat, lon)) %>%
#'     mutate(data_plot = as.Date(paste0("2025-", format(data, "%m-%d"))))  # sobrepor tudo no ano fictício
#'
#'   # Gráfico de barras
#'   ggplot(dados_clima, aes(x = data_plot, y = precipitacao, fill = as.factor(ano))) +
#'     geom_col(position = "identity", width = 1) +
#'     geom_point(
#'       data = filter(dados_clima, data == as.Date(data_evento)),
#'       aes(x = as.Date(paste0("2025-", format(data_evento, "%m-%d"))), y = precipitacao),
#'       color = cor_evento, size = 3
#'     ) +
#'     scale_x_date(
#'       date_breaks = "1 month",
#'       date_labels = "%b"
#'     ) +
#'     scale_fill_manual(
#'       name = "Ano",
#'       values = c("2020" = "blue", "2021" = "gold", "2022" = "green",
#'                  "2023" = "red", "2024" = "black", "2025" = "gray30")
#'     ) +
#'     labs(
#'       title = "Precipitação Diária (mm)",
#'       subtitle = paste("Comparativo entre anos – Data de evento:", format(as.Date(data_evento), "%d/%m/%Y")),
#'       x = NULL, y = "mm"
#'     ) +
#'     theme_minimal(base_size = 14) +
#'     theme(
#'       axis.text.x = element_text(size = 12)
#'     )
#' }
