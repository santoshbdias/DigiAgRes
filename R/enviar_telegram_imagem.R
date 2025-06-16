#' Envia uma imagem para um grupo ou usuário no Telegram
#'
#' @description Envia uma imagem (foto) para um grupo ou chat privado no Telegram usando um bot previamente configurado. É necessário que o bot tenha sido adicionado ao grupo e tenha permissão para enviar mensagens.
#'
#' @param bot_token Token do bot do Telegram, obtido via BotFather (ex: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11").
#' @param chat_id Identificador do chat ou grupo. Para grupos, o ID começa com "-100".
#' @param caminho_imagem Caminho completo da imagem local a ser enviada (ex: "img/chuva_radar.png").
#' @param legenda (Opcional) Texto da legenda a ser enviada junto com a imagem. Pode conter formatação Markdown.
#'
#' @return Retorna a resposta da API do Telegram.
#'
#' @importFrom httr POST upload_file
#'
#' @examples
#' \dontrun{
#' enviar_telegram_imagem(
#'   bot_token = "123456:ABC-DEF1234g3ew11",
#'   chat_id = "-9999999999999",
#'   caminho_imagem = "radar/chuva_atual.jpeg",
#'   legenda = "🚨 Alerta de chuva detectada na região!"
#' )
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

enviar_telegram_imagem <- function(bot_token, chat_id, caminho_imagem, legenda = "") {
  httr::POST(
    url = paste0("https://api.telegram.org/bot", bot_token, "/sendPhoto"),
    body = list(
      chat_id = chat_id,
      photo = httr::upload_file(caminho_imagem),
      caption = legenda,
      parse_mode = "Markdown"
    )
  )
}








