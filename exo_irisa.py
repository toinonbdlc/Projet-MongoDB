import matplotlib.pyplot as plt
import numpy as np
from pymongo import MongoClient, DESCENDING
from pprint import pprint
import networkx as nx

db_uri = "mongodb+srv://etudiant:ur2@clusterm1.0rm7t.mongodb.net/"
client = MongoClient(db_uri,tls=True,tlsAllowInvalidCertificates=True)
db = client["publications"]

# 2.2 Réseau de publications scientifiques


#####################   REQUETE    #######################

donnees = db.hal_irisa_2021.aggregate([
    
    {"$unwind": 
            "$authors"       
    },
        
    {"$group":
            {"_id": "$authors",
                "nb":{"$sum":1},
                "titre": {"$push":"$title"}
            }                      
    },

    {"$sort": {"nb": -1}},
    {"$limit": 20}

])
    


#print(donnees)

############### MANIPULATIONS PYTHON #################

# Création d'une liste avec les noms et une liste avec les titres

dico = {}
dico2 = {}
for obj in donnees:
    print(obj)
    dico[(obj["_id"]["name"]+' '+obj["_id"]["firstname"])]= obj["titre"]
    dico2[(obj["_id"]["name"]+' '+obj["_id"]["firstname"])]= obj["nb"]
    
print(dico)
print(dico2)


# Générer toutes les paires d'auteurs
paires = [] 
for auteur1 in dico.keys(): 
    for auteur2 in dico.keys(): 
        if (auteur1!=auteur2): 
            paires.append((auteur1,auteur2)) 
#print(paires)


# Ajouter une couleur pour le nombre de publications

liste_nb = []
for nb in dico2.values(): 
    if nb not in liste_nb: 
        liste_nb.append(nb)
print(liste_nb)

# Creation d'un dictionnaire de couleur : 
liste_color = ["blue", "pink", "green", "yellow", "red", "purple", "black"]    
dico_couleur = {}
for i in range(0, len(liste_color)):
    dico_couleur[liste_nb[i]] = liste_color[i]

print(dico_couleur)

l1 = []
l2 = []
liste_compteur = []
for (auteur1, auteur2) in paires: 
    l1.append(dico[auteur1])
    l2.append(dico[auteur2])
 

#nb = set1.intersection(set2)
liste_nb = []
for i in range(0,len(l1)):
    set1 = set(l1[i])
    set2 = set(l2[i])
    nb = set1.intersection(set2)
    #print(nb)
    liste_nb.append(len(nb))
    
#print(liste_nb)

# Creation d'un tuple pour créer un graph
tuple_lien = []
for i in range(0,len(liste_nb)):
    for auteur1, auteur2 in paires:
        tuple_lien.append((auteur1, auteur2, liste_nb[i]))
        
#print(tuple_lien)    

# Garder les noeuds qui présentent un lien et création de la liste des poids
liste_tuple_lien_propre = []
liste_poids = []
for (auteur1, auteur2, poids) in tuple_lien:
    #liste_poids.append(poids)
    if poids!= 0: 
        liste_tuple_lien_propre.append((auteur1, auteur2, poids))
    #if poids not in liste_poids and poids!= 0:
        
        
#print(liste_poids)  
#print(liste_tuple_lien_propre[:10])


########################## CREATION DU GRAPHE ########################

G = nx.Graph()

# Ajout des noeuds, des liens et de leurs poids
G.add_weighted_edges_from(liste_tuple_lien_propre)


# Definir la liste des couleurs des noeuds
color_map = []
for node  in G:
    for key, value in dico2.items():
        for k, v in dico_couleur.items():
            if node == key:
                if value == k:
                    color_map.append(v)
#print(color_map)
#print(list(G.nodes))

nx.draw(G, node_color = color_map, with_labels = True)

