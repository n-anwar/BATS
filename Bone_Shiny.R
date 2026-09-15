# Draft for impact of training on bone damage (Shiny app)
#Include starting race distance, target race distance, racing frequency

library(shiny)
library(ggplot2)
library(JuliaCall)
library(patchwork)
library(DT)

# Setup Julia
julia_setup()
#main Julia script. Uses all default model and training program
julia_command('include("RShiny_julia_scripts.jl")')

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
    body { font-size: 18px; }
    .control-label { font-size: 18px; font-weight: 600; }
    .nav-tabs > li > a { font-size: 18px; }
    h5{font-size: 18px; }
    h4{font-size: 18px; }
    input.form-control {font-size: 18px;}
  "))
  ),
  
  titlePanel("Impact of training on bone damage"),
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        tabPanel("Program duration",
                 br(),
                 # wellPanel(
                 selectInput(
                   inputId = "time_unit",
                   label = "Choose time unit:",
                   choices = c("Day", "Week"),
                   selected = "Day"
                 ),
                 # ),
                 h5("Enter the duration of each program: ",textOutput("show_time_unit",inline=TRUE)),
                 wellPanel(
                 # hr(),
                 numericInput("rest_dur", tags$span("Rest duration", style = "color:#33b5ff;"), value = 44, min = 0, step = 1),
                 numericInput("pre_dur", tags$span("Pre-training  duration", style = "color:#8acfbc;"), value = 28, min = 0, step = 1),
                 numericInput("prog_dur", tags$span("Progressive training duration", style = "color:#efc958;"), value = 66, min = 0, step = 1),
                 numericInput("race_dur", tags$span("Race-fit training duration", style = "color:#ef82bd;"), value = 56, min = 0, step = 1),
                 )
                 
        ),
        tabPanel("Program speed",
                 br(),
                 # h4("Rest"),
                 # wellPanel(
                   selectInput(
                     inputId = "spd_unit",
                     label = "Choose speed unit:",
                     choices = c("meters per second (m/s)", "seconds per furlong (s/f)"),
                     selected = "m/s"
                   ),
                 # ),
                 h5("Enter the speed during each program: ",textOutput("show_spd_unit",inline=TRUE)),
                 # wellPanel(
                   # style = "background-color: #33b5ff; border: 2px solid #666;",
                   numericInput("rest_spd", tags$span("Speed during rest", style = "color:#33b5ff;"), value = 3.6, min = 0, step = 1),
                 # ),
                 # hr(),
                 # wellPanel(
                   numericInput("pre_spd", tags$span("Speed during pre-training", style = "color:#8acfbc;"), value = 7.5, min = 0, step = 1),
                   # h4("Progresive"),
                 # ),
                 # hr(),
                 wellPanel(
                   numericInput("slw_prog_spd_strt", 
                                tagList(
                                  tags$span("Speed during progressive training",
                                            tags$br(),
                                            "(at the start of slow phase)", style = "color:#efc958;")), value = 11.8, min = 0, step = 1),
                   numericInput("slw_prog_spd_end", 
                                tagList(
                                  tags$span("Speed during progressive training",
                                            tags$br(),
                                            "(at the end of slow phase)", style = "color:#efc958;")), value = 13.8, min = 0, step = 1),
                   numericInput("fst_prog_spd_strt", 
                                tagList(
                                  tags$span("Speed during progressive training",
                                            tags$br(),
                                            "(at the start of fast phase)", style = "color:#efc958;")), value = 13.8, min = 0, step = 1),
                   numericInput("fst_prog_spd_end", 
                                tagList(
                                  tags$span("Speed during progressive training",
                                            tags$br(),
                                            "(at the end of fast phase)", style = "color:#efc958;")), value = 16, min = 0, step = 1),
                 ),
                 # hr(),
                 wellPanel(
                   numericInput("rce_spd1", tags$span("Speed during race-fit trainig (Even time)", style = "color:#ef82bd;"), value = 13.8, min = 0, step = 1),
                   numericInput("rce_spd2", tags$span("Speed during race-fit trainig (fast gallop)", style = "color:#ef82bd;"), value = 16, min = 0, step = 1),
                   numericInput("rce_spd3", tags$span("Race speed", style = "color:#ef82bd;"), value = 16.7, min = 0, step = 1),
                 ),
                 # hr(),
                 # wellPanel(
                   numericInput("slow_work_spd", tags$span("Speed during slow workout", style = "color:#6a329f;"), value = 7.5, min = 0, step = 1),
                 # )
                 # hr(),
                 # checkboxInput("verbose", "Show details", value = TRUE)
        ),
        tabPanel("Program volume",
                 br(),
                 h5("Enter the distances (in meters) of each program"),
                 
                 # wellPanel(
                 # h4("Rest",style = "color:#33b5ff; font-weight:bold;"),
                 numericInput("rest_dist", tags$span("Distance per day during rest", style = "color:#33b5ff;"), value = 4000, min = 0, step = 100),
                 # h4("Pre-training"),
                 # ),
                 # wellPanel(
                 numericInput("pre_dist", tags$span("Distance per day during pre-training", style = "color:#8acfbc;"), value = 2000, min = 0, step = 100),
                 # hr(),
                 # ),
                 wellPanel(
                 numericInput("slw_prog_dist_strt", 
                              tagList(
                                tags$span("Distance per day during progressive training",
                                          tags$br(),
                                          "(at the start of slow phase)", style = "color:#efc958;")), value = 129, min = 0, step = 50),
                 numericInput("slw_prog_dist_end", 
                              tagList(
                                tags$span("Distance per day during progressive training",
                                          tags$br(),
                                          "(at the end of slow phase)", style = "color:#efc958;")), value = 257, min = 0, step = 50),
                 numericInput("fst_prog_dist1", tags$span("Total distance (in fast phase) at speed ", style = "color:#6a329f;"), value = 6600, min = 0, step = 200),
                 numericInput("fst_prog_dist2", tags$span("Total distance (in fast phase) at speed ", style = "color:#6a329f;"), value = 3200, min = 0, step = 200),
                 
                 ),
                 # # Will incorporate later
                 wellPanel(
                   numericInput("rce_dist1", tags$span("Distance per day at speed ", style = "color:#ef82bd;"), value = 160, min = 0, step = 10),
                   numericInput("rce_dist2", tags$span("Distance per day at speed ", style = "color:#ef82bd;"), value = 107, min = 0, step = 10),
                   numericInput("rce_dist3", tags$span("Target race distance (fortnightly) at speed ", style = "color:#ef82bd;"), value = 1600, min = 0, step = 200),
                 ),
                 
                 
                 # hr(),
                 # h4("Race-fit",style = "color:#ebc775; font-weight:bold;"),
                 # wellPanel(
                 numericInput("slow_work_dist_pr_day", tags$span("Distance during slow workout", style = "color:#6a329f;"), value = 2000, min = 0, step = 100),
                 # h4("Slow workout",style = "color:#33b5ff; font-weight:bold;"),
                 # numericInput("slow_work_dist_pr_day", tags$span("Distance per day  (meter) during slow workout", style = "color:#6a329f;"), value = 2000, min = 0, step = 100),
                 # ),
              
                 br(),br(),
                 # selectInput("choice", "Include freshen-up (during race-fit training)?",
                 #             choices = c("No", "4 weeks", "2 weeks"),
                 #             selected = "No"),
                 
        ),
        
      ),
      br(),
      h4("Total number of preparations"),
      sliderInput("n_seasons", "", min = 1, max = 5, value = 4, step = 1, round = TRUE),
      # tabsetPanel()
      # h4("Program duration (week)"),
      # numericInput("rest_dur", "Rest", value = 6, min = 0, step = 1),
      # numericInput("pre_dur", "Pretraining", value = 4, min = 0, step = 1),
      # numericInput("prog_dur", "Progressive", value = 9, min = 0, step = 1),
      # numericInput("race_dur", "Race-fit", value = 7, min = 0, step = 1),
      br(),
      # checkboxInput("back_off", "Include freshen-up?", value = FALSE),
      actionButton("run_btn", "Run model", class = "btn-primary"),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        
        
        tabPanel("Result: Bone dynamics over time",
                 br(), br(),
                 plotOutput("ts_plot", height = "550px")
                 # downloadButton("download_plot", "Download plot")
        ),
        
        tabPanel("Result: Damage summary",
                 br(),
                 plotOutput("summary_plot", height = "650px")
        ),
        tabPanel("Table",
                 br(),
                 dataTableOutput("df_table")
        ),
        tabPanel("Model info",
                 br(),
                 # verbatimTextOutput("model_info") #for plain text
                 tags$img(src = "training_program_durations2.png", width = "80%"),
                 withMathJax(
                   HTML(
                     paste0(
                       "<p> <b>Figure</b>: Schematic of a typical training program in Victoria, Australia. Speeds (\\(s_i\\)) are expressed in
\\(ms^{-1}\\) and corresponding distances (\\(d_i\\)) are expressed in \\(m/week\\). For a typical training program, the durations of each phase
(in weeks) are \\(T_{rest} = 6\\), \\(T_{pre-train} = 4\\), \\(T_{slow} = 3.6\\), \\(T_{fast} = 5.4\\), \\(T_{prog} = T_{slow}+T_{fast} = 9\\) and \\(T_{race} = 8\\).</p>",
                       br(),br(),
                       "<p> We divide the preparation into four periods (durations, distances and speeds bellow are for a typical training preperation): </p>",
                       
                       "<p> <b>1. <span style='color:#33b5ff;'>Rest program:</span></b> Horses in rest in an Australian training environment and in the absence of injury are typically turned out in a paddock with voluntary
            exercise including trotting for a distance of 4000 m every day, at a speed of 3.6 m/s.</p>",
                       
                       "<p>  <b>2. <span style='color:#8acfbc;'>Pre-training program:</span></b> The pre-training period consists of 2000 m/day at canter (7.5 m/s).</p>", 
                       
                       "<p> <b>3. <span style='color:#efc958;'>Progressive training program:</span></b> Progressive training is divided into a slow phase and a fast phase. The slow phase consists of slower gallops of 11.8 m/s,
            linearly increasing to 13.8 m/s by the end of the show phase (assuming 40% of the progressive duration). The galloping distance is also increased over this period, starting from 900 m/week before building up to 1800 m/week by the end of the slow phase. 
            During the fast phase, racehorses cover a total distance of approximately 6600 m at 13.8 m/s and 3200 m at 16.0 m/s. Over the 38 days (default) of the fast phase, this results in an average
            gallop distance of 1805 m/week, which is assumed to be constant throughout the fast phase. Horses begin the fast phase galloping at 13.8 m/s, with the distance gradually replaced with the
            higher speed of 16.0 m/s. Assuming the distance per day at 16.0 m/s is linearly increased over this phase, horses cover 1179 m/week at 16.0 m/s by the end of progressive training.</p>",
                       
                       "<p><b>4. <span style='color:#ef82bd;'>Race-fit training program:</span></b> Horses
            in race-fit training cover a total of 4800 m at 13.8 m/s and 3200m at 16.0 m/s per month (red box), consistent with a medium-volume training program. Weekly workloads are
            divided by seven to equate to an average daily workload. In addition, we model participation in an average race length of 1600 m every two weeks, at an average speed of 16.7 m/s (dark
            red box).</p>",
                       "<p><b>4. <span style='color:#6a329f;'>Slow workout:</span></b> Throughout both progressive and race-fit training, horses undergo
constant ‘slow workouts’ amounting to 2000 m per day at a cantering speed of 7.5 m/s (purple box).</p>",
                       
                       "<p>The details of the mathematical model used to generate these results can be found in the following paper:</p>",
                       "<p><a href='https://doi.org/10.1007/s10237-017-0998-z' target='_blank'>",
                       "1. Hitchens, P. L., Pivonka, P., Malekipour, F., & Whitton, R. C. (2018). Mathematical modelling of bone adaptation of the metacarpal subchondral bone in racehorses. Biomechanics and Modeling in Mechanobiology, 17(3), 877-890.",
                       "</a></p>",
                       "<p><a href='https://doi.org/10.1098/rsif.2025.0297' target='_blank'>",
                       "2. Pan, M., Malekipour, F., Pivonka, P., Morrice-West, A. V., Flegg, J. A., Whitton, R. C., & Hitchens, P. L. (2025). A mathematical model of metacarpal subchondral bone adaptation, microdamage and repair in racehorses. Journal of the Royal Society Interface, 22(231), 20250297.",
                       "</a></p>",
                       "<p><a href='https://doi.org/10.48550/arXiv.2603.22680' target='_blank'>",
                       "3. Anwar, M. N., Pan, M., Morrice-West, A. V., Malekipour, F., Pivonka, P., Flegg, J. A., ... & Hitchens, P. L. (2026). Balancing training load, rest and musculoskeletal injury risk: a mathematical modelling study in Thoroughbred racehorses. arXiv:2603.22680.",
                       "</a></p>"
                     )
                   )
                 ),
                 # tags$iframe(style="height:600px; width:100%", src="training_program_durations2.pdf"),
                 uiOutput("model_info")# text with url
        ),
      )
    )
  )
)

