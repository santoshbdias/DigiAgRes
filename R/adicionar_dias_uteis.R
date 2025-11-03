#' Adiciona dias úteis a uma data consultando feriados via API
#'
#' @description
#' Esta função calcula uma data futura (ou passada) adicionando um número específico de
#' dias úteis a uma data inicial. Ela automaticamente busca feriados nacionais
#' brasileiros (via \code{brasilapi.com.br}) para garantir a precisão do cálculo,
#' descontando fins de semana e feriados.
#'
#' @param data_inicio Data inicial para o cálculo (formato Date, ou string "YYYY-MM-DD").
#'                    Default: \code{Sys.Date()} (hoje).
#' @param dias_uteis Número de dias úteis a adicionar. Pode ser um número
#'                   positivo (para o futuro) ou negativo (para o passado).
#'
#' @return Retorna um objeto \code{Date} com a data final calculada.
#'
#' @details
#' A função depende dos pacotes \code{bizdays} (para o cálculo) e \code{jsonlite}
#' (para ler a API).
#'
#' Ela busca feriados do ano da \code{data_inicio} e do ano seguinte para
#' garantir que cálculos que cruzam a virada do ano funcionem corretamente.
#'
#' Se a API falhar, um aviso (\code{warning}) será emitido e o cálculo será
#' feito considerando apenas sábados e domingos como dias não úteis.
#'
#' @importFrom bizdays create.calendar add.bizdays
#' @importFrom jsonlite fromJSON
#'
#' @examples
#' \dontrun{
#' # Pré-requisito: instalar os pacotes
#' # install.packages("bizdays")
#' # install.packages("jsonlite")
#'
#' # --- Exemplo 1: Calcular 15 dias úteis a partir de hoje ---
#' data_futura <- adicionar_dias_uteis(dias_uteis = 15)
#' print(paste("15 dias úteis a partir de hoje será:", data_futura))
#'
#'
#' # --- Exemplo 2: Calcular 5 dias úteis pulando feriados (Natal/Ano Novo) ---
#' data_base <- as.Date("2024-12-20")
#' proxima_data <- adicionar_dias_uteis(data_base, 5)
#' # O resultado pulará 24, 25, 28, 29, 31/Dez e 01/Jan (se for feriado nacional)
#' print(paste("5 dias úteis após 20/12/2024 será:", proxima_data))
#'
#'
#' # --- Exemplo 3: Calcular 10 dias úteis *antes* de uma data ---
#' data_passada <- adicionar_dias_uteis(as.Date("2025-03-01"), -10)
#' print(paste("10 dias úteis antes de 01/03/2025 foi:", data_passada))
#' }
#'
#' @export


adicionar_dias_uteis <- function(data_inicio = Sys.Date(), dias_uteis) {

  # --- 1. Validação de Inputs ---
  if (missing(dias_uteis) || !is.numeric(dias_uteis)) {
    stop("O argumento 'dias_uteis' é obrigatório e deve ser um número.", call. = FALSE)
  }

  # Garantir que a data de início seja um objeto Date
  tryCatch({
    data_inicio <- as.Date(data_inicio)
  }, error = function(e) {
    stop("O argumento 'data_inicio' não pôde ser convertido para Data. Use o formato 'YYYY-MM-DD'.", call. = FALSE)
  })

  # Dependências (Verifica se os pacotes estão instalados)
  if (!requireNamespace("bizdays", quietly = TRUE)) {
    stop("Pacote 'bizdays' é necessário. Por favor, instale com install.packages('bizdays')", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Pacote 'jsonlite' é necessário. Por favor, instale com install.packages('jsonlite')", call. = FALSE)
  }


  # --- 2. Função Interna para buscar Feriados na API ---
  # (Usamos uma função interna para não poluir o ambiente global)
  .fetch_feriados_api <- function(ano) {
    url_api <- paste0("https://brasilapi.com.br/api/feriados/v1/", ano)
    tryCatch({
      feriados_df <- jsonlite::fromJSON(url_api)
      return(as.Date(feriados_df$date))
    }, error = function(e) {
      warning(paste("Aviso: Falha ao buscar feriados de", ano, "da API. (", e$message, ")"), call. = FALSE)
      return(NULL)
    })
  }

  # --- 3. Buscar Feriados (Ano atual e próximo) ---

  # Pegamos o ano da data de início e o ano seguinte
  # Isso cobre cálculos que começam no fim de um ano e terminam no outro
  ano_1 <- as.numeric(format(data_inicio, "%Y"))
  ano_2 <- ano_1 + 1

  # (Se o cálculo for para o passado, talvez precisemos do ano anterior)
  if (dias_uteis < 0) {
    # Estimativa simples da data passada
    data_fim_estimada <- data_inicio + (dias_uteis * 1.5) # 1.5 para cobrir fins de semana
    ano_0 <- as.numeric(format(data_fim_estimada, "%Y"))

    # Se o ano estimado for diferente, buscamos ele e o ano de início
    if(ano_0 != ano_1) {
      ano_1 <- ano_0
      ano_2 <- as.numeric(format(data_inicio, "%Y"))
    }
  }

  feriados_list <- list()
  feriados_list[[1]] <- .fetch_feriados_api(ano_1)
  feriados_list[[2]] <- .fetch_feriados_api(ano_2)

  # Combinar e remover duplicatas (caso a API retorne algo sobreposto)
  feriados_datas <- unique(do.call(c, feriados_list))


  # --- 4. Criar o Calendário 'bizdays' ---

  # Define os dias não úteis (fins de semana)
  dias_nao_uteis <- c("saturday", "sunday")

  if (length(feriados_datas) > 0) {
    # Se a API funcionou, cria o calendário com feriados
    cal <- bizdays::create.calendar("BR_FERIADOS_API",
                                    holidays = feriados_datas,
                                    weekdays = dias_nao_uteis)
  } else {
    # Fallback: Se a API falhou, usa apenas fins de semana
    warning("Nenhum feriado da API foi carregado. Calculando apenas com Sáb/Dom.", call. = FALSE)
    cal <- bizdays::create.calendar("FIM_DE_SEMANA",
                                    weekdays = dias_nao_uteis)
  }

  # --- 5. Calcular e Retornar a Data ---

  # A função add.bizdays faz o cálculo (funciona para dias positivos e negativos)
  data_final <- bizdays::add.bizdays(data_inicio, dias_uteis, cal)

  return(data_final)
}
