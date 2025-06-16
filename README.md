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
  DigiAgRes,httr, jsonlite, magick)  # Instalar/ativar pacotes

repeat {
  minuto <- as.numeric(format(Sys.time(), "%M"))
  cat(format(Sys.time(), "%H:%M"), "- Verificando horário...\n")

  # Verifica se o minuto termina em 3
  if (minuto %% 10 == 3) {
    cat(format(Sys.time(), "%Y-%m-%d %H:%M"), "- Executando...\n")

    minuto %% 10 == 3

    # Baixa a imagem mais recente do radar meteorológico do PR
    img <- baixar_radar_PR()
    raio = 55

    cat('Cianorte',"\n")

  img_cianorte <- image_draw(img)
  points(388, 240, col = "red", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(388+raio, 240, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(388-raio, 240, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(388, 240+raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(388, 240-raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  dev.off()

  print(img_cianorte)

  # Analisa a imagem para a região de Cianorte
  resul <- analisar_radar_PR(img, mega = 'Cianorte', raio = 55)

  # Envia e-mail de alerta caso a condição detectada seja "Sem chuvas"
  if (resul == "Chuva forte (vermelho)" || resul == "Chuva leve (amarelo)" || resul == "Risco de chuva (verde)") {
    caminho_temp <- tempfile(fileext = ".png")
    magick::image_write(img_cianorte, path = caminho_temp, format = "png")

    enviar_telegram_imagem(
      bot_token = "79387979745:AAdhgfhfghgH6qCnpfPrMEi-plgrVMHEx_Eo8",  # Seu token real
      chat_id = "-105678679870906",                           # ID do grupo
      caminho_imagem = caminho_temp,  # Caminho da imagem
      legenda = paste0("Radar atualizado às ",format(Sys.time(), "%H:%M")," - risco de chuva em Cianorte")
    )
  } else if (resul == 'Sem chuvas') {
    cat('Sem Chuvas',"\n")
  }

  cat('Presidente Castelo Branco',"\n")

  img_castelo <- image_draw(img)
  points(435, 190, col = "red", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(435+raio, 190, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(435-raio, 190, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(435, 190+raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(435, 190-raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  dev.off()

  print(img_castelo)

  # Analisa a imagem para a região de Cianorte
  resul2 <- analisar_radar_PR(img, mega = "Castelo", raio = 55)

  # Envia e-mail de alerta caso a condição detectada seja "Sem chuvas"
  if (resul2 == "Chuva forte (vermelho)" || resul2 == "Chuva leve (amarelo)" || resul2 == "Risco de chuva (verde)") {

    caminho_temp <- tempfile(fileext = ".png")
    magick::image_write(img_castelo, path = caminho_temp, format = "png")

    enviar_telegram_imagem(
      bot_token = "79387979745:AAdhgfhfghgH6qCnpfPrMEi-plgrVMHEx_Eo8",  # Seu token real
      chat_id = "-105678679870906",                           # ID do grupo
      caminho_imagem = caminho_temp,  # Caminho da imagem
      legenda = paste0("Radar atualizado às ",format(Sys.time(), "%H:%M")," - risco de chuva em Presidente Castelo Branco")
    )
  } else if (resul == 'Sem chuvas') {
    cat('Sem Chuvas',"\n")
  }
  # Espera 20 segundos antes de checar de novo
  Sys.sleep(550)
  }
    # Espera 20 segundos antes de checar de novo
    Sys.sleep(20)
}
``` 



------------------------------------------------------------------------


## 👨‍💻 Autor

Desenvolvido pelo Prof. Dr. Santos Henrique Brant Dias<br> 
Pesquisador Agricultura Digital no Manejo e Conservação do Solo e da Água<br> 

Para mais informações: <https://www.santoshbdias.com.br/><br>

