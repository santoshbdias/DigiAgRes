#' Analisa a cor média em uma região circular do radar e interpreta intensidade de chuva
#'
#' @description Esta função analisa uma imagem de radar meteorológico e classifica a intensidade de chuva com base na cor (RGB) de uma área circular ao redor de coordenadas específicas.
#'
#' @param img Imagem de radar obtida pela função \code{baixar_radar_PR()}.
#' @param mega Nome da cidade/ponto de interesse. Aceita: "Cianorte", "Castelo", "teste".
#' @param raio Raio em pixels da área circular a ser analisada (default = 55).
#'
#' @return Texto indicando a condição meteorológica: "Chuva forte", "Chuva leve", "Risco de chuva" ou "Sem chuvas".
#'
#' @importFrom magick image_draw
#' @importFrom magick image_data
#'
#' @examples
#' \dontrun{
#' img <- baixar_radar_PR()
#' result <- analisar_radar_PR(img, mega = "Cianorte", raio = 50)
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

analisar_radar_PR <- function(img, mega='Castelo', raio=50) {

  if (mega == 'Cianorte') {
    x_centro=388
    y_centro=240
  } else if (mega == 'Castelo') {
    x_centro=435
    y_centro=190
  } else if (mega == 'teste') {
    x_centro=435
    y_centro=350
  }

  #Verificar coordenadas
  image_draw(img)
  points(x_centro, y_centro, col = "red", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(x_centro+raio, y_centro, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(x_centro-raio, y_centro, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(x_centro, y_centro+raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  points(x_centro, y_centro-raio, col = "purple", pch = 19, cex = 2)  # ajuste até bater com Cascavel
  dev.off()

  img_data <- image_data(img, channels = "rgb")

  largura <- dim(img_data)[2]
  altura  <- dim(img_data)[3]

  # Inicializa vetores
  r_vals <- c(); g_vals <- c(); b_vals <- c()

  for (x in seq(x_centro - raio, x_centro + raio, by = 2)) {
    for (y in seq(y_centro - raio, y_centro + raio, by = 2)) {
      if (x > 0 & x <= largura & y > 0 & y <= altura) {
        dist <- sqrt((x - x_centro)^2 + (y - y_centro)^2)
        if (dist <= raio) {
          r_vals <- c(r_vals, as.numeric(img_data[1, x, y]))
          g_vals <- c(g_vals, as.numeric(img_data[2, x, y]))
          b_vals <- c(b_vals, as.numeric(img_data[3, x, y]))
        }
      }
    }
  }

  #plot(img_data[2,,])

  # Calcula a média de cor
  media_r <- mean(r_vals); media_r
  media_g <- mean(g_vals); media_g
  media_b <- mean(b_vals); media_b

  # Classificação
  resultado <- if (media_r > 180 & media_g < 100) {
    "Chuva forte (vermelho)"
  } else if (media_g > 180 & media_b < 100) {
    "Chuva leve (amarelo)"
  } else if (media_b > 180) {
    " Risco de chuva (verde)"
  } else {
    "Sem chuvas"
  }
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "- Resultado:", resultado, "\n")
  return(resultado)
}
