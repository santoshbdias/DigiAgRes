# #' Gera gráfico de precipitação acumulada por ano com base em KML de área agrícola
# #'
# #' @description
# #' Esta função lê um arquivo KML contendo o polígono da área de interesse, extrai o centroide,
# #' consulta a precipitação diária da NASA POWER para múltiplos anos e gera um gráfico comparativo
# #' da precipitação acumulada ao longo do ano, com destaque para a data de um evento (ex: geada).
# #'
# #' @param kml_path Caminho completo para o arquivo .kml contendo o polígono da área
# #' @param data_evento Data do evento climático de interesse, no formato "YYYY-MM-DD"
# #' @param anos Vetor com os anos a serem comparados (ex: 2020:2025)
# #' @param largura Tamanho da linha do gráfico (padrão = 1.1)
# #' @param cor_evento Cor do ponto do evento no gráfico (padrão = "red")
# #'
# #' @return Um gráfico ggplot2 com a precipitação acumulada por ano
# #'
# #' @importFrom sf st_read st_geometry st_centroid st_coordinates
# #' @importFrom httr GET content
# #' @importFrom jsonlite fromJSON
# #' @importFrom lubridate ymd
# #' @importFrom dplyr filter arrange mutate %>% tibble
# #' @importFrom ggplot2 ggplot aes geom_line geom_point scale_x_date scale_color_manual labs theme_minimal theme
# #' @importFrom purrr map_dfr
# #' @importFrom scales date_format
# #'
# #' @examples
# #' grafico_precipitacao_kml(
# #'   kml_path = "C:/caminho/area.kml",
# #'   data_evento = "2025-06-20",
# #'   anos = 2020:2025
# #' )
# #'
# #' @author Santos Henrique Brant Dias
# #' @export
#
# grafico_precipitacao_acum_kml <- function(kml_path, data_evento, anos = (as.numeric(format(Sys.Date(), "%Y")) - 5):as.numeric(format(Sys.Date(), "%Y")),
#'                                      largura = 1.1, cor_evento = "red") {
#'
#'   if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
#'   pacman::p_load(sf, httr, jsonlite, lubridate, dplyr, ggplot2, purrr)
#'
#'   # Leitura do KML e coordenadas
#'   area <- st_read(kml_path, quiet = TRUE)
#'   centroide <- st_centroid(st_geometry(area)) |> st_coordinates()
#'   lat <- centroide[2]
#'   lon <- centroide[1]
#'
#'   # Função interna para baixar dados
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
#'       filter(!is.na(data), precipitacao != -999) %>%
#'       arrange(data) %>%
#'       mutate(precipitacao_acumulada = cumsum(precipitacao))
#'   }
#'
#'   # Baixar dados
#'   dados_clima <- map_dfr(anos, ~baixar_precipitacao(.x, lat, lon)) %>%
#'     mutate(data_plot = as.Date(paste0("2025-", format(data, "%m-%d"))))
#'
#'   # Geração do gráfico
#'   ggplot(dados_clima, aes(x = data_plot, y = precipitacao_acumulada, color = as.factor(ano))) +
#'     geom_line(size = largura) +
#'     geom_point(
#'       data = filter(dados_clima, data == as.Date(data_evento)),
#'       aes(x = as.Date(paste0("2025-", format(data_evento, "%m-%d"))), y = precipitacao_acumulada),
#'       color = cor_evento, size = 3
#'     ) +
#'     scale_x_date(
#'       date_breaks = "1 month",
#'       date_labels = "%b"
#'     ) +
#'     scale_color_manual(
#'       name = "Ano",
#'       values = c("2020" = "blue", "2021" = "gold", "2022" = "green",
#'                  "2023" = "red", "2024" = "black", "2025" = "gray30")
#'     ) +
#'     labs(
#'       title = "Precipitação Acumulada (mm)",
#'       subtitle = paste("Comparativo entre anos – Data de evento:", format(as.Date(data_evento), "%d/%m/%Y")),
#'       x = NULL, y = "mm"
#'     ) +
#'     theme_minimal(base_size = 14) +
#'     theme(
#'       axis.text.x = element_text(size = 12)
#'     )
#' }
#'
#'
#'
#' # rm(list = ls()); gc(); graphics.off(); cat("\014")# Atalho equivalente a Ctrl+L
#' #
#' # if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
#' # pacman::p_load(sf, httr, jsonlite, lubridate, dplyr, ggplot2)  # Instalar/ativar pacotes
#' #
#' # # 1. Ler o KML e extrair o centroide da área
#' # kml_path <- "C:/Users/server_SantosDias/Downloads/Demilitacao_Area.kml"  # Altere para seu caminho
#' # area <- st_read(kml_path, quiet = TRUE)
#' # plot(area)
#' # centroide <- st_centroid(st_geometry(area)) |> st_coordinates()
#' #
#' # lat <- centroide[2]
#' # lon <- centroide[1]
#' #
#' # # 2. Função para baixar dados da NASA POWER (precipitação diária)
#' # baixar_precipitacao <- function(ano, lat, lon) {
#' #   url <- paste0(
#' #     "https://power.larc.nasa.gov/api/temporal/daily/point?",
#' #     "parameters=PRECTOT",
#' #     "&community=AG",
#' #     "&longitude=", lon,
#' #     "&latitude=", lat,
#' #     "&start=", ano, "0101",
#' #     "&end=", ano, "1231",
#' #     "&format=JSON"
#' #   )
#' #
#' #   resposta <- tryCatch(httr::GET(url), error = function(e) return(NULL))
#' #   if (is.null(resposta)) {
#' #     message("❌ Falha na requisição para o ano: ", ano)
#' #     return(NULL)
#' #   }
#' #
#' #   dados <- tryCatch(fromJSON(content(resposta, as = "text")), error = function(e) return(NULL))
#' #   if (is.null(dados$properties$parameter$PRECTOT)) {
#' #     message("❌ Dados de precipitação indisponíveis para o ano: ", ano)
#' #     return(NULL)
#' #   }
#' #
#' #   chuva_raw <- dados$properties$parameter$PRECTOT
#' #
#' #   # Transforma datas no formato YYYYMMDD para Date
#' #   datas <- names(chuva_raw)
#' #   datas_convertidas <- as.Date(datas, format = "%Y%m%d")
#' #
#' #   # Cria o tibble
#' #   tibble(
#' #     data = datas_convertidas,
#' #     ano = ano,
#' #     precipitacao = as.numeric(chuva_raw)
#' #   ) %>%
#' #     filter(!is.na(data), precipitacao != -999) %>%
#' #     arrange(data) %>%
#' #     mutate(precipitacao_acumulada = cumsum(precipitacao))
#' # }
#' #
#' # # 3. Baixar para múltiplos anos
#' # anos <- 2020:2025
#' # dados_clima <- purrr::map_dfr(anos, ~baixar_precipitacao(.x, lat, lon))
#' # dados_clima <- dados_clima %>%
#' #   mutate(data_plot = as.Date(paste0("2025-", format(data, "%m-%d"))))
#' #
#' # # 4. Definir data do evento
#' # data_evento <- as.Date("2025-06-20")
#' #
#' # # 5. Gerar gráfico
#' # ggplot(dados_clima, aes(x = data_plot, y = precipitacao_acumulada, color = as.factor(ano))) +
#' #   geom_line(size = 1.1) +
#' #   geom_point(
#' #     data = filter(dados_clima, data == as.Date("2025-06-20")),
#' #     aes(x = as.Date("2025-06-20"), y = precipitacao_acumulada),
#' #     color = "red", size = 3
#' #   ) +
#' #   scale_x_date(
#' #     date_breaks = "1 month",
#' #     date_labels = "%b"
#' #   ) +
#' #   scale_color_manual(
#' #     name = "Ano",
#' #     values = c("2020" = "blue", "2021" = "gold", "2022" = "green",
#' #                "2023" = "red", "2024" = "black")
#' #   ) +
#' #   labs(
#' #     title = "Precipitação Acumulada (mm)",
#' #     subtitle = "Comparativo entre anos – Data de evento: 20/06/2024",
#' #     x = NULL, y = "mm"
#' #   ) +
#' #   theme_minimal(base_size = 14) +
#' #   theme(
#' #     axis.text.x = element_text(size = 12)
#' #   )
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
