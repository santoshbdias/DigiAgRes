# 📦 DigiAgRes

**DigiAgRes** é uma abreviação *Digital Argiculture Research*, pacote R voltado para o processamento de dados espaciais e meteorológicos, como a geração de grades de pontos em áreas agrícolas, integração com dados externos como o Wunderground e shapefiles geográficos. Ele oferece ferramentas simples e práticas para pesquisadores em agricultura digital.

----

## 🚀 Instalação dos softwares
Antes de tudo, instale o **R** e o **RStudio**:
- 📥 Baixe e instale o R: [https://cran.r-project.org/](https://cran.r-project.org/)
- 💻 Baixe e instale o RStudio: [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)

----

## 💻 Instalação do pacote
Depois de instalar os softwares na sequência, instale o pacote com:
```r
# Instale devtools se ainda não tiver
install.packages("devtools")

# Instale o DigiAgRes diretamente do GitHub
devtools::install_github("santoshbdias/DigiAgRes")
```

---

## 📚 Funcionalidades
### 1. Baixar dados meteorológicos Wunderground
```r
library(DigiAgRes)

dados <- station_wund_download(
  stations = c("ICIANO1", "IMANDA28"),
  start_date = "2024-12-01",
  end_date = "2024-12-03"
)

# Exportar para CSV e/ou Excel
readr::write_csv(dados, "C:/Users/SantosDias/Documents/dados_wunderground.csv") #Altere aqui o caminho para o seu computador
writexl::write_xlsx(dados, "C:/Users/SantosDias/Documents/dados_wunderground.xlsx")#Altere aqui o caminho para o seu computador
```
### 2. Gerar grade regular de pontos a partir de um polígono .kml
```r
grid_points <- polygon_to_points_grid(
  dir_polygon = "C:/Users/SantosDias/Documents/outra_area.kml",#Altere aqui o caminho para o seu computador
  dist = 100,
  plot = TRUE
)

# Exportar para KML
sf::st_write(grid_points, "C:/Users/SantosDias/Documents/grid_regular_pontos.kml",#Altere aqui o caminho para o seu computador
             driver = "KML", append = FALSE)
```
### 3. Gerar pontos aleatórios dentro de uma área
```r

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
```r

TopoData_download_to_vector(
  area_kml = "Caminho/para/area.kml",
  layer = "ALTITUDE",
  path_out = "Caminho/saida/"
)
```
---

## 👨‍💻 Autor</p>
Desenvolvido por Prof. Dr. Santos Henrique Brant Dias</p>
Para mais informações: [https://www.santoshbdias.com.br/](https://www.santoshbdias.com.br/)</p>
E-mail: santoshbdias@gmail.com
---

##  📄 Licença</p>
Este pacote está licenciado sob a MIT License.

