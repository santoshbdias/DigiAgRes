#' Faz o download de imagem de radar meteorológico do PR (Simepar)
#'
#' @description Esta função acessa a imagem mais recente do radar do Paraná disponibilizada pelo Simepar e retorna uma imagem tipo magick.
#'
#' @return Uma imagem (`magick-image`) contendo o radar meteorológico atual do estado do Paraná.
#' @import httr
#' @import magick
#'
#' @examples
#' \dontrun{
#' radar_img <- baixar_radar_PR()
#' }
#'
#' @author Santos Henrique Brant Dias
#' @export

baixar_radar_PR <- function() {
  url <- "https://lb01.simepar.br/riak/pgw-radar/product1.jpeg"
  img_path <- tempfile(fileext = ".jpeg")

  # Envia headers realistas
  resposta <- tryCatch({
    GET(
      url,
      add_headers(
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Referer" = "https://www.simepar.br/simepar/radar_msc"
      ) )
  }, error = function(e) {
    message("Erro ao acessar a imagem.")
    return(NULL)
  })

  if (is.null(resposta) || status_code(resposta) != 200) {
    cat("❌ Imagem não pode ser baixada. Status:", status_code(resposta), "\n")
    return(NULL)
  }
  writeBin(content(resposta, "raw"), img_path)

  img <- image_read(img_path)
  #print(img)

  return(img)
}

