# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   https://r-pkgs.org
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'


#usethis::create_github_token()
#gitcreds::gitcreds_set()

#devtools::document()

#devtools::load_all()     # Para testar as funções sem instalar
#*devtools::document()     # Para gerar a documentação
#devtools::install()      # Para instalar como pacote
#
#devtools::check()
#
#devtools::test()
#
#
#usethis::use_vignette("nome-da-vignette") #Isso cria o arquivo: vignettes/nome-da-vignette.Rmd
#
#usethis::use_test("TopoData_download_to_vector")
#
#
#system('git config --global --add safe.directory "D:/OneDrive/Pesquisa/pacote_R/DigiAgRes"')
#
#system("git status")
#
#system("git add .")
#
#system('git commit -m "Atualizar TopoData"')
#
#system("git push")
#
#
#

# atualizar_github <- function(mensagem = "Atualização do pacote") {
#
#   system("git add .")
#
#   system2(
#     "git",
#     args = c(
#       "commit",
#       "-m",
#       shQuote(mensagem)
#     )
#   )
#
#   system("git push")
#
#   message("✅ GitHub atualizado.")
# }



#atualizar_github("Corrige TOPODATA")

