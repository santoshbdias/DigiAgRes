# 📦 DigiAgRes

**DigiAgRes** é uma abreviação de **Digital Argiculture Research**,
pacote R para facilitar operações recorrentes no contexto da agricultura
digital, da pesquisa do manejo e conservação do solo e da água, como o
download de dados climáticos e a geração de grids amostrais a partir de
polígonos. Ele oferece ferramentas simples e práticas para pesquisadores
em agricultura digital.

------------------------------------------------------------------------

## 🚀 Instalação dos softwares

Antes de tudo, instale o **R** e o **RStudio**:

Antes de utilizar o pacote, certifique-se de que você tem o **R** e o **RStudio** instalados:

- 📥**R (CRAN):**  
  Acesse [https://cran.r-project.org](https://cran.r-project.org) e baixe a versão mais recente do R para seu sistema operacional (Windows, Mac ou Linux).

- 💻 **RStudio (IDE recomendada):**  
  Acesse [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/) e baixe o RStudio Desktop gratuito.

---


## 💻 Instalação do pacote

Depois de instalar os softwares na sequência, instale o pacote com:

``` r
# Instale devtools se ainda não tiver
install.packages("devtools")

# Instale o DigiAgRes diretamente do GitHub
devtools::install_github("santoshbdias/DigiAgRes")
```

------------------------------------------------------------------------

## 📚 Funcionalidades

### 1.📥 Download e plot de dados meteorológicos da Weather Underground

Utilize a função ***station_wund_download()*** para baixar dados
horários de estações meteorológicas pessoais (PWS) da rede Weather
Underground:

``` r
#Comandos para limpar completamente o R, tudo aberto e o que já rodou.
rm(list = ls()); gc(); graphics.off(); cat("\014")# Atalho equivalente a Ctrl+L

library(DigiAgRes)

dados <- station_wund_download(
  stations = 'IPARANAM3',
  start_date = "2025-06-01",
  end_date = "2025-06-12"
)


# Explorando gráficamente os dados
plot_clima_estacao(dados, estacao = "IPARANAM3",
                   datas = c("2025-06-11","2025-06-12"))


# Exportar para CSV e/ou Excel
readr::write_csv(dados, "C:/Users/SantosDias/Documents/dados_wunderground.csv") #Altere aqui o caminho para o seu computador
writexl::write_xlsx(dados, "C:/Users/SantosDias/Documents/dados_wunderground.xlsx")#Altere aqui o caminho para o seu computador
```
Retorna um data.frame contendo temperatura, umidade, velocidade do vento, radiação solar, entre outras variáveis no sistema internacional de unidades.



### 2.💧 Cálculo da Evapotranspiração de Referência (ETo) diária — FAO 56
A função *calc_eto_fao56()* realiza o cálculo da evapotranspiração de referência (ETo) diária utilizando o método de Penman-Monteith proposto pela FAO (FAO 56). A função opera sobre os dados horários baixados com station_wund_download() e agrega os valores por estação e por dia.

É necessário informar a altitude e a latitude da estação, que podem ser passadas como valores únicos ou vetores nomeados para múltiplas estações.

```r
#Comandos para limpar completamente o R, tudo aberto e o que já rodou.
rm(list = ls()); gc(); graphics.off(); cat("\014")# Atalho equivalente a Ctrl+L

library(DigiAgRes)

dados <- station_wund_download(
  stations = 'IPARANAM3',
  start_date = "2025-06-01",
  end_date = "2025-06-12"
)

# Calcular ETo diária para uma estação
eto_df <- eto_fao56_station(dados, estacao="IPARANAM3")

# Visualizar os resultados
head(eto)
```


A função retorna um data.frame com as seguintes colunas:<br>
Estacao: nome da estação meteorológica;<br>
Data: data de referência (agregada por dia);<br>
ETo_FAO56: valor da evapotranspiração de referência (em mm/dia).<br>
Essa métrica é essencial para o manejo hídrico e o cálculo das necessidades de irrigação em diferentes culturas agrícolas.<br>



### 3.🗺️ Gerar grade regular de pontos a partir de um polígono 

A função polygon_to_points_grid() permite criar um grid regular de pontos centrados dentro de um polígono (ex: área experimental ou talhão agrícola).

``` r
grid_points <- polygon_to_points_grid(
  dir_polygon = "C:/Users/SantosDias/Documents/outra_area.kml",#Altere aqui o caminho para o seu computador
  dist = 100, #Distância entre os pontos, para 1 ponto por ha (dist=100)
  plot = TRUE
)

# Exportar para KML
sf::st_write(grid_points, "C:/Users/SantosDias/Documents/grid_regular_pontos.kml",#Altere aqui o caminho para o seu computador
             driver = "KML", append = FALSE)
```
O sistema de coordenadas do KML é convertido automaticamente para UTM com base no centróide do polígono.



### 4.🌱 Geração de pontos aleatórios com distância mínima

Essa função permitirá gerar pontos aleatórios dentro de um polígono, respeitando uma distância mínima entre eles (útil para amostragem espacial).

``` r

random_points <- polygon_to_random_points(
  dir_polygon = "C:/Users/SantosDias/Documents/outra_area.kml",#Altere aqui o caminho para o seu computador
  n = 50, #Número de pontos para plotar na área
  min_dist = 30, #Distância mínima entre os pontos
  plot = TRUE
)

# Exportar para shapefile
sf::st_write(random_points, "C:/Users/SantosDias/Documents/pontos_aleatorios.shp", append = FALSE)
```



### 5. Baixar dados do modelo Topodata para um vetor

``` r

TopoData_download_to_vector(
  area_kml = "Caminho/para/area.kml",
  layer = "ALTITUDE",
  path_out = "Caminho/saida/"
)
```

### 6.🌧️ Análise automática de radar meteorológico e envio de alertas por Telegram
O DigiAgRes permite baixar a imagem mais recente do radar meteorológico do Simepar, analisar a presença de chuva em uma região de interesse (com base na cor da imagem) e enviar alertas por e-mail sempre que uma condição meteorológica for detectada. Isso pode ser automatizado com um loop que roda a cada 10 minutos.

``` r
if(!require("pacman")) install.packages("pacman");pacman::p_load(
  DigiAgRes,httr, jsonlite, magick,purrr)  # Instalar/ativar pacotes

#Para descobrir o token do bot, ou até criar o bot, busque BotFather no Telegram
bot_token <- "7968534845:AAETdjrjtykjtrjktrkm4ttrykjkg856Eo8"

#Para descobrir o chat id do grupo que seu bot entrou:
resposta <- httr::GET(
  url = paste0("https://api.telegram.org/bot", bot_token, "/getUpdates")
)

conteudo <- content(resposta, as = "parsed")

# Ver chat_id dos grupos
conteudo$result |>
  purrr::map(~ .x$my_chat_member$chat$id %||% .x$message$chat$id)

chat_id <- '-48767525577'

ultima_mensagem_diaria <- as.Date(Sys.time()) - 1

repeat {
  minuto <- as.numeric(format(Sys.time(), "%M"))
  hora <- format(Sys.time(), "%H:%M")
  hoje <- as.Date(Sys.time())

  cat(hora, "- Verificando horário...\n")

  coords <- list(
    'Cianorte' = list(x = 388, y = 240),
    'Castelo'  = list(x = 437, y = 190)
  )

  raio=55

  radar_img <- tryCatch(
    baixar_radar_PR(),
    error = function(e) {
      cat("❌ Erro ao baixar imagem do radar: ", conditionMessage(e), "\n")
      return(NULL)
    }
  )

  if (!is.null(radar_img)) {
    img_plot <- image_draw(radar_img)

    for (cidade in names(coords)) {
      x <- coords[[cidade]]$x
      y <- coords[[cidade]]$y
      points(x, y, col = "red", pch = 19, cex = 1)
      points(x + raio, y, col = "purple", pch = 19, cex = 1)
      points(x - raio, y, col = "purple", pch = 19, cex = 1)
      points(x, y + raio, col = "purple", pch = 19, cex = 1)
      points(x, y - raio, col = "purple", pch = 19, cex = 1)
    }
    dev.off()
  }

  # ✅ Envia mensagem de status uma vez por dia às 13:00
  if (hora == "13:00" && ultima_mensagem_diaria < hoje) {

    caminho_imagem <- tempfile(fileext = ".png")

    img_salva <- tryCatch(
      {
        if (!is.null(radar_img)) {
          magick::image_write(img_plot, path = caminho_imagem, format = "png")
          TRUE
        } else {
          FALSE
        }
      },
      error = function(e) {
        cat("❌ Erro ao salvar imagem: ", conditionMessage(e), "\n")
        FALSE
      }
    )

    if (img_salva) {
      tryCatch({
        httr::POST(
          url = paste0("https://api.telegram.org/bot", bot_token, "/sendPhoto"),
          body = list(
            chat_id = chat_id,
            photo = httr::upload_file(caminho_imagem),
            caption = "Mensagem diária de status. Sistema de alerta meteorológico ativo e funcionando perfeitamente. *Sem chuvas* até o momento",
            parse_mode = "Markdown"
          )
        )
        cat("✅ Mensagem diária de status enviada.\n")
        ultima_mensagem_diaria <- hoje
      }, error = function(e) {
        cat("❌ Erro ao enviar mensagem no Telegram: ", conditionMessage(e), "\n")
      })
    }
  }


  #Verifica se é hora de rodar a função principal, se o minuto termina em 3
  if (minuto %% 10 == 3) {
    cat(format(Sys.time(), "%Y-%m-%d %H:%M"), "- Executando...\n")

    if (!is.null(img_plot)) print(img_plot)

    for (g in 1:length(names(coords))) {
      tryCatch({
        executar_alerta_telegram(
          mega = names(coords)[g],
          chat_id = chat_id,
          bot_token = bot_token
        )
      }, error = function(e) {
        cat("❌ Erro ao executar alerta para ", cidade, ": ", conditionMessage(e), "\n")
      })
    }
    # Espera 6 minutos antes de checar de novo
    Sys.sleep(360)
  }
  # Espera 30 segundos antes de checar de novo
  Sys.sleep(30)
}


``` 



------------------------------------------------------------------------


## 👨‍💻 Autor

Desenvolvido pelo Prof. Dr. Santos Henrique Brant Dias<br> 
Pesquisador Agricultura Digital no Manejo e Conservação do Solo e da Água<br> 

Para mais informações: <https://www.santoshbdias.com.br/><br>

