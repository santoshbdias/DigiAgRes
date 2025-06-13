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
#'                    datas = c("2025-06-11","2025-06-12"))
#' }
#'
#' @author Santos Henrique Brant Dias
#' @return Vários gráficos plotados diretamente no dispositivo gráfico do R.
#' @export

plot_clima_estacao <- function(df, estacao, datas) {

  #df_filtrado <- subset(df, Estacao == estacao & as.Date(DataHora) %in% as.Date(datas))
  df_filtrado <- df[df$Estacao == estacao & as.Date(df$DataHora) %in% as.Date(datas), ]

  if (nrow(df_filtrado) == 0) {
    message("⚠️ Nenhum dado disponível para a estação e datas fornecidas.")
    return(NULL)
  }

  eixo_x <- ggplot2::scale_x_datetime(date_labels = "%d/%m\n%H:%M",  "2 hours")

  df_filtrado$Data <- as.Date(df_filtrado$DataHora)

  # Escalar umidade para o eixo secundário (mesma escala visual)
  max_temp <- max(c(df_filtrado$Temperatura_C, df_filtrado$PontoOrvalho_C), na.rm = TRUE)
  min_temp <- min(c(df_filtrado$Temperatura_C, df_filtrado$PontoOrvalho_C), na.rm = TRUE)
  range_temp <- max_temp - min_temp
  umidade_scaled <- (df_filtrado$Umidade - min(df_filtrado$Umidade, na.rm = TRUE)) /
    (max(df_filtrado$Umidade, na.rm = TRUE) - min(df_filtrado$Umidade, na.rm = TRUE)) *
    range_temp + min_temp

  print(ggplot(df_filtrado, aes(x = DataHora)) +
    geom_line(aes(y = Temperatura_C, color = "Temperatura (°C)"), size = 1) +
    geom_line(aes(y = PontoOrvalho_C, color = "Ponto de Orvalho (°C)"), size = 1) +
    geom_line(aes(y = umidade_scaled, color = "Umidade Relativa (%)"), linetype = "dashed", size = 0.8) +
    scale_color_manual(
      name = "Variáveis",
      values = c("Temperatura (°C)" = "firebrick",
                 "Ponto de Orvalho (°C)" = "steelblue",
                 "Umidade Relativa (%)" = "forestgreen")
    ) +
    scale_y_continuous(
      name = "Temperatura e Ponto de Orvalho (°C)",
      sec.axis = sec_axis(~ (. - min_temp) / range_temp *
                            (max(df_filtrado$Umidade, na.rm = TRUE) - min(df_filtrado$Umidade, na.rm = TRUE)) +
                            min(df_filtrado$Umidade, na.rm = TRUE),
                          name = "Umidade Relativa (%)")
    ) +
    labs(
      title = paste0("Temperatura, Ponto de Orvalho e Umidade - Estação ", estacao),
      x = "Data e Hora"
    ) +
    theme_minimal() +
    theme(
      axis.title.y.left = element_text(color = "black"),
      axis.title.y.right = element_text(color = "forestgreen"),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "top"
    ))

  print(ggplot(df_filtrado, aes(x = Temperatura_C, y = PontoOrvalho_C, color = Umidade)) +
          geom_point(size = 2, alpha = 0.8) +
          scale_color_gradient(low = "yellow", high = "blue", name = "Umidade (%)") +
          labs(title = "Relação entre Temperatura e Ponto de Orvalho", x = "Temperatura (°C)", y = "Ponto de Orvalho (°C)") +
          theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora)) +
          geom_line(aes(y = Temperatura_C, color = "Temperatura")) +
          geom_line(aes(y = PontoOrvalho_C, color = "Ponto de Orvalho")) +
          scale_color_manual(values = c("Temperatura" = "firebrick", "Ponto de Orvalho" = "steelblue")) +
          labs(title = "Temperatura e Ponto de Orvalho ao Longo do Tempo", x = "Data e Hora", y = "°C", color = "Variável") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = Umidade)) +
          geom_line(color = "dodgerblue4") +
          labs(title = "Umidade relativa do ar", x = "Data e Hora", y = "Umidade (%)") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = Temperatura_C)) +
          geom_line(color = "firebrick") +
          labs(title = "Temperatura ao longo do tempo", x = "Data e Hora", y = "Temperatura (°C)") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = RadiacaoSolar_W_m2)) +
          geom_area(fill = "goldenrod1", alpha = 0.7) +
          labs(title = "Radiação solar", x = "Data e Hora", y = "W/m²") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado, aes(x = DataHora, y = PrecipitacaoAcumulada_mm)) +
          geom_col(fill = "steelblue") +
          labs(title = "Precipitação acumulada", x = "Data e Hora", y = "Precipitação (mm)") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado) +
          geom_line(aes(x = DataHora, y = VelocidadeVento_m_s, color = "Velocidade")) +
          geom_line(aes(x = DataHora, y = RajadaVento_m_s, color = "Rajada")) +
          scale_color_manual(values = c("Velocidade" = "darkorange", "Rajada" = "purple")) +
          labs(title = "Velocidade e Rajada de Vento", x = "Data e Hora", y = "m/s", color = "Tipo de Vento") +
          eixo_x + theme_minimal())

  print(ggplot(df_filtrado, aes(x = factor(Data), y = Temperatura_C)) +
          geom_boxplot(fill = "tomato", alpha = 0.7) +
          labs(title = "Distribuição diária da temperatura", x = "Data", y = "Temperatura (°C)") +
          theme_minimal())
  }

