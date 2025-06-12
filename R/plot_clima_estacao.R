#' Plota gráficos climáticos (Temperatura, Ponto de Orvalho, Umidade e etc)
#'
#' @description
#' Esta função plota gráficos de temperatura do ar, ponto de orvalho e umidade relativa do ar ao longo do tempo,
#' utilizando dados meteorológicos processados por `station_wund_download()`. Permite filtrar por estação e intervalo de datas,
#' e apresenta a umidade relativa em eixo secundário.
#'
#' @param df Dataframe com os dados meteorológicos processados.
#' @param estacao Nome da estação desejada (ex: "ICIANO1").
#' @param datas Vetor de datas a serem plotadas (formato: "YYYY-MM-DD").
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom scales date_format
#'
#' @examples
#' \dontrun{
#' plot_clima_estacao(df,
#'                    estacao = "IPARANAM3",
#'                    datas = c("2025-06-10","2025-06-11","2025-06-12"))
#' }
#'
#' @author Santos Henrique Brant Dias
#' @return Vários gráficos plotados diretamente no dispositivo gráfico do R.
#' @export

plot_clima_estacao <- function(df, estacao, datas) {

  df_filtrado <- df %>%
    dplyr::filter(Estacao == estacao & as.Date(DataHora) %in% as.Date(datas))

  if (nrow(df_filtrado) == 0) {
    message("⚠️ Nenhum dado disponível para a estação e datas fornecidas.")
    return(NULL)
  }

  pacman::p_load(ggplot2, dplyr, lubridate)

  print(ggplot(df_filtrado, aes(x = DataHora, y = Temperatura_C)) +
          geom_line(color = "firebrick") +
          labs(title = "Temperatura ao longo do tempo", x = "Data e Hora", y = "Temperatura (°C)") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = Umidade)) +
          geom_line(color = "dodgerblue4") +
          labs(title = "Umidade relativa do ar", x = "Data e Hora", y = "Umidade (%)") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = PrecipitacaoAcumulada_mm)) +
          geom_col(fill = "steelblue") +
          labs(title = "Precipitação acumulada", x = "Data e Hora", y = "Precipitação (mm)") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = RadiacaoSolar_W_m2)) +
          geom_area(fill = "goldenrod1", alpha = 0.7) +
          labs(title = "Radiação solar", x = "Data e Hora", y = "W/m²") +
          theme_minimal())

  df_filtrado$Data <- as.Date(df_filtrado$DataHora)
  print(ggplot(df_filtrado, aes(x = factor(Data), y = Temperatura_C)) +
          geom_boxplot(fill = "tomato", alpha = 0.7) +
          labs(title = "Distribuição diária da temperatura", x = "Data", y = "Temperatura (°C)") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora)) +
          geom_line(aes(y = Temperatura_C, color = "Temperatura")) +
          geom_line(aes(y = PontoOrvalho_C, color = "Ponto de Orvalho")) +
          scale_color_manual(values = c("Temperatura" = "firebrick", "Ponto de Orvalho" = "steelblue")) +
          labs(title = "Temperatura e Ponto de Orvalho ao Longo do Tempo", x = "Data e Hora", y = "°C", color = "Variável") +
          theme_minimal())

  print(ggplot(df_filtrado) +
          geom_line(aes(x = DataHora, y = VelocidadeVento_m_s, color = "Velocidade")) +
          geom_line(aes(x = DataHora, y = RajadaVento_m_s, color = "Rajada")) +
          scale_color_manual(values = c("Velocidade" = "darkorange", "Rajada" = "purple")) +
          labs(title = "Velocidade e Rajada de Vento", x = "Data e Hora", y = "m/s", color = "Tipo de Vento") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = Temperatura_C, y = PontoOrvalho_C, color = Umidade)) +
          geom_point(size = 2, alpha = 0.8) +
          scale_color_gradient(low = "yellow", high = "blue", name = "Umidade (%)") +
          labs(title = "Relação entre Temperatura e Ponto de Orvalho", x = "Temperatura (°C)", y = "Ponto de Orvalho (°C)") +
          theme_minimal())
}


