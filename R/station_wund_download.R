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

  results <- list()

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

      names(vrtt)<-c('Station','Date',"Time","Temperature", "Dew Point", "Humidity", "Wind", "Speed",
                     "Gust", "Pressure", "Precip. Rate.", "Precip. Accum.", "UV", "Solar")

      #if(exists('santosT')==T){santosT<-rbind(santosT, vrtt)}else{santosT<-vrtt}

      results[[length(results) + 1]] <- vrtt

      return(NULL)
    }}

  santosT <- dplyr::bind_rows(resultados) %>%
    dplyr::mutate(
      Temperature = round((as.numeric(str_replace_all(Temperature, "[^0-9\\.\\-]", "")) - 32) * 5/9, 2), #°C
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

  return(santosT)
}
