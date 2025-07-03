rm(list = ls()); gc(); graphics.off(); cat("\014")# Atalho equivalente a Ctrl+L

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(rvest, dplyr, stringr, tidyr, httr)  # Instalar/ativar pacotes

extrair_info_miguilim <- function(url) {
  id <- stringr::str_extract(url, "\\d+$")

  res <- tryCatch(httr::GET(url), error = function(e) return(NULL))
  if (is.null(res) || httr::status_code(res) != 200) return(NULL)

  page <- tryCatch(read_html(httr::content(res, as = "text")), error = function(e) return(NULL))
  if (is.null(page)) return(NULL)

  tabelas <- page %>% html_elements("table")
  if (length(tabelas) == 0) return(NULL)

  tds <- tabelas[[1]] %>% html_elements("td") %>% html_text(trim = TRUE)
  if (length(tds) < 2 || length(tds) %% 2 != 0) return(NULL)

  chaves <- tds[seq(1, length(tds), 2)]
  valores <- tds[seq(2, length(tds), 2)]

  df <- tibble::tibble(chave = chaves, valor = valores) %>%
    dplyr::distinct(chave, .keep_all = TRUE) %>%
    tidyr::pivot_wider(names_from = chave, values_from = valor)

  df$id <- id
  df$url <- url
  return(df)
}

ids <- sprintf("%04d", 3000:9200)#3706:3710
urls <- paste0("https://miguilim.ibict.br/handle/miguilim/", ids)

dados_revistas <- list()
for (i in seq_along(urls)) {
  cat(sprintf("🔍 [%02d/%02d] Coletando ID %s\n", i, length(urls), ids[i]))
  resultado <- extrair_info_miguilim(urls[i])
  if (!is.null(resultado)) {
    dados_revistas[[length(dados_revistas) + 1]] <- resultado
  }
}

df_final <- bind_rows(dados_revistas)

write.csv(df_final, file = "S:/OneDrive/Pesquisa/wArquivos/Avaliacao_Revistas/dados_miguilim.csv", fileEncoding = "ISO-8859-1", row.names = T)




