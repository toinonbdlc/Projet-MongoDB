
########################## package utiliser  ###############################
library(mongolite)
library(jsonlite)
library(tidyr)
library(dplyr)
library(leaflet)
######################## Partie requête mongodb ###############################

url="mongodb://etudiant:ur2@clusterm1-shard-00-00.0rm7t.mongodb.net:27017,clusterm1-shard-00-01.0rm7t.mongodb.net:27017,clusterm1-shard-00-02.0rm7t.mongodb.net:27017/?ssl=true&replicaSet=atlas-l4xi61-shard-0"

elections <- mongo(collection="elections2020_rennes", db="elections_rennes",
            url=url,
            verbose=TRUE)
#print(elections$find())


req_bureaux_votes='[
    {"$group":
        {"_id":"$nom_lieu",
            "pourc_moyen_participation":{"$avg":"$pourcentage_participation"},
            "loc" : {"$addToSet":"$loc.coordinates"}
            }
     }
]'


df_info_bureaux=elections$aggregate(req_bureaux_votes)
#print(df_info_bureaux)
#View(df_info_bureaux)
colnames(df_info_bureaux)<- c('lieu','pourcentage','loc')

req_centres_votes='[
    {"$unwind":"$candidats"},
    {"$group":
        {"_id":
                {"candidat":"$candidats.nom",
                 "lieu":"$nom_lieu"},
            "sum_nb_votes":{"$sum":"$candidats.n_votes"}
            }
        
     }
]'


df_info_centres=elections$aggregate(req_centres_votes)
#print(df_info_centres)
#View(df_info_centres)
colnames(df_info_centres)<-c('candidat_lieu','nb_votes')
########### Changement dans les dataframes pour une utilisation plus facile dans la carte ####################

### changement dans le tableau bureau pour avoir lat et lon dans une colonne séparer
longitude = c()
latitude = c()
for (i in (1:28)){
  longitude = c(longitude,df_info_bureaux$loc[[i]][,1])
  latitude = c(latitude,df_info_bureaux$loc[[i]][,2])
}
df_info_bureaux = cbind(df_info_bureaux[1:2],longitude,latitude) 

### changement dans le tableau centre pour avoir candidat et lieu dans une colonne séparer
candidat =df_info_centres$candidat_lieu[[1]]
lieu = df_info_centres$candidat_lieu[[2]]
df_info_centres = cbind(lieu,candidat,df_info_centres[2]) 

df_info_bureaux$candidat=as.factor(df_info_bureaux$candidat)

#### changement de sens dans la table avec pivot_wider
df_info_centres <- df_info_centres %>%
  pivot_wider(names_from = candidat, values_from = nb_votes)
View(df_info_centres)

### dataframe total reunissant les deux requetes
df_total=merge(df_info_bureaux,df_info_centres,by="lieu")


###################################### Partie cartographie ##################################################

##### fonction permettant de gérer la couleur en fonction du taux de participation
getColor <- function(df_info_bureaux) {
  sapply(df_info_bureaux$pourcentage, function(pourcentage) {
  if(pourcentage > quantile(df_info_bureaux$pourcentage,2/3)) {
    "green"
  } else if(pourcentage <quantile(df_info_bureaux$pourcentage,1/3) ) {
    "red"
  } else {
    "orange"
  } })
}
#### icon de visualisation 
icons <- awesomeIcons(
  icon = 'location-dot',
  iconColor = 'black',
  library = 'ion',
  markerColor = getColor(df_info_bureaux)
)


### carte leaflet
leaflet(data = df_total) %>% addTiles() %>%
  addAwesomeMarkers(~longitude, ~latitude, icon=icons,popup =~ paste(paste("<u>",lieu,"</u>",sep=""),
                           paste("Carole GANDON",as.character(df_total$`Carole GANDON`),sep=' : '),
                           paste("Matthieu THEURIER",as.character(df_total$`Matthieu THEURIER`),sep=' : '),
                           paste("Emeric SALMON",as.character(df_total$`Emeric SALMON`),sep=' : '),
                           paste("Nathalie APPÉRÉ",as.character(df_total$`Nathalie APPÉRÉ`),sep=' : '),
                           paste("Enora LE-PAPE",as.character(df_total$`Enora LE-PAPE`),sep=' : '),
                           paste("Franck DARCEL",as.character(df_total$`Franck DARCEL`),sep=' : '),
                           paste("Charles COMPAGNON",as.character(df_total$`Charles COMPAGNON`),sep=' : '),
                           paste("Valérie HAMON",as.character(df_total$`Valérie HAMON`),sep=' : '),
                           paste("Pierre PRIET",as.character(df_total$`Pierre PRIET`),sep=' : '),
                           sep="<br/>"),
    popupOptions = popupOptions(maxWidth = 200, closeOnClick = TRUE))

 

