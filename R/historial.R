# Historial de recetas: serialización (JSON para el navegador, Excel para
# exportar/importar). Shiny carga automáticamente los archivos de R/.
#
# Cada receta es una lista: id, nombre, fecha y `entradas` (los parámetros).
# Los resultados no se guardan: se recalculan con calcular_resultados().

CAMPOS_ENTRADA <- c(
  "n_masas", "peso_masa", "hidratacion", "sal", "levadura", "sobremasa",
  "autolisis", "temp_ambiente", "temp_harina", "temp_fria", "temp_caliente",
  "temp_fermentacion", "horas_fermentacion"
)
# Interruptores (0/1) de los apartados opcionales. No son obligatorios para que
# sigan siendo válidas las recetas guardadas antes de que existieran.
CAMPOS_OPCIONALES <- c("usar_temp", "usar_autolisis", "usar_harinas")
TIPOS_VALIDOS <- c("instantanea", "fresca", "seca_activa")

# Valor por defecto si x es NULL
`%||%` <- function(x, y) if (is.null(x)) y else x
MAX_NOMBRE <- 80

# Estado de un interruptor opcional. En recetas guardadas antes de que existiera
# se asume activado (así se veían), salvo la mezcla de harinas, que se mostraba
# solo si había más de una.
valor_opcional <- function(e, k) {
  e[[k]] %||% if (k == "usar_harinas") as.numeric(length(e$harinas) > 1) else 1
}

nuevo_id <- function() {
  paste0("r", format(Sys.time(), "%Y%m%d%H%M%S"), sample(1000:9999, 1))
}

# Resultados de una receta a partir de sus entradas
calcular_resultados <- function(e) {
  r <- calcular_receta(e$n_masas, e$peso_masa, e$hidratacion, e$sal,
                       e$levadura, e$sobremasa)$Gramos
  temp_agua <- calcular_temp_agua(e$temp_ambiente, e$temp_harina)
  mezcla <- if (e$temp_caliente == e$temp_fria) {
    c(fria = NA_real_, caliente = NA_real_)
  } else {
    calcular_mezcla_agua(r[2], temp_agua, e$temp_fria, e$temp_caliente)
  }
  aut <- min(max(e$autolisis, 0), 100)
  list(
    harina_g = r[1], agua_g = r[2], sal_g = r[3], levadura_g = r[4],
    masa_total_g = r[5],
    agua_autolisis_g = r[2] * aut / 100, agua_amasado_g = r[2] * (100 - aut) / 100,
    temp_agua = temp_agua,
    agua_fria_g = mezcla[["fria"]], agua_caliente_g = mezcla[["caliente"]]
  )
}

es_numero <- function(x) is.numeric(x) && length(x) == 1 && is.finite(x)

# Comprueba tipos y rangos: los datos vienen del navegador o de un Excel
# subido por el usuario, así que no se dan por buenos.
receta_valida <- function(r) {
  if (!is.list(r)) return(FALSE)
  if (!is.character(r$id) || length(r$id) != 1 || !nzchar(r$id)) return(FALSE)
  if (!is.character(r$nombre) || length(r$nombre) != 1) return(FALSE)
  if (!is.character(r$fecha) || length(r$fecha) != 1) return(FALSE)
  e <- r$entradas
  if (!is.list(e)) return(FALSE)
  if (!all(vapply(CAMPOS_ENTRADA, function(k) es_numero(e[[k]]), logical(1)))) return(FALSE)
  if (!(is.character(e$tipo_levadura) && length(e$tipo_levadura) == 1 &&
        e$tipo_levadura %in% TIPOS_VALIDOS)) return(FALSE)
  if (e$n_masas < 1 || e$peso_masa <= 0 || e$horas_fermentacion <= 0) return(FALSE)
  for (k in CAMPOS_OPCIONALES) {
    if (!is.null(e[[k]]) && !(es_numero(e[[k]]) && e[[k]] %in% c(0, 1))) return(FALSE)
  }
  h <- e$harinas
  if (!is.list(h) || length(h) < 1 || length(h) > MAX_HARINAS) return(FALSE)
  all(vapply(h, function(x) {
    is.list(x) && is.character(x$nombre) && length(x$nombre) == 1 && es_numero(x$pct)
  }, logical(1)))
}

