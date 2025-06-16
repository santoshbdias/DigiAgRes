#' Envia alerta por e-mail via Gmail
#'
#' @description Envia uma mensagem de alerta meteorológico por e-mail usando servidor SMTP autenticado (Gmail). Atenção: essa senha deve ser uma senha de aplicativo,gerada em https://myaccount.google.com/apppasswords
#'
#' @param from_email Endereço de e-mail do remetente (ex: "seuemail@gmail.com").
#' @param to_email Endereço de e-mail do destinatário.
#' @param senha_app Senha de aplicativo do Gmail (não é a senha normal). #Gere em: https://myaccount.google.com/apppasswords.
#' @param corpo_mensagem Texto da mensagem (default: "🚨 Alerta de chuva detectada!").
#'
#' @importFrom emayili envelope server
#'
#' @examples
#' \dontrun{
#' enviar_email_alerta(
#'   from_email = "seuemail",
#'   to_email = "destino",
#'   senha_app = "abcxyz123456"
#' )
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

enviar_email_alerta <- function(from_email, to_email, senha_app, corpo_mensagem = "🚨 Alerta de chuva detectada!") {

  # Configura SMTP do Gmail
  smtp <- emayili::server(
    host = "smtp.gmail.com",
    port = 587,
    username = from_email,
    password = senha_app
  )

  # Cria a mensagem
  email <- emayili::envelope() |>
    from(from_email) |>
    to(to_email) |>
    subject("🌧️ Alerta de chuva no radar - Simepar") |>
    text(corpo_mensagem)

  # Envia
  smtp(email, verbose = TRUE)
}

