library(shiny)
library(bslib)


# Campos numéricos de la receta guardada -> id del input de Shiny
INPUTS_NUMERICOS <- c(
  n_masas = "n_masas", peso_masa = "peso_masa", hidratacion = "hidratacion",
  sal = "sal", levadura = "levadura", sobremasa = "sobremasa",
  autolisis = "autolisis", temp_ambiente = "temp_ambiente",
  temp_harina = "temp_harina", temp_fria = "temp_fria",
  temp_caliente = "temp_caliente", temp_fermentacion = "temp",
  horas_fermentacion = "horas"
)

# El historial vive en el localStorage del navegador de cada usuario: al conectar
# se envía al servidor (input$hist_ls) y cada cambio se guarda con "hist_save".
JS_HISTORIAL <- "
$(document).on('shiny:connected', function() {
  var v = '';
  try { v = localStorage.getItem('pizza_historial') || ''; } catch (e) {}
  Shiny.setInputValue('hist_ls', v, {priority: 'event'});
});
Shiny.addCustomMessageHandler('hist_save', function(v) {
  try { localStorage.setItem('pizza_historial', v); } catch (e) {}
});
"

# Tema "claro moderno" con modo oscuro. Los colores de la app son variables (--app-*)
# que cambian con data-bs-theme, para que el botón de modo oscuro de bslib los
# actualice todos. Las fuentes son del sistema (sin descargas), así que la app no
# depende de internet al publicarse.
tema <- bs_theme(
  version = 5,
  bg = "#F4F5F7", fg = "#16181D",
  primary = "#4F46E5",
  base_font = font_collection("Segoe UI", "system-ui", "-apple-system", "Roboto", "sans-serif"),
  "border-radius" = "0.75rem"
)
tema <- bs_add_rules(tema, "
  :root, [data-bs-theme=light] {
    --app-bg: #F4F5F7; --app-surface: #FFFFFF; --app-surface2: #F8F9FB; --app-line: #E6E8EC;
    --app-muted: #6B7280; --app-accent: #4F46E5; --app-accent-soft: #EEF0FF;
    --app-shadow: 0 1px 2px rgba(16, 24, 40, .05), 0 4px 16px rgba(16, 24, 40, .06);
  }
  [data-bs-theme=dark] {
    --app-bg: #0F1115; --app-surface: #181B21; --app-surface2: #1E222A; --app-line: #2A2F39;
    --app-muted: #9AA1AE; --app-accent: #818CF8; --app-accent-soft: #23264A;
    --app-shadow: 0 0 0 1px #232834;
    --bs-body-bg: #0F1115; --bs-body-color: #ECEEF2; --bs-border-color: #2A2F39;
  }
  body { background: var(--app-bg); }
  hr { border-color: var(--app-line); opacity: 1; }

  /* Navegación: pestaña activa en píldora */
  .navbar { background: var(--app-surface) !important; border-bottom: 1px solid var(--app-line);
    box-shadow: none; }
  .navbar-brand { font-weight: 700; font-size: 1.2rem; letter-spacing: -.2px; }
  /* Pestaña activa: negrita y color de acento (sin línea ni fondo) */
  .navbar .nav-link { border-radius: 0; padding: .5rem .9rem; color: var(--app-muted);
    border-bottom: 0 !important; box-shadow: none !important; }
  .navbar .nav-link:hover { color: var(--bs-body-color); }
  .navbar .navbar-nav .nav-link.active, .navbar .nav-link.active { background: transparent !important;
    color: var(--app-accent) !important; font-weight: 700 !important; box-shadow: none !important; }

  /* Tarjetas */
  .card { background: var(--app-surface); border: 0; border-radius: 1rem;
    box-shadow: var(--app-shadow); }
  /* bslib da a .card-header un tamaño y peso más específicos; de ahí !important */
  .card .card-header { font-size: 1.2rem !important; font-weight: 700 !important;
    letter-spacing: -.2px; color: inherit; background: transparent; border-bottom: 0;
    padding: 1.25rem 1.5rem .25rem; }
  /* Cuerpo de las tarjetas alineado con su título; las tablas lo anulan más abajo */
  .card .card-body { padding: .5rem 1.5rem 1.5rem; }
  .card h6 { font-weight: 700; font-size: 1rem; margin: 1.25rem 0 .4rem; }
  .card h6:first-child { margin-top: 0; }
  /* bslib separa los hijos del cuerpo con un gap propio que se sumaba a los márgenes */
  .texto-explicativo .card-body { font-size: .95rem; gap: 0 !important; }
  .texto-explicativo p { margin-bottom: .6rem; }
  #levadura_resultado h2 { font-weight: 700; margin: 0 0 .25rem; }
  #levadura_resultado p { margin: 0; color: var(--app-muted); }

  /* Tablas de la pestaña Método directo: mismo ancho, columnas fijas y cifras
     alineadas con su encabezado (renderTable fija text-align y width en línea, de
     ahí los !important) */
  .tablas-receta .card-body { padding: 0 0 .5rem; }
  .tablas-receta table.shiny-table { width: 100% !important; table-layout: fixed; margin: .5rem 0 0;
    --bs-table-bg: transparent; --bs-table-color: inherit; }
  /* Shiny fija su propio relleno en las celdas (table-spacing-s), de ahí !important */
  /* Encabezados de columna: mismo tamaño y color que los valores, en negrita */
  .shiny-table th { font-weight: 700; font-size: inherit; color: inherit;
    padding: .65rem 1.5rem !important; border-bottom: 1px solid var(--app-line); }
  .shiny-table td { padding: .7rem 1.5rem !important; border-top: 0;
    border-bottom: 1px solid var(--app-line); }
  .shiny-table tbody tr:last-child td { border-bottom: 0; }
  .tablas-receta .shiny-table th:first-child, .tablas-receta .shiny-table td:first-child {
    width: 45%; text-align: left !important; }
  .tablas-receta .shiny-table th:not(:first-child), .tablas-receta .shiny-table td:not(:first-child) {
    text-align: right !important; font-variant-numeric: tabular-nums; }
  /* Última fila destacada en las tablas que terminan en un total */
  .tabla-total .shiny-table tbody tr:last-child td { font-weight: 700; background: var(--app-surface2); }
  .valor-destacado { display: inline-block; padding: .1rem .65rem; border-radius: 999px;
    background: var(--app-accent-soft); color: var(--app-accent); font-weight: 600; font-size: .85rem; }
  .tablas-receta .help-block { padding: 0 1.5rem .75rem; margin: 0; }

  /* Barra lateral: tarjetas sin marco de panel */
  .bslib-sidebar-layout { --_sidebar-bg: transparent; --_border-color: transparent;
    border: 0 !important; background: transparent !important; box-shadow: none; }
  .bslib-sidebar-layout > .sidebar { background: transparent; border: 0; }
  .secciones-lateral { display: flex; flex-direction: column; gap: .75rem; }
  .secciones-lateral .accordion, .secciones-lateral .seccion-switch { margin: 0; width: 100%;
    background: var(--app-surface); border: 0; border-radius: 1rem; box-shadow: var(--app-shadow);
    overflow: hidden; }
  .sidebar .accordion { --bs-accordion-border-width: 0; --bs-accordion-bg: transparent;
    --bs-accordion-active-bg: transparent; --bs-accordion-active-color: inherit;
    --bs-accordion-btn-focus-box-shadow: none; --bs-accordion-btn-padding-x: 1.25rem;
    --bs-accordion-body-padding-x: 1.25rem; }
  .sidebar .accordion-button { font-weight: 600; box-shadow: none; }
  .seccion-switch-cab { display: flex; justify-content: space-between; align-items: center;
    gap: 1rem; padding: 1rem 1.25rem; min-height: 3.5rem; font-weight: 600; }
  /* El título ocupa el espacio libre y solo salta de línea si no cabe; el
     interruptor mantiene su tamaño y queda pegado a la derecha. Shiny da 300 px
     al contenedor del input y Bootstrap le deja un margen izquierdo de 2.5em,
     de ahí los !important. */
  .seccion-switch-titulo { flex: 1 1 auto; min-width: 0; }
  .seccion-switch .shiny-input-container { flex: 0 0 auto; width: auto !important;
    max-width: none; margin: 0 0 0 auto; }
  .seccion-switch .form-check, .seccion-switch .form-switch { padding-left: 0 !important;
    margin: 0 0 0 auto; min-height: 0; }
  .seccion-switch .form-check-input { float: none; margin: 0 !important; }
  .seccion-switch-cuerpo { padding: 1rem 1.25rem .5rem; border-top: 1px solid var(--app-line); }

  /* Campos: fondo suave, esquinas moderadas, dos por fila */
  .form-control, .form-select, .selectize-input { border-radius: .5rem;
    background-color: var(--app-surface2); border-color: var(--app-line); }
  .control-label, .shiny-input-container > label { font-size: .8rem; font-weight: 500;
    color: var(--app-muted); margin-bottom: .25rem; }
  .form-group { margin-bottom: .75rem; }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 0 .75rem; }
  .grid-2 .shiny-input-container { width: 100%; margin-bottom: .75rem; }

  /* Mezcla de harinas */
  .harinas-cab { color: var(--app-muted); font-size: .8rem; font-weight: 600; margin-bottom: .25rem; }
  .harinas-cab > div:last-child, .harina-base-pct { text-align: right; }
  .fila-harina .form-group { margin-bottom: .5rem; }
  .fila-harina input[type=number] { text-align: right; }
  .harina-base-pct { padding: .45rem .75rem; color: var(--app-muted); white-space: nowrap; }
  .harinas-acciones { display: flex; gap: 1.25rem; margin: .5rem 0; font-size: .9rem; }
  .harinas-acciones a { text-decoration: none; color: var(--app-accent); font-weight: 500; }
  .harinas-acciones a:hover { text-decoration: underline; }
  .help-block { color: var(--app-muted); }
