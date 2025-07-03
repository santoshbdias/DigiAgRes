#' Gera imagem do radar meteorológico com marcações circulares e retorna imagem editada
#'
#' @description
#' Esta função baixa a imagem do radar meteorológico do Paraná e adiciona marcações circulares
#' ao redor das coordenadas de cidades de interesse. A imagem gerada pode ser usada para envio
#' por Telegram ou outras finalidades.
#'
#' @param coords Lista com coordenadas nomeadas das cidades. Exemplo: list("Cianorte" = list(x=388, y=240))
#' @param raio Raio da área de análise em pixels (default: 40)
#'
#' @return Objeto de imagem com as marcações, ou NULL se houver falha no download
#'
#' @importFrom magick image_draw image_write
#' @importFrom graphics points
#' @importFrom grDevices dev.off
#'
#' @examples
#'
#' coords <- list(
#'   'Cianorte' = list(x = 388, y = 240),
#'   'Castelo'  = list(x = 437, y = 190)
#' )
#' img_plot <- gerar_imagem_radar(coords)
#'
#' @author Santos Henrique Brant Dias
#' @export

gerar_imagem_radar <- function(coords, raio) {
  radar_img <- tryCatch(
    baixar_radar_PR(),
    error = function(e) {
      cat("\u274c Erro ao baixar imagem do radar: ", conditionMessage(e), "\n")
      return(NULL)
    }
  )

  if (is.null(radar_img)) return(NULL)

  img_plot <- image_draw(radar_img)

  for (cidade in names(coords)) {
    x_centro <- coords[[cidade]]$x
    y_centro <- coords[[cidade]]$y

    points(x_centro, y_centro, col = "red2", pch = 19, cex = 0.5)

    for (vr in seq(5, raio, by = ((raio - 5)/3))) {
      vri <- if (vr == 5) 0.01 else if (vr == raio) 0.2 else 0.1

      for (theta in seq(0, 2 * pi, length.out = 180)) {
        x <- round(x_centro + vr * cos(theta))
        y <- round(y_centro + vr * sin(theta))

        points(x, y, col = "royalblue1", pch = 19, cex = vri)
      }
    }
  }

  dev.off()
  return(img_plot)
}
