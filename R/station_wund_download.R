#' Está função serve para fazer o download de dados de estações da wunderground
#'
#' @description Função faz o download de dados meteorológicos wunderground.
#'
#' @param stations Vetor com um ou mais códigos de estação (ex: "ICIANO1").
#' @param start_date Data inicial no formato "YYYY-MM-DD".
#' @param end_date Data final no formato "YYYY-MM-DD".
#'
#' @examples
#' station_wund_download(c("ICIANO1", "IMANDA28"), "2024-12-01", "2024-12-03")
#'
#' @author Santos Henrique Brant Dias
#' @return Um data.frame com os dados meteorológicos.
#' @export


#devtools::document()

station_wund_download <- function(stations, start_date, end_date) {

  datas <- seq(as.Date(start_date), as.Date(end_date), by = "1 day")

  for (f in 1:length(stations)){
    for (i in 1:length(datas)) {

      link <- paste0("https://www.wunderground.com/dashboard/pws/",stations[f],"/table/",format(datas[i], "%Y-%m-%d"),
                     "/", format(datas[i], "%Y-%m-%d"), '/daily')

      pagina <- rvest::read_html(link)

      tabelas <- pagina %>% rvest::html_elements("table")

      tabela_dados <- tabelas[[4]] %>% rvest::html_table()

      vrtt <- data.frame(stations[f],format(datas[i], "%Y-%m-%d"),tabela_dados)

      names(vrtt)<-c('Station','Date',"Time","Temperature", "Dew Point", "Humidity", "Wind", "Speed",
                     "Gust", "Pressure", "Precip. Rate.", "Precip. Accum.", "UV", "Solar")

      if(exists('santosT')==T){santosT<-rbind(santosT, vrtt)}else{santosT<-vrtt}

      rm(link, pagina,tabelas,tabela_dados,vrtt)
    }}

  santosT <- santosT %>%
    dplyr::mutate(
      Temperature = round((as.numeric(str_replace_all(Temperature, "[^0-9\\.]", "")) - 32) * 5/9, 2),  # °C
      `Dew Point` = round((as.numeric(str_replace_all(`Dew Point`, "[^0-9\\.]", "")) - 32) * 5/9, 2),  # °C
      Humidity = as.numeric(str_replace_all(Humidity, "[^0-9]", "")),                                # %
      Speed = round(as.numeric(str_replace_all(Speed, "[^0-9\\.]", "")) * 0.44704, 2),                # m/s
      Gust = round(as.numeric(str_replace_all(Gust, "[^0-9\\.]", "")) * 0.44704, 2),                  # m/s
      Pressure = round(as.numeric(str_replace_all(Pressure, "[^0-9\\.]", "")) * 33.8639, 2),          # hPa
      `Precip. Rate.` = round(as.numeric(str_replace_all(`Precip. Rate.`, "[^0-9\\.]", "")) * 25.4, 2),     # mm/h
      `Precip. Accum.` = round(as.numeric(str_replace_all(`Precip. Accum.`, "[^0-9\\.]", "")) * 25.4, 2),   # mm
      Solar = as.numeric(str_extract(Solar, "\\d+"))  # w/m²
    ) %>%
    dplyr::transmute(
      Estacao = Station,
      Data = Date,
      Hora = Time,
      `Temperatura_°C` = Temperature,
      `PontoOrvalho_°C` = `Dew Point`,
      `Umidade_%` = Humidity,
      DirecaoVento = Wind,
      `VelocidadeVento_m_s` = Speed,
      `RajadaVento_m_s` = Gust,
      `Pressao_hPa` = Pressure,
      `PrecipitacaoTaxa_mm_h` = `Precip. Rate.`,
      `PrecipitacaoAcumulada_mm` = `Precip. Accum.`,
      UV = UV,
      `RadiacaoSolar_W_m2` = Solar
    )

}