")

# Sección de la barra lateral con interruptor en la cabecera: al activarlo se
# despliegan sus campos, sin tener que abrir nada antes. No es un acordeón porque
# un interruptor dentro del botón del acordeón no responde al clic en Firefox.
seccion_switch <- function(id, titulo, ...) {
  div(
    class = "seccion-switch",
    div(
      class = "seccion-switch-cab",
      span(class = "seccion-switch-titulo", titulo),
      input_switch(id, span(class = "visually-hidden", titulo), value = FALSE)
    ),
    conditionalPanel(paste0("input.", id), div(class = "seccion-switch-cuerpo", ...))
  )
}

ui <- page_navbar(
  title = "Calculadora de masa de pizza",
  id = "tabs",
  theme = tema,
  lang = "es",
  fillable = FALSE,
  header = tags$head(tags$script(HTML(JS_HISTORIAL))),
  footer = div(
    class = "text-center text-muted small py-3",
    "Aplicación creada por ",
    tags$a("@nico_arm", href = "https://www.instagram.com/nico_arm/",
           target = "_blank", rel = "noopener")
  ),

  nav_panel(
    "Método directo", value = "receta",
    layout_sidebar(
      fillable = FALSE,
      sidebar = sidebar(
        width = 360,
        open = list(desktop = "open", mobile = "always-above"),
        div(
          class = "secciones-lateral",
          accordion(
            id = "acc_params", open = "masa",
            accordion_panel(
              "Parámetros receta", value = "masa",
              div(class = "grid-2",
                  numericInput("n_masas", "Cantidad de masas", value = 4, min = 1, step = 1),
                  numericInput("peso_masa", "Peso unitario (g)", value = 260, min = 1, step = 10),
                  numericInput("hidratacion", "Hidratación (%)", value = 65, min = 0, step = 1),
                  numericInput("sal", "Sal (%)", value = 3, min = 0, step = 0.1),
                  numericInput("levadura", "Levadura (%)", value = 0.3, min = 0, step = 0.01),
                  numericInput("sobremasa", "Sobremasa (%)", value = 5, min = 0, step = 1))
            )
          ),
          seccion_switch(
            "usar_temp", "Temperatura del agua",
            div(class = "grid-2",
                numericInput("temp_masa", "Masa deseada (°C)", value = TEMP_MASA_DEFECTO, step = 1),
                numericInput("friccion", "Factor de fricción (°C)", value = FRICCION_DEFECTO, step = 1),
                numericInput("temp_ambiente", "Ambiente (°C)", value = 22, step = 1),
                numericInput("temp_harina", "Harina (°C)", value = 20, step = 1),
                numericInput("temp_fria", "Agua fría (°C)", value = 15, step = 1),
                numericInput("temp_caliente", "Agua caliente (°C)", value = 100, step = 1))
          ),
          seccion_switch(
            "usar_harinas", "Mezcla de harinas",
            uiOutput("harinas_ui"),
            div(class = "harinas-acciones",
                actionLink("add_harina", "+ Añadir harina"),
                actionLink("del_harina", "− Quitar última"))
          ),
          seccion_switch(
            "usar_autolisis", "Distribución del agua en etapas",
            numericInput("autolisis", "Agua en la autólisis (% del agua total)",
                         value = 90, min = 0, max = 100, step = 5)
          )
        )
      ),

      # Solo se muestran las tablas de los apartados que el usuario ha activado
      uiOutput("tablas")
    )
  ),

  nav_panel(
    "Método indirecto", value = "indirecto",
    card(card_body(class = "text-center text-muted py-5", "Próximamente"))
  ),

  nav_panel(
    "Estimación porcentaje de levadura", value = "levadura",
    layout_sidebar(
      fillable = FALSE,
      sidebar = sidebar(
        width = 360,
        open = list(desktop = "open", mobile = "always-above"),
        selectInput("tipo_levadura", "Tipo de levadura", TIPOS_LEVADURA, selectize = FALSE),
        numericInput("temp", "Temperatura de fermentación (°C)", value = 20, min = 1, max = 40, step = 1),
        helpText("~4 °C si fermenta en la nevera", style = "margin-top: -.4rem;"),
        numericInput("horas", "Horas de fermentación", value = 24, min = 1, step = 1),
        actionButton("aplicar", "Usar en la receta", class = "btn-primary")
      ),
      layout_columns(
        col_widths = 12, fill = FALSE,
        card(
          card_header("Levadura recomendada"),
          uiOutput("levadura_resultado")
        ),
        card(
          class = "texto-explicativo",
          card_header("Cómo se calcula"),
          card_body(
          h6("Fórmula"),
          p("Porcentaje de levadura instantánea sobre el peso de harina:"),
          p(tags$code(sprintf(
            "%% levadura = %s × (%g / horas) × %s^((%g − T) / 10)",
            format(REF_PCT, decimal.mark = ","), REF_HORAS,
            format(Q10, decimal.mark = ","), REF_TEMP
          ))),
          p("donde ", tags$em("horas"), " es la duración de la fermentación y ", tags$em("T"),
            " su temperatura en °C. Para otros tipos de levadura el resultado se multiplica por ",
            sprintf("%g (fresca) o %g (seca activa).",
                    FACTOR_LEVADURA[["fresca"]], FACTOR_LEVADURA[["seca_activa"]])),
          h6("Alcance del modelo"),
          p("Es un modelo empírico simplificado: las dos constantes se ajustaron por mínimos ",
            "cuadrados (en logaritmos) a unos 10 valores centrales de tablas publicadas, no a ",
            "mediciones propias. Con ellas, 24 h a 20 °C dan ",
            format(REF_PCT, decimal.mark = ","), " %. ",
            "Úsalo como punto de partida y ajústalo con tu experiencia."),
          h6("Referencias"),
          tags$ul(
            tags$li("Tablas de levadura según tiempo y temperatura (datos del ajuste): ",
                    tags$a("mypizzanight", href = "https://mypizzanight.com/guides/pizza-dough-yeast-calculator", target = "_blank", rel = "noopener"), ", ",
                    tags$a("dough.school", href = "https://www.dough.school/guides/yeast-calculator", target = "_blank", rel = "noopener"), ", ",
                    tags$a("fond.kitchen", href = "https://fond.kitchen/guides/pizza-dough/pizza-dough-fermentation/", target = "_blank", rel = "noopener"), " y ",
                    tags$a("flourwise", href = "https://flourwise.com/pizza-calculator/", target = "_blank", rel = "noopener"), "."),
            tags$li("Pizzablab, ",
                    tags$a("guía de su calculadora de masa", href = "https://www.pizzablab.com/calculators/pizza-dough-calculator-guide/", target = "_blank", rel = "noopener")),
            tags$li("TXCraig1, ",
                    tags$a("«Baker's yeast quantity prediction model»", href = "https://www.pizzamaking.com/forum/index.php?msg=271528", target = "_blank", rel = "noopener"),
                    " (pizzamaking.com, 2013)"),
            tags$li("Temperaturas cardinales de levaduras ", tags$em("Saccharomyces"), " (",
                    tags$a("PMC3067424", href = "https://pmc.ncbi.nlm.nih.gov/articles/PMC3067424", target = "_blank", rel = "noopener"),
                    ")")
          )
          )
        )
      )
    )
  ),

  nav_panel(
    "Historial de recetas", value = "historial",
    layout_sidebar(
      fillable = FALSE,
      sidebar = sidebar(
        width = 360,
        open = list(desktop = "open", mobile = "always-above"),
        textInput("hist_nombre", "Nombre de la receta", placeholder = "Ej.: Napolitana 24 h"),
        actionButton("hist_guardar", "Guardar receta actual", class = "btn-primary"),
        hr(),
        selectInput("hist_sel", "Receta guardada", choices = character(0), selectize = FALSE),
        actionButton("hist_cargar", "Cargar", class = "btn-sm btn-outline-secondary"),
        actionButton("hist_eliminar", "Eliminar", class = "btn-sm btn-outline-secondary"),
        hr(),
        downloadButton("hist_descargar", "Descargar Excel", class = "btn-sm"),
        fileInput("hist_subir", "Importar Excel", accept = ".xlsx",
                  buttonLabel = "Examinar…", placeholder = "Sin archivo")
      ),
      card(
        card_header("Recetas guardadas"),
        div(style = "overflow-x: auto;", tableOutput("hist_tabla")),
        helpText("El historial se guarda en este navegador. Descarga el Excel como copia ",
                 "de seguridad o para usarlo en otro dispositivo; luego impórtalo allí.")
      )
    )
  ),

  nav_panel(
    "Instrucciones de uso", value = "instrucciones",
    # (el botón de modo oscuro está al final de la barra, tras nav_spacer)
    div(
      class = "mx-auto", style = "max-width: 820px;",
      card(
        card_header("Instrucciones de uso"),
        h5("Qué hace la aplicación"),
        p("Calcula los gramos de harina, agua, sal y levadura de una masa de pizza a partir de ",
          "porcentajes panaderos: cada ingrediente se expresa como un porcentaje del peso total ",
          "de la harina (la harina es siempre el 100 %)."),

        h5("Método directo"),
        p("Es la pestaña principal. Rellena la sección ", span("Parámetros receta"), ":"),
        tags$ul(
          tags$li(span("Cantidad de masas"), " y ", span("peso unitario"), " de cada una, en gramos."),
          tags$li(span("Hidratación, sal y levadura"), ": porcentajes sobre la harina."),
          tags$li(span("Sobremasa"), ": porcentaje extra de masa que se prepara para ",
                  "compensar lo que se pierde en el proceso. Se suma al peso total antes de calcular.")
        ),
        p("La tabla ", span("Resumen de la receta"), " muestra los gramos de harina, agua, sal y levadura, ",
          "y el peso total de la masa a preparar (con la sobremasa incluida)."),

        h5("Apartados opcionales"),
        p("Cada uno tiene un interruptor. Al activarlo se despliegan sus campos y aparece su tabla ",
          "de resultados; mientras esté apagado no se muestra nada."),
        tags$ul(
          tags$li(span("Temperatura del agua"), ": indica la temperatura que quieres para la masa, el factor ",
                  "de fricción, la temperatura ambiente, la de la harina y las temperaturas del agua fría y ",
                  "caliente que tienes. La app calcula la temperatura a la que debe estar el agua y cuántos ",
                  "gramos de agua fría y caliente mezclar para alcanzarla (ver «Cálculo de las temperaturas»)."),
          tags$li(span("Mezcla de harinas"), ": escribe el nombre de cada harina y su porcentaje. La primera ",
                  "(base) no se edita: es el resto hasta 100 %. Por ejemplo, con 2 % de integral y 10 % de ",
                  "otra más fuerte, la base queda en 88 %. Puedes usar hasta 6 harinas."),
          tags$li(span("Distribución del agua en etapas"), ": indica qué porcentaje del agua va a la ",
                  "autólisis (harina y agua en reposo antes de amasar). El resto se añade en el amasado.")
        ),

        h5("Cálculo de las temperaturas"),
        p("Temperatura del agua. Se usa el método de la temperatura deseada de la masa (",
          tags$em("desired dough temperature"), "):"),
        p(tags$code("T agua = (T masa deseada × 3) − (T ambiente + T harina + factor de fricción)")),
        p("El 3 se debe a que se promedian tres temperaturas: agua, harina y ambiente. El factor de ",
          "fricción es el calor que el amasado añade a la masa, así que depende de la amasadora y del ",
          "tiempo de amasado. Como orientación, King Arthur Baking da unos 22–24 °F (12–13 °C) para ",
          "una amasadora de pie durante unos 7 minutos y unos 6–8 °F (3–4 °C) para amasar a mano durante ",
          "unos 8 minutos. Por defecto la app usa 24 °C de masa y 12 °C de fricción, que equivale a ",
          "60 − T ambiente − T harina. Es una aproximación: no tiene en cuenta todas las variables, ",
          "así que ajusta el factor de fricción midiendo la temperatura real de tu masa."),
        p("Mezcla de agua fría y caliente. Sale de un balance de calor: el calor que cede el agua caliente ",
          "es el que gana la fría, si no hay pérdidas hacia el entorno. Como las dos son agua, el ",
          "calor específico se cancela y la temperatura final es el promedio ponderado por la masa:"),
        p(tags$code("T final = (m fría × T fría + m caliente × T caliente) / (m fría + m caliente)")),
        p("La app despeja de ahí los gramos de agua caliente y fría para llegar a la temperatura calculada. ",
          "En la práctica el recipiente y el ambiente absorben algo de calor, y la temperatura del agua ",
          "del grifo cambia, así que conviene comprobarla con un termómetro."),
        p("Referencias:"),
        tags$ul(
          tags$li(tags$a("King Arthur Baking, «Desired dough temperature»", href = "https://www.kingarthurbaking.com/blog/2018/05/29/desired-dough-temperature", target = "_blank", rel = "noopener")),
          tags$li(tags$a("Pizza Today, «Temperature Control»", href = "https://pizzatoday.com/news/temperature-control/130721/", target = "_blank", rel = "noopener")),
          tags$li(tags$a("Pizza Today, «Dough Doctor: Get Wet»", href = "https://pizzatoday.com/?p=130903", target = "_blank", rel = "noopener")),
          tags$li(tags$a("Pearson, «Calorimetry»", href = "https://pearson.com/channels/physics/learn/patrick/heat-temperature-and-kinetic-theory-of-gasses/calorimetry", target = "_blank", rel = "noopener")),
          tags$li(tags$a("Physics Forums, «Formula: final temperature when mixing water with water»", href = "https://www.physicsforums.com/threads/135713", target = "_blank", rel = "noopener"))
        ),

        h5("Estimación porcentaje de levadura"),
        p("Elige el tipo de levadura, la temperatura y las horas de fermentación (en la nevera, unos 4 °C). ",
          "La app estima el porcentaje de levadura y los gramos para tu receta. Con ",
          span("Usar en la receta"), " ese porcentaje pasa al Método directo. La fórmula y las ",
          "referencias están en esa misma pestaña; es una estimación aproximada, úsala como punto de partida."),

        h5("Historial de recetas"),
        tags$ul(
          tags$li("Escribe un nombre y pulsa ", span("Guardar receta actual"), ". Se guardan todos los ",
                  "parámetros, incluidos los apartados opcionales que tengas activados."),
          tags$li("Elige una receta guardada y pulsa ", span("Cargar"), " para recuperarla o ",
                  span("Eliminar"), " para borrarla."),
          tags$li("El historial se guarda en tu navegador, y solo tú lo ves. Si borras los datos del ",
                  "navegador, se pierde. Usa ", span("Descargar Excel"), " como copia de seguridad o para ",
                  "llevar tus recetas a otro dispositivo, y ", span("Importar Excel"), " para recuperarlas.")
        ),

        h5("Método indirecto"),
        p("Próximamente.")
      )
    )
  ),

  nav_spacer(),
  nav_item(input_dark_mode(id = "modo_oscuro"))
)

