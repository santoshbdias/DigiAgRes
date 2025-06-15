#' Calcula a Evapotranspiração de Referência diária (ETo) pelo método FAO 56
#'
#' @description
#' Esta função calcula a evapotranspiração de referência diária (ETo) utilizando o método de Penman-Monteith proposto pela FAO (FAO-56).
#' Os dados de entrada devem conter observações meteorológicas horárias incluindo temperatura do ar, ponto de orvalho, radiação solar,
#' velocidade do vento e pressão atmosférica. A função agrupa os dados por estação e por dia e retorna a ETo diária.
#'
#' A altitude (z) e a latitude (lat) da estação devem ser fornecidas como valores únicos ou vetores nomeados com os nomes das estações.
#'
#' @param df Dataframe com dados meteorológicos horários.
#' @param estacao Nome da estação desejada (ex: "ICIANO1").
#'
#' @return Um data.frame contendo a ETo diária por estação e por data.
#'
#' @details
#' A equação de Penman-Monteith requer dados médios diários de temperatura, pressão atmosférica,
#' déficit de vapor de pressão, radiação líquida e resistência aerodinâmica. A função realiza as conversões
#' necessárias a partir de dados horários.
#'
#' @import dplyr
#' @import lubridate
#'
#' @examples
#' \dontrun{
#' eto_df <- eto_fao56_station(df, estacao='IPARANAM3')
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

eto_fao56_station <- function(df,estacao) {

  df_filtrado <- df[df$Estacao == estacao, ]

  # Constantes
  Gsc <- 0.0820  # MJ m-2 min-1
  sigma <- 4.903e-9  # MJ K-4 m-2 dia-1

  df_filtrado <- df_filtrado %>%
    mutate(Data = as.Date(Data),
           T = Temperatura_C,
           u2 = VelocidadeVento_m_s,
           RH = Umidade,
           Rs = RadiacaoSolar_W_m2)  # Converter W/m2 para MJ/m2/dia (aproximadamente)

  df_resumo <- df_filtrado %>%
    group_by(Estacao, Data) %>%
    summarise(
      Tmean = mean(T, na.rm = TRUE),
      Tmax = max(T, na.rm = TRUE),
      Tmin = min(T, na.rm = TRUE),
      RHmean = mean(RH, na.rm = TRUE),
      RHmax = max(RH, na.rm = TRUE),
      RHmin = min(RH, na.rm = TRUE),
      u2 = mean(u2, na.rm = TRUE),
      Rs = sum(Rs, na.rm = TRUE),
      Chuva = max(PrecipitacaoAcumulada_mm, na.rm = TRUE),
      Patm = mean(Pressao_hPa, na.rm = TRUE)/10,
      .groups = "drop"
    )

  df_resumo2 <- df_resumo %>%
    rowwise() %>%
    mutate(
      z_est = df[2,2],
      lat_est = df[2,3],
      Rs = Rs * 300/1000000, # 300 é o tempo em segundos e 100000 a conversão de J para MJ
      J = as.numeric(format(Data, "%j")), # Dia Juliano
      P = 101.3 * (((293 - 0.0065 * z_est) / 293)^5.26),
      gamma = 0.000665 * Patm,
      delta = 4098 * (0.6108 * exp((17.27 * Tmean) / (Tmean + 237.3))) / (Tmean + 237.3)^2,
      DT = (delta / (delta + gamma * (1 + 0.34 * u2))),
      PT = (gamma) / (delta + gamma * (1 + 0.34 * u2)),
      TT = (900 / (Tmean + 273)) * u2,

      es = 0.6108 * exp((17.27 * Tmean) / (Tmean + 237.3)),

      e_tmax = 0.6108 * exp(17.27 * Tmax / (Tmax + 237.3)), # e_tmax (kPa)
      e_tmin = 0.6108 * exp(17.27 * Tmin / (Tmin + 237.3)), # e_tmin (kPa)
      es2 = (e_tmax + e_tmin) / 2,

      ea2 = (e_tmin * (RHmax / 100) + e_tmax * (RHmin / 100)) / 2,


      ea = es * RHmean / 100,
      dr = 1 + 0.033 * cos(2 * pi * J / 365),
      delta_s = 0.409 * sin((2 * pi * J / 365) - 1.39),
      solar_decli  = 0.409 * sin((2 * pi * J / 365) - 1.39),
      lat_rad = (pi / 180) * lat_est,
      sigma = 4.903 * 10^-9, # MJ K-4 m-2 day -1
      phi = lat_est * pi / 180,
      ws = acos(-tan(lat_rad) * tan(solar_decli)),
      Ra = (24 * 60 / pi) * Gsc * dr * ((ws * sin(lat_rad) * sin(solar_decli)) + (cos(lat_rad) * cos(solar_decli) * sin(ws))),
      Rso = (0.75 + (2 * 10^-5) * z_est) * Ra,
      Rns = 0.77 * Rs,
      Rnl = sigma * ((((Tmax + 273.16)^4) + ((Tmin + 273.16)^4)) / 2) * (0.34 - 0.14 * sqrt(ea2)) * (1.35 * (Rs / Rso) - 0.35),
      Rn = Rns - Rnl,
      Rng = 0.408 * Rn,
      ETrad = DT * Rng,
      ETwind = PT * TT * (es - ea2),
      G = 0,
      ETo2 = ETwind + ETrad,
      ETo = (0.408 * delta * (Rn - G) + gamma * 900 / (Tmean + 273) * u2 * (es - ea)) /
        (delta + gamma * (1 + 0.34 * u2))
    ) %>%
    select(Estacao, Data, ETo, Chuva)

  return(df_resumo2)
}
