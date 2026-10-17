# Cálculos y constantes de la receta (funciones puras, sin Shiny).
# Cálculo con porcentajes panaderos (relativos al peso de harina)
calcular_receta <- function(n_masas, peso_masa, hidratacion, sal, levadura, sobremasa = 0) {
  # La sobremasa compensa la masa que se pierde durante el proceso
  masa_total <- n_masas * peso_masa * (1 + sobremasa / 100)
  harina <- masa_total / (1 + (hidratacion + sal + levadura) / 100)
  data.frame(
    Ingrediente = c("Harina", "Agua", "Sal", "Levadura", "Total"),
    Gramos = c(
      harina,
      harina * hidratacion / 100,
      harina * sal / 100,
      harina * levadura / 100,
      masa_total
    )
  )
}

MAX_HARINAS <- 6

# Temperatura del agua para iniciar el amasado: 60 - T ambiente - T harina
calcular_temp_agua <- function(temp_ambiente, temp_harina, constante = 60) {
  constante - temp_ambiente - temp_harina
}

# Mezcla de agua fría (T1) y caliente (T2) para alcanzar una temperatura final.
# Balance de calor: m1*T1 + m2*T2 = total*T_final, con m1 + m2 = total
calcular_mezcla_agua <- function(total, temp_final, temp_fria, temp_caliente) {
  caliente <- total * (temp_final - temp_fria) / (temp_caliente - temp_fria)
  c(fria = total - caliente, caliente = caliente)
}

# --- Modelo de levadura -------------------------------------------------------
# Modelo empírico simplificado (aproximado, no es el de Pizzablab):
#   % levadura instantánea = REF_PCT * (REF_HORAS / horas) * Q10^((REF_TEMP - T) / 10)
# Constantes ajustadas por mínimos cuadrados (en logaritmos) a ~10 puntos de tablas
# de blogs de pizza: 24 h a 20 °C -> 0.13 % de levadura instantánea, Q10 = 1.39.
# Ver notas_investigacion.txt. Reajustar cuando haya datos propios.
REF_PCT   <- 0.13
REF_HORAS <- 24
REF_TEMP  <- 20
Q10       <- 1.39

# Equivalencia respecto a la levadura instantánea (seca)
FACTOR_LEVADURA <- c(instantanea = 1, fresca = 3, seca_activa = 1.25)

calcular_levadura_pct <- function(horas, temp, tipo = "instantanea") {
  pct_inst <- REF_PCT * (REF_HORAS / horas) * Q10^((REF_TEMP - temp) / 10)
  pct_inst * FACTOR_LEVADURA[[tipo]]
}

TIPOS_LEVADURA <- c(
  "Instantánea (seca)" = "instantanea",
  "Fresca" = "fresca",
  "Seca activa" = "seca_activa"
)