server <- function(input, output, session) {
  output$receta <- renderTable({
    req(input$n_masas, input$peso_masa, input$hidratacion, input$sal, input$levadura, input$sobremasa)
    res <- calcular_receta(input$n_masas, input$peso_masa,
                           input$hidratacion, input$sal, input$levadura,
                           input$sobremasa)
    res$Gramos <- sprintf("%.1f g", res$Gramos)
    res
  })

  # Tablas visibles: Resumen de la receta siempre; el resto según lo que el usuario activó.
  # Solo depende de los interruptores, no de los valores.
  output$tablas <- renderUI({
    # Las tablas que terminan en una fila de total van en un div "tabla-total"
    # para destacar esa última fila
    tarjetas <- list(card(card_header("Resumen de la receta"),
                          div(class = "tabla-total", tableOutput("receta"))))
    if (isTRUE(input$usar_harinas)) {
      tarjetas <- c(tarjetas, list(card(card_header("Mezcla de harinas"),
                                        div(class = "tabla-total", tableOutput("harinas_tabla")),
                                        uiOutput("harinas_aviso"))))
    }
    if (isTRUE(input$usar_autolisis)) {
      tarjetas <- c(tarjetas, list(card(card_header("Agua por etapas"),
                                        div(class = "tabla-total", tableOutput("agua_etapas")))))
    }
    if (isTRUE(input$usar_temp)) {
      tarjetas <- c(tarjetas, list(card(card_header("Temperatura del agua"),
                                        tableOutput("mezcla_agua"), uiOutput("mezcla_aviso"))))
    }
    do.call(layout_columns, c(
      list(class = "tablas-receta", fill = FALSE, col_widths = breakpoints(sm = 12, lg = 6)),
      tarjetas
    ))
  })

  # --- Mezcla de harinas: nombre y porcentaje editables, 1 a MAX_HARINAS filas
  harinas_n <- reactiveVal(1)
  # Harinas de una receta cargada del historial (con un nonce para que cargar la
  # misma receta dos veces vuelva a pintar las filas)
  harinas_carga <- reactiveVal(NULL)
  observeEvent(input$add_harina, {
    harinas_carga(NULL)
    harinas_n(min(harinas_n() + 1, MAX_HARINAS))
  })
  observeEvent(input$del_harina, {
    harinas_carga(NULL)
    harinas_n(max(harinas_n() - 1, 1))
  })

  output$harinas_ui <- renderUI({
    carga <- harinas_carga()$datos
    # Se conservan los valores ya escritos al añadir o quitar filas
    previo <- function(id, defecto, i, campo) {
      if (!is.null(carga) && i <= length(carga)) return(carga[[i]][[campo]])
      v <- isolate(input[[id]])
      if (is.null(v)) defecto else v
    }
    filas <- lapply(seq_len(harinas_n()), function(i) {
      nombre <- textInput(paste0("harina_nombre_", i), NULL,
                          value = previo(paste0("harina_nombre_", i),
                                         if (i == 1) "Harina base" else "", i, "nombre"),
                          placeholder = "Tipo de harina")
      # La primera fila (base) no se edita: es 100 - suma de las demás
      pct <- if (i == 1) {
        div(class = "harina-base-pct", textOutput("harina_base_pct", inline = TRUE))
      } else {
        numericInput(paste0("harina_pct_", i), NULL,
                     value = previo(paste0("harina_pct_", i), 0, i, "pct"),
                     min = 0, max = 100, step = 1)
      }
      fluidRow(class = "fila-harina", column(7, nombre), column(5, pct))
    })
    cabecera <- fluidRow(class = "harinas-cab", column(7, "Harina"), column(5, "%"))
    tagList(cabecera, filas)
  })

  harinas <- reactive({
    n <- harinas_n()
    nombres <- vapply(seq_len(n), function(i) {
      v <- input[[paste0("harina_nombre_", i)]]
      if (is.null(v) || !nzchar(trimws(v))) paste("Harina", i) else trimws(v)
    }, character(1))
    # Las harinas adicionales (filas 2..n) se escriben; la base es el resto hasta 100 %
    extras <- vapply(seq_len(n)[-1], function(i) {
      v <- input[[paste0("harina_pct_", i)]]
      if (is.null(v) || is.na(v)) 0 else v
    }, numeric(1))
    data.frame(Harina = nombres, pct = c(100 - sum(extras), extras))
  })

  output$harina_base_pct <- renderText(sprintf("%.1f %%", harinas()$pct[1]))

  output$harinas_tabla <- renderTable({
    req(input$n_masas, input$peso_masa, input$hidratacion, input$sal, input$levadura, input$sobremasa)
    h <- harinas()
    total <- calcular_receta(input$n_masas, input$peso_masa, input$hidratacion,
                             input$sal, input$levadura, input$sobremasa)$Gramos[1]
    data.frame(Harina = c(h$Harina, "Total"),
               `%` = sprintf("%.1f %%", c(h$pct, sum(h$pct))),
               Gramos = sprintf("%.1f g", c(total * h$pct / 100, total * sum(h$pct) / 100)),
               check.names = FALSE)
  })

  output$harinas_aviso <- renderUI({
    base <- harinas()$pct[1]
    if (base < 0) {
      helpText(sprintf("Las harinas adicionales suman %.1f %%; no pueden superar el 100 %%.",
                       100 - base))
    }
  })

  output$agua_etapas <- renderTable({
    req(input$n_masas, input$peso_masa, input$hidratacion, input$sal, input$levadura,
        input$sobremasa, input$autolisis)
    pct <- min(max(input$autolisis, 0), 100)
    agua <- calcular_receta(input$n_masas, input$peso_masa, input$hidratacion,
                            input$sal, input$levadura, input$sobremasa)$Gramos[2]
    data.frame(
      Etapa = c("Autólisis", "Amasado", "Total"),
      `%` = sprintf("%.1f %%", c(pct, 100 - pct, 100)),
      Gramos = sprintf("%.1f g", c(agua * pct / 100, agua * (100 - pct) / 100, agua)),
      check.names = FALSE
    )
  })

  mezcla <- reactive({
    req(input$n_masas, input$peso_masa, input$hidratacion, input$sal, input$levadura,
        input$sobremasa, input$temp_ambiente, input$temp_harina,
        input$temp_fria, input$temp_caliente, input$temp_masa, input$friccion)
    req(input$temp_caliente > input$temp_fria)
    total <- calcular_receta(input$n_masas, input$peso_masa, input$hidratacion,
                             input$sal, input$levadura, input$sobremasa)$Gramos[2]
    final <- calcular_temp_agua(input$temp_ambiente, input$temp_harina,
                                input$temp_masa, input$friccion)
    list(total = total, final = final,
         m = calcular_mezcla_agua(total, final, input$temp_fria, input$temp_caliente))
  })

  output$mezcla_agua <- renderTable({
    x <- mezcla()
    data.frame(
      Concepto = c("Temperatura del agua", "Agua total", "Agua fría", "Agua caliente"),
      # La temperatura va en una etiqueta destacada (HTML generado aquí, no del usuario)
      Valor = c(sprintf("<span class='valor-destacado'>%.1f °C</span>", x$final),
                sprintf("%.1f g", x$total),
                sprintf("%.1f g (a %g °C)", x$m[["fria"]], input$temp_fria),
                sprintf("%.1f g (a %g °C)", x$m[["caliente"]], input$temp_caliente))
    )
  }, sanitize.text.function = function(x) x)

  output$mezcla_aviso <- renderUI({
    x <- mezcla()
    if (x$final < input$temp_fria || x$final > input$temp_caliente) {
      helpText("La temperatura final queda fuera del rango entre el agua fría y la caliente; ",
               "no se puede alcanzar con esa mezcla (las cantidades salen negativas).")
    }
  })

  levadura_pct <- reactive({
    req(input$horas > 0, input$temp)
    calcular_levadura_pct(input$horas, input$temp, input$tipo_levadura)
  })

  output$levadura_resultado <- renderUI({
    pct <- levadura_pct()
    req(input$n_masas, input$peso_masa, input$hidratacion, input$sal, input$sobremasa)
    gramos <- calcular_receta(input$n_masas, input$peso_masa, input$hidratacion,
                              input$sal, pct, input$sobremasa)$Gramos[4]
    tagList(
      h2(sprintf("%.3f %%", pct)),
      p(sprintf("≈ %.2f g de levadura para la receta actual (%d masas de %g g).",
                gramos, as.integer(input$n_masas), input$peso_masa))
    )
  })

  observeEvent(input$aplicar, {
    updateNumericInput(session, "levadura", value = signif(levadura_pct(), 3))
    updateTabsetPanel(session, "tabs", selected = "receta")
  })

  # --- Historial de recetas ---------------------------------------------------
  historial <- reactiveVal(list())

  # Carga inicial desde el navegador (una sola vez por sesión)
  observeEvent(input$hist_ls, {
    txt <- input$hist_ls
    if (is.character(txt) && length(txt) == 1 && nzchar(txt)) {
      historial(json_a_historial(txt))
    }
  }, once = TRUE)

  # Cada cambio se guarda en el navegador y refresca la lista desplegable
  observeEvent(historial(), {
    session$sendCustomMessage("hist_save", historial_a_json(historial()))
    h <- rev(historial())
    ids <- vapply(h, function(r) r$id, character(1))
    etiquetas <- vapply(h, function(r) paste0(r$nombre, " (", r$fecha, ")"), character(1))
    updateSelectInput(session, "hist_sel", choices = setNames(ids, etiquetas))
  }, ignoreInit = TRUE)

  entradas_actuales <- function() {
    h <- harinas()
    list(
      n_masas = input$n_masas, peso_masa = input$peso_masa,
      hidratacion = input$hidratacion, sal = input$sal, levadura = input$levadura,
      sobremasa = input$sobremasa, autolisis = input$autolisis,
      temp_ambiente = input$temp_ambiente, temp_harina = input$temp_harina,
      temp_fria = input$temp_fria, temp_caliente = input$temp_caliente,
      temp_masa = input$temp_masa, friccion = input$friccion,
      temp_fermentacion = input$temp, horas_fermentacion = input$horas,
      tipo_levadura = input$tipo_levadura,
      usar_temp = as.numeric(isTRUE(input$usar_temp)),
      usar_autolisis = as.numeric(isTRUE(input$usar_autolisis)),
      usar_harinas = as.numeric(isTRUE(input$usar_harinas)),
      harinas = lapply(seq_len(nrow(h)), function(i) list(nombre = h$Harina[i], pct = h$pct[i]))
    )
  }

  observeEvent(input$hist_guardar, {
    nombre <- trimws(input$hist_nombre)
    if (!nzchar(nombre)) nombre <- paste("Receta", format(Sys.time(), "%d/%m %H:%M"))
    rec <- list(id = nuevo_id(), nombre = substr(nombre, 1, MAX_NOMBRE),
                fecha = format(Sys.time(), "%Y-%m-%d %H:%M"),
                entradas = entradas_actuales())
    if (!receta_valida(rec) || harinas()$pct[1] < 0) {
      showNotification("Revisa los parámetros: hay valores vacíos o no válidos.", type = "error")
      return()
    }
    historial(c(historial(), list(rec)))
    showNotification("Receta guardada.", type = "message")
  })

  observeEvent(input$hist_cargar, {
    sel <- Filter(function(r) identical(r$id, input$hist_sel), historial())
    req(length(sel) == 1)
    e <- sel[[1]]$entradas
    for (campo in names(INPUTS_NUMERICOS)) {
      updateNumericInput(session, INPUTS_NUMERICOS[[campo]], value = e[[campo]])
    }
    for (k in names(CAMPOS_NUMERICOS_OPCIONALES)) {
      updateNumericInput(session, k, value = numero_opcional(e, k))
    }
    updateSelectInput(session, "tipo_levadura", selected = e$tipo_levadura)
    # Recetas guardadas antes de existir los interruptores: se muestran activados
    for (k in CAMPOS_OPCIONALES) {
      update_switch(k, value = valor_opcional(e, k) == 1, session = session)
    }
    harinas_carga(list(datos = e$harinas, nonce = runif(1)))
    harinas_n(length(e$harinas))
    updateTabsetPanel(session, "tabs", selected = "receta")
  })

  observeEvent(input$hist_eliminar, {
    req(input$hist_sel)
    historial(Filter(function(r) !identical(r$id, input$hist_sel), historial()))
  })

  output$hist_tabla <- renderTable({
    h <- rev(historial())
    req(length(h) > 0)
    filas <- lapply(h, function(r) {
      e <- r$entradas
      res <- calcular_resultados(e)
      data.frame(
        Nombre = r$nombre, Fecha = r$fecha,
        Masas = sprintf("%g × %g g", e$n_masas, e$peso_masa),
        `Hidratación` = sprintf("%g %%", e$hidratacion),
        Harina = sprintf("%.0f g", res$harina_g), Agua = sprintf("%.0f g", res$agua_g),
        Sal = sprintf("%.1f g", res$sal_g), Levadura = sprintf("%.2f g", res$levadura_g),
        check.names = FALSE
      )
    })
    do.call(rbind, filas)
  })

  output$hist_descargar <- downloadHandler(
    filename = function() paste0("historial_pizzas_", format(Sys.Date()), ".xlsx"),
    content = function(file) historial_a_excel(historial(), file)
  )

  observeEvent(input$hist_subir, {
    nuevo <- tryCatch(excel_a_historial(input$hist_subir$datapath), error = function(e) NULL)
    if (is.null(nuevo)) {
      showNotification("No se pudo leer el archivo. ¿Es un Excel descargado desde esta app?",
                       type = "error")
    } else {
      historial(fusionar_historial(historial(), nuevo))
      showNotification(sprintf("Se importaron %d receta(s).", length(nuevo)), type = "message")
    }
  })
}

shinyApp(ui, server)