# rm(list = ls()); gc(); graphics.off(); cat("\014")# Atalho equivalente a Ctrl+L
#
# if(!require("pacman")) install.packages("pacman");pacman::p_load(
#   readxl, readr, dplyr,stringr)  # Instalar/ativar pacotes
#
# #JCR - Journal Citation Reports™
# #https://jcr.clarivate.com/jcr/home?app=jcr&Init=Yes&authCode=epvM0RuBy7C9wKi0TQ7NVApNhkCFDvtGwt6qovLeSZs&SrcApp=IC2LS
#
# tipos_jcr <- cols(
#   `Journal name` = col_character(),
#   `JCR Abbreviation` = col_character(),
#   `Publisher` = col_character(),
#   `ISSN` = col_character(),
#   `eISSN` = col_character(),
#   `Category` = col_character(),
#   `Edition` = col_character(),
#   `Total Citations` = col_number(),
#   `2024 JIF` = col_double(),
#   `JIF Quartile` = col_character(),
#   `2024 JCI` = col_double(),
#   `% of Citable OA` = col_character()
# )
#
# # Lê todos os arquivos com os mesmos tipos
# arquivos <- list.files("S:/OneDrive/Pesquisa/wArquivos/Avaliacao_Revistas",
#                        pattern = "Santos H. B.BDias_JCR_JournalResults_06_2025.*csv",
#                        full.names = TRUE)
#
# # Lê e une os arquivos de forma robusta
# dfJCR <- arquivos %>%
#   lapply(read_csv, skip = 1, col_types = tipos_jcr) %>%
#   bind_rows()
#
# dfJCR <- dfJCR %>%
#   mutate(
#     ISSN_clean = str_replace_all(ISSN, "-", ""),
#     eISSN_clean = str_replace_all(eISSN, "-", "")
#   )
#
# jcr_issn <- dfJCR %>%
#   select(ISSN_clean, `2024 JIF`, `JIF Quartile`, `2024 JCI`)
# jcr_eissn <- dfJCR %>%
#   select(ISSN_clean=eISSN_clean, `2024 JIF`, `JIF Quartile`, `2024 JCI`)
#
# jcr_issn <- dplyr::bind_rows(jcr_issn, jcr_eissn) %>%
#   filter(!is.na(ISSN_clean), ISSN_clean != "", ISSN_clean != "N/A") %>%
# distinct(ISSN_clean, .keep_all = TRUE)
#
#
#
# #Link plataforma_Sucupira
# #https://sucupira-legado.capes.gov.br/sucupira/public/consultas/coleta/veiculoPublicacaoQualis/listaConsultaGeralPeriodicos.jsf
#
# #classificacoes_publicadas_interdisciplinar_2022_1721678840913.xlsx
# dfinter <- read_excel('S:/OneDrive/Pesquisa/wArquivos/Avaliacao_Revistas/classificacoes_publicadas_interdisciplinar_2022_1721678840913.xlsx')
# dfinter <- dfinter %>% mutate(ISSN_clean = str_replace_all(ISSN, "-", ""))
#
# #classificacoes_publicadas_ciencias_agrarias_i_2022_1721678830314.xls
# dfagro <- read_excel('S:/OneDrive/Pesquisa/wArquivos/Avaliacao_Revistas/classificacoes_publicadas_ciencias_agrarias_i_2022_1721678830314.xlsx')
# dfagro <- dfagro %>% mutate(ISSN_clean = str_replace_all(ISSN, "-", ""))
#
# # 2. Marca se também está na interdisciplinar
# issn_inter <- dfinter$ISSN_clean
# dfagro <- dfagro %>%
#   mutate(
#     Interdisciplinar = if_else(ISSN_clean %in% issn_inter, "SIM", "NÃO"),
#     Area = "CIÊNCIAS AGRÁRIAS I"
#   )
#
# dfagro_jcr <- left_join(dfagro, jcr_issn, by = c("ISSN_clean" = "ISSN_clean"))
#
# rm(dfagro,dfinter,dfJCR,jcr_eissn,jcr_issn,tipos_jcr, arquivos, issn_inter)
#
# writexl::write_xlsx(dfagro_jcr, "C:/Users/server_SantosDias/Downloads/jcr_agro_qualis.xlsx")#Altere aqui o caminho para o seu computador
#
# head(dfagro_jcr)
#
# oi<-dfagro_jcr %>%
#   filter(grepl("agro", Título, ignore.case = TRUE)) %>%
#   filter(Interdisciplinar == 'SIM' )
#
# dfagro_jcr %>%
#   filter(ISSN_clean == '00068705')
#
# #qualis_top <- df_qualis %>%
# #  dplyr::filter(Estrato %in% c("A1", "A2"))
# #dplyr::filter(df_qualis, grepl("agronomia", Título, ignore.case = TRUE))
#
# # 1. Padronizar ISSNs
# df_qualis <- df_qualis %>%
#   mutate(ISSN_clean = str_replace_all(ISSN, "-", ""))
#
# dfJCR <- dfJCR %>%
#   mutate(
#     ISSN_clean = str_replace_all(ISSN, "-", ""),
#     eISSN_clean = str_replace_all(eISSN, "-", "")
#   )
#
# # 2. Primeiro join pelo ISSN
# join1 <- left_join(df_qualis, dfJCR, by = "ISSN_clean", relationship = "many-to-many")
#
# # 3. Filtrar os que ainda estão sem JIF
# faltantes <- join1 %>%
#   filter(is.na(`2024 JIF`)) %>%
#   select(ISSN_original = ISSN_clean, Título, Estrato, Area)
#
# # 4. Fazer um join com o eISSN agora
# faltantes <- faltantes %>%
#   mutate(ISSN_original = str_replace_all(ISSN_original, "-", ""))
#
# com_eissn <- left_join(faltantes, dfJCR, by = c("ISSN_original" = "eISSN_clean"))
#
# # 5. Unir os dados que tinham JIF com os que agora têm por eISSN
# completos <- join1 %>% filter(!is.na(`2024 JIF`))
#
# df_qualis_jcr_final <- bind_rows(completos, com_eissn)
#
# # 6. Visualizar e conferir
# View(df_qualis_jcr_final)
#
# # 7. Quantos com JCR agora?
# sum(!is.na(df_qualis_jcr_final$`2024 JIF`))
#
#
#
#
# # Ver quantos tiveram correspondência
# sum(!is.na(df_qualis_jcr$`2024 JIF`))
