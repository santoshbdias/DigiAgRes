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
#' result <- analisar_radar_PR(img, mega = "Cianorte", raio = 55)
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

analisar_radar_PR <- function(img, mega='Castelo', raio) {

  coords <- list(
    'Cianorte' = list(x = 388, y = 240),
    'Castelo'  = list(x = 437, y = 190),
    'PontaGrossa' = list(x = 613, y = 361),
    'Cambé' = list(x = 509, y = 185),
    'Guarapuava' = list(x = 483, y = 405),
    'Toledo' = list(x = 308, y = 335),
    'DoisVizinhos' = list(x = 340, y = 420)
  )

  img_data <- image_data(img, channels = "rgb")

  largura <- dim(img_data)[2]
  altura  <- dim(img_data)[3]

  # Inicializa vetores
  r_vals <- c(); g_vals <- c(); b_vals <- c()

  for (theta in seq(0, 2*pi, length.out = 360)) {
    for (vr in seq(1, raio, by=5)) {
      x <- round(coords[[mega]]$x + vr * cos(theta))
      y <- round(coords[[mega]]$y + vr * sin(theta))

      r_vals <- c(r_vals, as.numeric(img_data[1, x, y]))
      g_vals <- c(g_vals, as.numeric(img_data[2, x, y]))
      b_vals <- c(b_vals, as.numeric(img_data[3, x, y]))
  } }

  #plot(img_data[2,,])

  # Calcula a média de cor
  media_r <- mean(r_vals); media_r
  media_g <- mean(g_vals); media_g
  media_b <- mean(b_vals); media_b

  return(list(R = media_r, G = media_g, B = media_b))
}
