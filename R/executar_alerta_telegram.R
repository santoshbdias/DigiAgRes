#' Executa análise do radar meteorológico e envia alerta com imagem via Telegram
#'
#' @description Esta função realiza a análise da imagem de radar meteorológico do estado do Paraná (via Simepar),
#' identificando a ocorrência de chuva nas proximidades de uma cidade especificada. Em caso positivo, uma imagem
#' com marcações geográficas e legenda é enviada automaticamente para um grupo ou chat no Telegram.
#'
#' @param mega Nome da cidade a ser monitorada. Deve ser um dos nomes previamente cadastrados na função (ex: "Cianorte", "Castelo").
#' @param chat_id Código identificador do grupo ou chat do Telegram (ex: "-1001234567890").
#' @param bot_token Token do bot do Telegram (obtido via @BotFather).
#'
#' @details A imagem de radar é obtida em tempo real do Simepar. A função compara os valores RGB de pixels centrais da cidade para inferir a presença de chuva.
#' A mensagem enviada inclui imagem com marcações e legenda no formato Markdown.
#'
#' @import httr
#' @import magick
#'
#' @return Não retorna valor, mas envia uma mensagem automática ao Telegram em caso de detecção de chuva.
#'
#' @author Santos Henrique Brant Dias
#' @export

executar_alerta_telegram <- function(mega, chat_id, bot_token) {

  # Coordenadas conhecidas
  coords <- list(
    "Cianorte" = list(x = 388, y = 240),
    "Castelo"  = list(x = 435, y = 190)
  )

  if (!(mega %in% names(coords))) {
    stop("Cidade não cadastrada. Adicione as coordenadas na lista 'coords'.")
  }

  x_centro <- coords[[mega]]$x
  y_centro <- coords[[mega]]$y
  raio <- 55

  cat(format(Sys.time(), "%H:%M"), "- Verificando radar para:", mega, "\n")

  img <- tryCatch(baixar_radar_PR(), error = function(e) NULL)
  if (is.null(img)) {
    message("❌ Falha ao baixar imagem do radar.")
    return(invisible(NULL))
  }

  resultado <- analisar_radar_PR(img, mega = mega, raio = raio)

  #resultado = "Risco de chuva (verde)"

  if (resultado %in% c("Risco de chuva (verde)", "Chuva leve (amarelo)", "Chuva forte (vermelho)")) {
    legenda <- paste0("🚨 Alerta meteorológico em *", mega, "*:\n", resultado)

    # Desenhar pontos no mapa
    caminho_imagem <- tempfile(fileext = ".png")

    img_plot <- image_draw(img)

    for (cidade in names(coords)) {
      x <- coords[[cidade]]$x
      y <- coords[[cidade]]$y
      points(x, y, col = "red", pch = 19, cex = 2) # centro
      points(x + raio, y,     col = "purple", pch = 19, cex = 1)
      points(x - raio, y,     col = "purple", pch = 19, cex = 1)
      points(x,     y + raio, col = "purple", pch = 19, cex = 1)
      points(x,     y - raio, col = "purple", pch = 19, cex = 1)
    }
    dev.off()

    print(img_plot)

    magick::image_write(img_plot, path = caminho_imagem, format = "png")

    # Enviar imagem via Telegram
    httr::POST(
      url = paste0("https://api.telegram.org/bot", bot_token, "/sendPhoto"),
      body = list(
        chat_id = chat_id,
        photo = httr::upload_file(caminho_imagem),
        caption = legenda,
        parse_mode = "Markdown"
      )
    )
    cat("✅ Alerta enviado com sucesso para Telegram.\n")
  } else {
    cat("ℹ️ Sem chuva detectada para:", mega, "\n")
  }
}
