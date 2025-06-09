# 📦 DigiAgRes

**DigiAgRes** é um pacote R voltado para o processamento de dados meteorológicos, geração de grades de pontos em áreas agrícolas e integração com dados externos como o Wunderground e shapefiles geográficos. Ele oferece ferramentas simples e práticas para pesquisadores em agricultura digital.

----

## 🚀 Instalação dos softwares
Antes de tudo, instale o **R** e o **RStudio**:
- 📥 Baixe e instale o R: [https://cran.r-project.org/](https://cran.r-project.org/)
- 💻 Baixe e instale o RStudio: [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)

----

## 💻 Instalação do pacote
Depois, instale o pacote com:
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

# Exportar para CSV e Excel
readr::write_csv(dados, "dados_wunderground.csv")
writexl::write_xlsx(dados, "dados_wunderground.xlsx")
```
### 2. Gerar grade regular de pontos a partir de um polígono .kml
```r
grid_points <- polygon_to_points_grid(
  dir_polygon = "C:/Users/server_SantosDias/Downloads/outra_area.kml",
  dist = 100,
  plot = TRUE
)

# Exportar para KML
sf::st_write(grid_points, "C:/Users/server_SantosDias/Downloads/grid_regular_pontos.kml",
             driver = "KML", append = FALSE)
```
### 3. Gerar pontos aleatórios dentro de uma área
```r

random_points <- polygon_to_random_points(
  dir_polygon = "C:/Users/server_SantosDias/Downloads/outra_area.kml",
  n = 50,
  min_dist = 30,
  plot = TRUE
)

# Exportar para shapefile
sf::st_write(random_points, "pontos_aleatorios.shp", append = FALSE)
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

👨‍💻 Autor
Desenvolvido por Santos H. B. Dias</p>
E-mail: santoshbdias@gmail.com
---

📄 Licença
Este pacote está licenciado sob a MIT License.

