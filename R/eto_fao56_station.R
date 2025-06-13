#' Calcula a Evapotranspiração de Referência diária (ETo) pelo método FAO 56
#'
#' @description A função calcula a ETo diária agrupada por estação e data, com base no método de Penman-Monteith da FAO.
#'
#' @param df Dataframe com dados horários meteorológicos.
#' @param z Altitude da estação (em metros) — pode ser um valor único ou vetor nomeado por estação.
#' @param lat Latitude da estação em graus decimais — pode ser um valor único ou vetor nomeado.
#'
#' @return Um data.frame com a ETo diária por estação e data.
#' @import dplyr
#' @import lubridate
#' @export

eto_fao56_station <- function(df, z, lat) {
  library(dplyr)
  library(lubridate)

  # Constantes
  Gsc <- 0.0820  # MJ m-2 min-1
  sigma <- 4.903e-9  # MJ K-4 m-2 dia-1

  df <- df %>%
    mutate(Data = as.Date(Data),
           T = Temperatura_C,
           u2 = VelocidadeVento_m_s,
           RH = Umidade,
           Rs = RadiacaoSolar_W_m2 * 0.0864 / 1e3)  # Converter W/m2 para MJ/m2/dia (aproximadamente)

  df_resumo <- df %>%
    group_by(Estacao, Data) %>%
    summarise(
      Tmean = mean(T, na.rm = TRUE),
      RHmean = mean(RH, na.rm = TRUE),
      u2 = mean(u2, na.rm = TRUE),
      Rs = sum(Rs, na.rm = TRUE),
      .groups = "drop"
    )

  df_resumo <- df_resumo %>%
    rowwise() %>%
    mutate(
      z_est = ifelse(length(z) > 1, z[Estacao], z),
      lat_est = ifelse(length(lat) > 1, lat[Estacao], lat),
      J = yday(Data),
      P = 101.3 * (((293 - 0.0065 * z_est) / 293)^5.26),
      gamma = 0.000665 * P,
      delta = 4098 * (0.6108 * exp((17.27 * Tmean) / (Tmean + 237.3))) / (Tmean + 237.3)^2,
      es = 0.6108 * exp((17.27 * Tmean) / (Tmean + 237.3)),
      ea = es * RHmean / 100,
      dr = 1 + 0.033 * cos(2 * pi * J / 365),
      delta_s = 0.409 * sin(2 * pi * J / 365 - 1.39),
      phi = lat_est * pi / 180,
      ws = acos(-tan(phi) * tan(delta_s)),
      Ra = (24 * 60 / pi) * Gsc * dr * (ws * sin(phi) * sin(delta_s) + cos(phi) * cos(delta_s) * sin(ws)),
      Rso = (0.75 + 2e-5 * z_est) * Ra,
      Rns = 0.77 * Rs,
      Rnl = sigma * ((Tmean + 273.16)^4 + (Tmean + 273.16)^4) / 2 *
        (0.34 - 0.14 * sqrt(ea)) * (1.35 * (Rs / Rso) - 0.35),
      Rn = Rns - Rnl,
      G = 0,
      ETo = (0.408 * delta * (Rn - G) + gamma * 900 / (Tmean + 273) * u2 * (es - ea)) /
        (delta + gamma * (1 + 0.34 * u2))
    ) %>%
    select(Estacao, Data, ETo)

  return(df_resumo)
}