server <- function(input, output, session) {
  ####Update labels in Distance tab when speeds change
  output$show_time_unit <- renderText({paste0("(in ", input$time_unit,"s)")
  })
  output$show_spd_unit <- renderText({paste0("(in ", input$spd_unit,")")
  })
  observeEvent(input$time_unit, {
    
    if (input$time_unit == "Day") {
      
      updateNumericInput(session, "rest_dur", value = 44)
      updateNumericInput(session, "pre_dur",  value = 28)
      updateNumericInput(session, "prog_dur", value = 66)
      updateNumericInput(session, "race_dur", value = 56)
      
    } else {
      
      updateNumericInput(session, "rest_dur", value = round(44/7, digits = 1))
      updateNumericInput(session, "pre_dur",  value = round(28/7, digits = 1))
      updateNumericInput(session, "prog_dur", value = round(66/7, digits = 1))
      updateNumericInput(session, "race_dur", value = round(56/7, digits = 1))
      
    }
    
  })
  observe({
    updateNumericInput(session, "fst_prog_dist1",
                       label = tags$span(paste0("Total distance (in fast phase) at speed ", input$fst_prog_spd_strt," m/s"), style = "color:#efc958;"))
    updateNumericInput(session, "fst_prog_dist2",
                       label = tags$span(paste0("Total distance (in fast phase) at speed ", input$fst_prog_spd_end," m/s"), style = "color:#efc958;"))
    updateNumericInput(session, "rce_dist1",
                       label = tags$span(paste0("Distance per day at speed ", input$rce_spd1," m/s"), style = "color:#ef82bd;"))
    updateNumericInput(session, "rce_dist2",
                       label = tags$span(paste0("Distance per day at speed ", input$rce_spd2," m/s"), style = "color:#ef82bd;"))
    updateNumericInput(session, "rce_dist3",
                       label = tags$span(paste0("Target race distance (fortnightly) at speed ", input$rce_spd3," m/s"), style = "color:#ef82bd;"))
  })

  sim <- eventReactive(input$run_btn, {
    # Call the main function "Trainig_model_R()" that collect the user provided data,
    #construct the training program, and return the necessary results back to R.
    
    prog_duration<-c(input$rest_dur,
                     input$pre_dur,
                     input$prog_dur, 
                     input$race_dur)
    
    if (input$time_unit=="Week"){
      prog_duration_f<-prog_duration*7
    }else if(input$time_unit=="Day"){
      prog_duration_f<-prog_duration
    }
      
    prog_volume<-c(input$rest_dist, 
                   input$pre_dist,
                   input$slw_prog_dist_strt,
                   input$slw_prog_dist_end,
                   input$fst_prog_dist1,
                   input$fst_prog_dist2,
                   input$rce_dist1,
                   input$rce_dist2,
                   input$rce_dist3/14,
                   
                   input$slow_work_dist_pr_day
                   )
    

    prog_speed<-c(input$rest_spd, 
                  input$pre_spd,
                  input$slw_prog_spd_strt,
                  input$slw_prog_spd_end,
                  input$fst_prog_spd_strt,
                  input$fst_prog_spd_end,
                  input$rce_spd1,
                  input$rce_spd2,
                  input$rce_spd3,
                  input$slow_work_spd
                  )
    
    if (input$spd_unit=="seconds per furlong (s/f)"){
      prog_speed<-201.17/prog_speed
    }
    
    # result <- julia_call("Trainig_model_R",
    #                      # as.numeric(input$rest_dur), as.numeric(input$pre_dur),
    #                      # as.numeric(input$prog_dur), as.numeric(input$race_dur), as.integer(input$n_seasons))
    #                        # input$rest_dur, input$pre_dur,
    #                         # input$prog_dur, input$race_dur, input$n_seasons)
    #                      prog_duration,prog_volume, prog_speed, input$n_seasons)

    result <- withProgress(message = "Running Julia model...", value = 0, {
      
      incProgress(0.2, detail = "Initializing Julia...")
      Sys.sleep(0.1)  # optional delay to visualize progress
      
      incProgress(0.5, detail = "Calculating training program...")
      julia_result <- julia_call("Trainig_model_R",
                                 prog_duration_f, prog_volume, prog_speed, input$n_seasons)
      
      incProgress(0.3, detail = "Finalizing results...")
      Sys.sleep(0.1)
      
      julia_result
    })
    
    # # Julia's Named tuple becomes a list in R
    list(
      sols_R = result$sols_R,
      df_changes = result$df_changes,
      sols_R_ave = result$sols_R_ave
    )
  }, ignoreNULL = FALSE)
  
  output$ts_plot <- renderPlot({
    result_sol <- sim()[["sols_R"]]
    result_sol_ave <- sim()[["sols_R_ave"]]
    result_df <- sim()[["df_changes"]]
    
    result_sol$program_type <- "Your current program"
    result_sol_ave$program_type <- "Average program in Victoria"
    df_lines <- rbind(result_sol, result_sol_ave)
    
    max_dmg<-max(result_sol$dmg)
    # Define axis limits
    ylim_left <- c(0, 1)
    ylim_right <- c(0, 1)
    
    # # Define colors
    col_left <- "#377eb8"
    col_right <- "#cc79a7"
    
    # scale_factor <- max(all_prog_sim[,"fBM"]) / max(all_prog_sim[,]$"dmg")
    scale_factor <-1
    progam_df<-result_df[result_df$phase!=5,]
    prog_duration<-result_df$end_time[result_df$phase==5 & result_df$preparation ==1]
    phase<-c("Rest", "Pre-training", "Progressive", "Race-fit")
    t_plot<-  ggplot() +
      geom_rect(data = progam_df,
                aes(xmin = start_time, xmax = end_time, ymin = -Inf, ymax = Inf,fill=my_color),
                inherit.aes = FALSE, alpha = 0.3)+
      geom_line(data=df_lines, aes(x=t,y=fBM, linetype = program_type),color=col_left)+
      geom_line(data=df_lines,aes(x=t,y = dmg*scale_factor,linetype = program_type),color=col_right) +  # rescale y2 to match
      # geom_hline(linetype = "dashed", yintercept=1, show.legend = FALSE)+
      #for victorian average 
      # geom_line(data=result_sol_ave, aes(x=t,y=fBM),color ='red')+
      # geom_line(data=result_sol_ave,aes(x=t,y = dmg*scale_factor),color ='red') +  # rescale y2 to match
      
      scale_y_continuous(
        # name = TeX("$f_{BM}$"),
        name = "Bone adaptation",
        # limits = ylim_left,
        sec.axis = sec_axis(~./scale_factor, name = "Damage")  # invert scaling
      )+
      scale_linetype_manual(
        values = c(
          "Your current program" = "solid",
          "Average program in Victoria" = "longdash"
        ),
        name = "Trajectory"
      )+
      scale_fill_identity(name = "Program",   # legend title
                          labels = phase,
                          breaks = c("#99daff", "#C1E9DE","#ffe099", "#e3b5ce"),
                          guide = "legend") +           # force a legend for hex colors)   # use hex codes directly
      labs(x = "Time (days)", title =paste0("Total duration of each preperation  = ", prog_duration, " days"))+
      theme_bw()+
      theme(legend.box = "vertical",
            axis.title.y.right = element_text(angle = 90,color = col_right,size=29),
            axis.text.y.right = element_text(color = col_right,size=20),
            axis.title.y.left = element_text(color = col_left,size=25),
            axis.text.y.left = element_text(color = col_left,size=20),
            axis.title.x = element_text(size=25),
            axis.text.x = element_text(size=20),
            legend.position = "bottom",
            legend.title = element_text(size=25),
            legend.text = element_text(size=20),
            # panel.background = element_rect(fill = "white"),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            plot.title = element_text(family = "serif",
                                      face = "bold",
                                      # colour = "darkblue",
                                      size = 29,
                                      hjust = 0.5)
      )+
      guides(
        fill = guide_legend(order = 1, nrow = 1,keywidth = 3),
        linetype = guide_legend(order = 2, nrow = 1,keywidth = 4,
                                override.aes = list(
                                  colour = "black",
                                  linewidth = 1.2
                                ))
      ) 
    if (max_dmg>=1){
      fail_time<-result_sol$t[which(result_sol$dmg>=1)][1]
      t_plot+annotate("text", x = mean(result_sol$t), y = 0.2, label = paste0("WARNING: Expected bone injury at day = ", round(fail_time)),colour = "red", size = 15)+
        geom_hline(linetype = "dashed", yintercept=1, show.legend = FALSE,colour = "red")
    }else{
      t_plot 
    }
  })
  
  output$summary_plot <- renderPlot({
    
    result_df <- sim()[["df_changes"]]

    prep1<-result_df[result_df$preparation==1,]
    prepf<-result_df[result_df$preparation==input$n_seasons,]
    phase_labels <- c(
      "1" = "Rest",
      "2" = "Pre-training",
      "3" = "Progresive",
      "4" = "Race-fit",
      "5" = "Total"
    )
    first_prep<-ggplot(prep1,aes(x=factor(phase),y=dmg_change, fill = my_color))+
      geom_bar(stat = "identity")+
      # scale_fill_manual(values = setNames(prep$my_color, prep$phase)) +
      scale_fill_identity() +
      scale_x_discrete(labels = phase_labels) +  # apply custom labels
      labs(x = "Program (First preparation)", y = "Damage gained", fill = "Phase", title ="") +
      theme_bw()+
      theme(
        axis.title.y.left = element_text(size=16),
        axis.text.y.left = element_text(size=14),
        axis.title.x = element_text(size=16),
        axis.text.x = element_text(size=14),
        legend.position = "bottom",
        legend.title = element_text(size=18),
        legend.text = element_text(size=16),
        plot.title = element_text(family = "serif",
                                  face = "bold",
                                  # colour = "darkblue",
                                  size = 16,
                                  hjust = 0.5)
      )
    
    last_prep<-ggplot(prepf,aes(x=factor(phase),y=dmg_change, fill = my_color))+
      geom_bar(stat = "identity")+
      # scale_fill_manual(values = setNames(prep$my_color, prep$phase)) +
      scale_fill_identity() +
      scale_x_discrete(labels = phase_labels) +  # apply custom labels
      labs(x = "Program (Final preparation)", y = "Damage gained", fill = "Phase") +
      theme_bw()+
      theme(
        axis.title.y.left = element_text(size=16),
        axis.text.y.left = element_text(size=14),
        axis.title.x = element_text(size=16),
        axis.text.x = element_text(size=14),
        legend.position = "bottom",
        legend.title = element_text(size=18),
        legend.text = element_text(size=16)
      )
    
    first_prep+last_prep+plot_layout(ncol = 1)
  })
  
  output$df_table <- DT::renderDataTable({
    df<-sim()[["df_changes"]]
    # Round for display
    df<-df[,c(2,1,3,4,5,6,7,8)]
    df$dmg_min<-round(df$dmg_min,3)
    df$dmg_max<-round(df$dmg_max,3)
    df$fBM_change<-round(df$fBM_change,3)
    df$dmg_change<-round(df$dmg_change,3)
    
    phase_labels <- c("Rest","Pre-training","Progresive","Race-fit","Preparation total"
    )
    for (i in nrow(df)){
      for (j in seq_along(phase_labels)){
        rest<-which(df$phase==j)
        df$phase[rest]<-phase_labels[j]
      }
    }
    names(df)<-c("Preperation","Program phase","Minimum damage","Maximum damage", "Change in BVF","Change in damage","Start (day)", "End (day)")
    df
  }, options = list(pageLength = 10))
  
  output$model_info <- renderUI({
    # tags$iframe(style="height:600px; width:100%", src="training_program_durations2.pdf")
    
  })
}

shinyApp(ui = ui, server = server)