# --- JSON (localStorage) -------------------------------------------------------
historial_a_json <- function(hist) {
  as.character(jsonlite::toJSON(hist, auto_unbox = TRUE, null = "null", na = "null",
                                digits = NA))
}

json_a_historial <- function(txt) {
  hist <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) list())
  if (!is.list(hist)) return(list())
  Filter(receta_valida, unname(hist))
}

# Une dos historiales; en caso de mismo id, gana el nuevo
fusionar_historial <- function(actual, nuevo) {
  ids_nuevos <- vapply(nuevo, function(r) r$id, character(1))
  conservar <- Filter(function(r) !(r$id %in% ids_nuevos), actual)
  c(conservar, nuevo)
}

# --- Excel ---------------------------------------------------------------------
# Hojas: "Recetas" (una fila por receta: entradas y resultados) y "Harinas"
# (una fila por harina de cada receta). Al importar solo se leen las entradas.
historial_a_excel <- function(hist, path) {
  recetas <- lapply(hist, function(r) {
    e <- r$entradas
    res <- lapply(calcular_resultados(e), as.numeric)
    as.data.frame(c(list(id = r$id, nombre = r$nombre, fecha = r$fecha),
                    e[CAMPOS_ENTRADA], list(tipo_levadura = e$tipo_levadura),
                    lapply(setNames(CAMPOS_OPCIONALES, CAMPOS_OPCIONALES),
                           function(k) valor_opcional(e, k)),
                    res),
                  stringsAsFactors = FALSE)
  })
  harinas <- lapply(hist, function(r) {
    h <- r$entradas$harinas
    data.frame(id = r$id, orden = seq_along(h),
               harina = vapply(h, function(x) x$nombre, character(1)),
               pct = vapply(h, function(x) x$pct, numeric(1)),
               stringsAsFactors = FALSE)
  })
  vacio_r <- data.frame(id = character(), nombre = character(), fecha = character())
  vacio_h <- data.frame(id = character(), orden = integer(), harina = character(),
                        pct = numeric())
  writexl::write_xlsx(
    list(Recetas = if (length(recetas)) do.call(rbind, recetas) else vacio_r,
         Harinas = if (length(harinas)) do.call(rbind, harinas) else vacio_h),
    path
  )
}

excel_a_historial <- function(path) {
  rec <- readxl::read_excel(path, sheet = "Recetas", col_types = "text")
  har <- readxl::read_excel(path, sheet = "Harinas", col_types = "text")
  har$orden <- suppressWarnings(as.numeric(har$orden))
  hist <- lapply(seq_len(nrow(rec)), function(i) {
    id <- rec$id[i]
    h <- har[!is.na(har$id) & har$id == id, , drop = FALSE]
    h <- h[order(h$orden), , drop = FALSE]
    entradas <- lapply(rec[i, CAMPOS_ENTRADA], function(v) suppressWarnings(as.numeric(v)))
    entradas$tipo_levadura <- rec$tipo_levadura[i]
    for (k in intersect(CAMPOS_OPCIONALES, names(rec))) {
      v <- suppressWarnings(as.numeric(rec[[k]][i]))
      if (!is.na(v)) entradas[[k]] <- v
    }
    entradas$harinas <- lapply(seq_len(nrow(h)), function(j) {
      list(nombre = h$harina[j], pct = suppressWarnings(as.numeric(h$pct[j])))
    })
    list(id = id, nombre = substr(rec$nombre[i], 1, MAX_NOMBRE),
         fecha = rec$fecha[i], entradas = entradas)
  })
  Filter(receta_valida, hist)
}
