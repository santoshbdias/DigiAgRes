#' Está função serve para fazer o download de dados de estações da wunderground
#'
#' @description Função faz o download de dados meteorológicos wunderground.
#'
#' @param stations Vetor com um ou mais códigos de estação (ex: "ICIANO1").
#' @param start_date Data inicial no formato "YYYY-MM-DD".
#' @param end_date Data final no formato "YYYY-MM-DD".
#'
#' @import rvest
#' @import dplyr
#' @import stringr
#' @import lubridate
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr transmute
#' @importFrom dplyr %>%
#' @importFrom rvest read_html
#' @importFrom rvest html_elements
#' @importFrom rvest html_table
#'
#' @examples
#' \dontrun{
#' station_wund_download(stations = c("ICIANO1", "IMANDA28"),
#'                       start_date = "2024-12-01",
#'                       end_date = "2024-12-03")
#'}
#'
#' @author Santos Henrique Brant Dias
#' @return Um data.frame com os dados meteorológicos.
#' @export


#devtools::document()

station_wund_download <- function(stations, start_date, end_date) {

  datas <- seq(as.Date(start_date), as.Date(end_date), by = "1 day")

  for (f in seq_along(stations)){
    for (i in seq_along(datas)) {

      link <- paste0("https://www.wunderground.com/dashboard/pws/",stations[f],"/table/",format(datas[i], "%Y-%m-%d"),
                     "/", format(datas[i], "%Y-%m-%d"), '/daily')

      #pagina <- rvest::read_html(link)

      pagina <- tryCatch({
        rvest::read_html(link)
      }, error = function(e) {
        message("❌ Falha ao acessar o link: ", link)
        message("🔍 Verifique sua conexão com a internet ou bloqueios de firewall/proxy.")
        return(NULL)
      })
      if (is.null(pagina)) next


      tabelas <- pagina %>% rvest::html_elements("table")

      #tabela_dados <- tabelas[[4]] %>% rvest::html_table()

      tabela_dados <- tabelas %>%
        purrr::map(rvest::html_table) %>%
        purrr::keep(~ all(c("Time", "Temperature") %in% names(.x))) %>%
        purrr::pluck(1)

      vrtt <- data.frame(stations[f],format(datas[i], "%Y-%m-%d"),tabela_dados)

      names(vrtt)<-c('Station','Date',"Time","Temperature", "DewPoint", "Humidity", "Wind", "Speed",
                     "Gust", "Pressure", "PrecipRate", "PrecipAccum", "UV", "Solar")

      if(exists('santosdias')==T){santosdias<-rbind(santosdias, vrtt)}else{santosdias<-vrtt}

    }}

  santosdias <- mutate(santosdias,
      Temperature = round((as.numeric(str_replace_all(Temperature, "[^0-9\\.]", "")) - 32) * 5/9, 2),
      DewPoint = round((as.numeric(str_replace_all(DewPoint, "[^0-9\\.]", "")) - 32) * 5/9, 2),
      Humidity = as.numeric(str_replace_all(Humidity, "[^0-9]", "")),
      Speed = round(as.numeric(str_replace_all(Speed, "[^0-9\\.]", "")) * 0.44704, 2),
      Gust = round(as.numeric(str_replace_all(Gust, "[^0-9\\.]", "")) * 0.44704, 2),
      Pressure = round(as.numeric(str_replace_all(Pressure, "[^0-9\\.]", "")) * 33.8639, 2),
      PrecipRate = round(as.numeric(str_replace_all(PrecipRate, "[^0-9\\.]", "")) * 25.4, 2),
      PrecipAccum = round(as.numeric(str_replace_all(PrecipAccum, "[^0-9\\.]", "")) * 25.4, 2),
      Solar = as.numeric(str_extract(Solar, "\\d+")),
      Hora_24h = format(strptime(Time, format = "%I:%M %p"), "%H:%M"),
      DataHora = as.POSIXct(paste(Date, Hora_24h), format = "%Y-%m-%d %H:%M"))

  santosdias <- transmute(santosdias,
      Estacao = Station,
      Data = Date,
      Hora = Hora_24h,
      DataHora,
      `Temperatura_°C` = Temperature,
      `PontoOrvalho_°C` = DewPoint,
      `Umidade_%` = Humidity,
      DirecaoVento = Wind,
      VelocidadeVento_m_s = Speed,
      RajadaVento_m_s = Gust,
      Pressao_hPa = Pressure,
      PrecipitacaoTaxa_mm_h = PrecipRate,
      PrecipitacaoAcumulada_mm = PrecipAccum,
      UV,
      RadiacaoSolar_W_m2 = Solar)

  return(santosdias)
}
