df<-df_changes
df<-df[,c(2,1,3,4,5,6)]
df$fBM_change<-round(df$fBM_change,3)
df$dmg_change<-round(df$dmg_change,3)

phase_labels <- c("Rest","Pre-training","Progresive","Race-fit","Season total")


for (i in nrow(df)){
  for (j in seq_along(phase_labels)){
   rest<-which(df$phase==j)
   df$phase[rest]<-phase_labels[j]
  }
}                  
names(df)<-c("Season","Program phase", "Change in BVF","Change in damage","Start (day)", "End (day)")
