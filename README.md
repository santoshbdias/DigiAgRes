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
library(DigiAgRes)
library(ggplot2)

dados <- station_wund_download(
  stations = 'IPARANAM3',
  start_date = "2025-06-01",
  end_date = "2025-06-12"
)


# Explorando gráficamente os dados
plot_clima_estacao(df,estacao = "IPARANAM3",
                   datas = c("2025-06-11","2025-06-12"))


# Exportar para CSV e/ou Excel
readr::write_csv(dados, "C:/Users/SantosDias/Documents/dados_wunderground.csv") #Altere aqui o caminho para o seu computador
writexl::write_xlsx(dados, "C:/Users/SantosDias/Documents/dados_wunderground.xlsx")#Altere aqui o caminho para o seu computador
```
Retorna um data.frame contendo temperatura, umidade, velocidade do vento, radiação solar, entre outras variáveis no sistema internacional de unidades.



### 2.🗺️ Gerar grade regular de pontos a partir de um polígono 

A função polygon_to_points_grid() permite criar um grid regular de pontos centrados dentro de um polígono (ex: área experimental ou talhão agrícola).

``` r
grid_points <- polygon_to_points_grid(
  dir_polygon = "C:/Users/SantosDias/Documents/outra_area.kml",#Altere aqui o caminho para o seu computador
  dist = 100,
  plot = TRUE
)

# Exportar para KML
sf::st_write(grid_points, "C:/Users/SantosDias/Documents/grid_regular_pontos.kml",#Altere aqui o caminho para o seu computador
             driver = "KML", append = FALSE)
```
O sistema de coordenadas do KML é convertido automaticamente para UTM com base no centróide do polígono.



### 3.🌱 Geração de pontos aleatórios com distância mínima

Essa função permitirá gerar pontos aleatórios dentro de um polígono, respeitando uma distância mínima entre eles (útil para amostragem espacial).

``` r

random_points <- polygon_to_random_points(
  dir_polygon = "C:/Users/SantosDias/Documents/outra_area.kml",#Altere aqui o caminho para o seu computador
  n = 50,
  min_dist = 30,
  plot = TRUE
)

# Exportar para shapefile
sf::st_write(random_points, "C:/Users/SantosDias/Documents/pontos_aleatorios.shp", append = FALSE)
```



### 4. Baixar dados do modelo Topodata para um vetor

``` r

TopoData_download_to_vector(
  area_kml = "Caminho/para/area.kml",
  layer = "ALTITUDE",
  path_out = "Caminho/saida/"
)
```

------------------------------------------------------------------------


## 👨‍💻 Autor

Desenvolvido pelo Prof. Dr. Santos Henrique Brant Dias<br> 
Pesquisador Agricultura Digital no Manejo e Conservação do Solo e da Água<br> 

Para mais informações: <https://www.santoshbdias.com.br/><br>

