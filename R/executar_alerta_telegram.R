#' Executa análise do radar meteorológico e envia alerta com imagem via Telegram
#'
#' @description Esta função realiza a análise da imagem de radar meteorológico do estado do Paraná (via Simepar),
#' identificando a ocorrência de chuva nas proximidades de uma cidade especificada. Em caso positivo, uma imagem
#' com marcações geográficas e legenda é enviada automaticamente para um grupo ou chat no Telegram.
#'
#' @param mega Nome da cidade a ser monitorada. Deve ser um dos nomes previamente cadastrados na função (ex: "Cianorte", "Castelo").
#' @param chat_id Código identificador do grupo ou chat do Telegram (ex: "-1001234567890").
#' @param bot_token Token do bot do Telegram (obtido via @BotFather).
#' @param raio Raio que vai considerar as nuvens
#'
#' @details A imagem de radar é obtida em tempo real do Simepar. A função compara os valores RGB de pixels centrais da cidade para inferir a presença de chuva.
#' A mensagem enviada inclui imagem com marcações e legenda no formato Markdown.
#'
#' @import httr
#' @import magick
#'
#'@examples
#' if (interactive()) {
#'executar_alerta_telegram(mega="Cianorte", chat_id="555585458", bot_token="555585458", raio = 50)
#'}
#'
#' @return Não retorna valor, mas envia uma mensagem automática ao Telegram em caso de detecção de chuva.
#'
#' @author Santos Henrique Brant Dias
#' @export

executar_alerta_telegram <- function(mega="Cianorte", chat_id, bot_token, raio = 50) {

  # Coordenadas conhecidas
  coords <- list(
    'Cianorte' = list(x = 388, y = 240),
    'PresidenteCasteloBranco'  = list(x = 437, y = 190),
    'PontaGrossa' = list(x = 613, y = 361),
    'Cambé' = list(x = 509, y = 185),
    'Guarapuava' = list(x = 483, y = 405),
    'Toledo' = list(x = 308, y = 335),
    'DoisVizinhos' = list(x = 340, y = 420)
  )

  if (!(mega %in% names(coords))) {
    stop("Cidade não cadastrada. Adicione as coordenadas na lista 'coords'.")
  }

  cat(format(Sys.time(), "%H:%M"), "- Verificando radar para:", mega, "\n")

  img <- tryCatch(DigiAgRes::baixar_radar_PR(), error = function(e) NULL)
  if (is.null(img)) {
    message("❌ Falha ao baixar imagem do radar.")
    return(invisible(NULL))
  }

  rgb_Res <- DigiAgRes::analisar_radar_PR(img, mega = 'PresidenteCasteloBranco', raio)

  #print(rgb_Res)

  # Classificação
  resultado <- if (rgb_Res$R > 70 & rgb_Res$B < 25) {
    "Chuva forte (vermelho)"
  } else if (rgb_Res$R > 65 & rgb_Res$B < 33) {
    "Chuva leve (amarelo)"
  } else {'Sem chuva'}

  if (resultado %in% c("Chuva leve (amarelo)", "Chuva forte (vermelho)")) {
    legenda <- paste0("🚨 Alerta meteorológico em *", mega, "*:\n", resultado)

    # Detectar pasta de Downloads
    downloads_dir <- switch(Sys.info()[["sysname"]],
                            "Windows" = file.path(Sys.getenv("USERPROFILE"), "Downloads"),
                            "Darwin"  = file.path(Sys.getenv("HOME"), "Downloads"),  # macOS
                            "Linux"   = file.path(Sys.getenv("HOME"), "Downloads"))   # Linux

    caminho <- paste0(downloads_dir, "/Radar.Simepar/",mega,'.png')

    # Enviar imagem via Telegram
    httr::POST(
      url = paste0("https://api.telegram.org/bot", bot_token, "/sendPhoto"),
      body = list(
        chat_id = chat_id,
        photo = httr::upload_file(caminho),
        caption = legenda,
        parse_mode = "Markdown"
      )
    )
    cat("✅ Alerta enviado com sucesso para Telegram.\n")
  } else {
    cat("ℹ️ Sem chuva detectada para:", mega, "\n")
  }
}














