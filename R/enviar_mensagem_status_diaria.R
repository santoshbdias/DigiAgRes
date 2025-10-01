#' Envia uma mensagem de status com imagem do radar meteorológico via Telegram
#'
#' @description
#' Esta função verifica se o horário atual coincide com o horário programado (\code{hora_alerta}) e, se for o caso, envia uma imagem do radar meteorológico para o Telegram, indicando que o sistema está ativo.
#'
#' @param hora_alerta Horário programado para envio da mensagem (formato "HH:MM"). Default: "13:00".
#' @param img_plot Objeto de imagem gerado por \code{magick::image_draw()}, contendo o radar com marcações.
#' @param bot_token Token do bot do Telegram obtido via \code{@BotFather}.
#' @param chat_id ID do chat ou grupo do Telegram que receberá a mensagem.
#'
#' @return Retorna \code{NULL} de forma invisível. Utiliza efeitos colaterais (envio de mensagem).
#'
#' @details
#' A imagem será salva temporariamente e enviada com uma legenda informando que o sistema de alerta meteorológico está funcionando. Se o horário atual for diferente de \code{hora_alerta}, ou se a imagem estiver ausente, nada será enviado.
#'
#' @importFrom magick image_write
#' @importFrom httr POST upload_file
#'
#' @examples
#' \dontrun{
#' enviar_mensagem_status_diaria(
#'   hora_alerta = "13:00",
#'   img_plot = radar_img,
#'   bot_token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
#'   chat_id = "-1001234567890"
#' )
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

enviar_mensagem_status_diaria <- function(hora_alerta='13:00', bot_token, chat_id,
                                          mensagem = 'Mensagem diária de status. Sistema de alerta meteorológico ativo e funcionando perfeitamente.') {
  radar_img <- tryCatch(
    DigiAgRes::baixar_radar_PR(),
    error = function(e) {
      cat("\u274c Erro ao baixar imagem do radar: ", conditionMessage(e), "\n")
      return(NULL)
    }
  )

  hora_atual <- format(Sys.time(), "%H:%M")

  if (hora_atual != hora_alerta) {
    return(invisible(NULL))
  }

  # Detectar pasta de Downloads
  downloads_dir <- switch(Sys.info()[["sysname"]],
                          "Windows" = file.path(Sys.getenv("USERPROFILE"), "Downloads"),
                          "Darwin"  = file.path(Sys.getenv("HOME"), "Downloads"),  # macOS
                          "Linux"   = file.path(Sys.getenv("HOME"), "Downloads"))   # Linux

  pasta_saida <- file.path(downloads_dir, "Radar.Simepar")

  if (!dir.exists(pasta_saida)) dir.create(pasta_saida, recursive = TRUE)

  caminho <- paste0(pasta_saida,'/Status.png')

  # Excluir arquivos zip corrompidos
  if (file.exists(caminho)) file.remove(caminho)

  img_salva <- tryCatch({
    magick::image_write(radar_img, path = caminho, format = "png")
    TRUE
  }, error = function(e) {
    cat("❌ Erro ao salvar imagem: ", conditionMessage(e), "\n")
    FALSE
  })

  if (!img_salva) return(invisible(NULL))

  tryCatch({
    httr::POST(
      url = paste0("https://api.telegram.org/bot", bot_token, "/sendPhoto"),
      body = list(
        chat_id = chat_id,
        photo = httr::upload_file(caminho),
        caption = mensagem,
        parse_mode = "Markdown"
      )
    )
    cat("✅ Mensagem diária de status enviada.\n")
    }, error = function(e) {
    cat("❌ Erro ao enviar mensagem no Telegram: ", conditionMessage(e), "\n")
  })

  invisible(NULL)
}
