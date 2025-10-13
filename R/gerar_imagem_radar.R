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

gerar_imagem_radar <- function(cidade, raio) {

  # Detectar pasta de Downloads
  downloads_dir <- switch(Sys.info()[["sysname"]],
                          "Windows" = file.path(Sys.getenv("USERPROFILE"), "Downloads"),
                          "Darwin"  = file.path(Sys.getenv("HOME"), "Downloads"),  # macOS
                          "Linux"   = file.path(Sys.getenv("HOME"), "Downloads"))   # Linux

  pasta_saida <- file.path(downloads_dir, "Radar.Simepar")

  # Verifique se a pasta existe antes de tentar limpá-la
  if (dir.exists(pasta_saida)) {
    # Liste todos os arquivos e subdiretórios na pasta
    # O parâmetro `all.files = TRUE` garante que arquivos ocultos também sejam listados
    arquivos_para_apagar <- list.files(pasta_saida,
                                       full.names = TRUE,
                                       recursive = TRUE,
                                       all.files = TRUE)

    # A função `list.files` inclui o diretório `.` e `..`, que não devem ser apagados.
    # Esta linha remove esses itens da lista.
    arquivos_para_apagar <- arquivos_para_apagar[!basename(arquivos_para_apagar) %in% c(".", "..")]

    # Use `unlink()` para apagar todos os arquivos e subdiretórios
    # `recursive = TRUE` apaga subdiretórios e seus conteúdos
    # `force = TRUE` força a remoção mesmo que haja problemas de permissão (use com cautela)
    unlink(arquivos_para_apagar, recursive = TRUE, force = TRUE)

    arquivos_para_apagar <- list.files(pasta_saida,
                                       full.names = TRUE,
                                       recursive = TRUE,
                                       all.files = TRUE)

    if (length(arquivos_para_apagar) == 0) {
      cat("A pasta foi limpa com sucesso.\n")
    } else {
      cat("Atenção: Não foi possível apagar todos os arquivos. Feche os arquivos abertos em outros programas.\n")
    }

  } else {
    dir.create(pasta_saida, recursive = TRUE)
    cat("O caminho especificado foi criado.\n")
  }

  caminho <- paste0(pasta_saida,'/',cidade,'.png')

  radar_img <- tryCatch(
    DigiAgRes::baixar_radar_PR(),
    error = function(e) {
      cat("\u274c Erro ao baixar imagem do radar: ", conditionMessage(e), "\n")
      return(NULL)
    }
  )

  if (is.null(radar_img)) return(NULL)

  coords <- list(
    'Cianorte' = list(x = 388, y = 240),
    'PresidenteCasteloBranco'  = list(x = 437, y = 190),
    'PontaGrossa' = list(x = 613, y = 361),
    'Cambé' = list(x = 509, y = 185),
    'Guarapuava' = list(x = 483, y = 405),
    'Toledo' = list(x = 308, y = 335),
    'DoisVizinhos' = list(x = 340, y = 420)
  )

  img_plot <- magick::image_draw(radar_img)

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
  dev.off()

  magick::image_write(img_plot, path = caminho, format = "png")

  return(img_plot)
}
