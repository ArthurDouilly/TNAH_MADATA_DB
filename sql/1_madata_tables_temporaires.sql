-- SCRIPT DE CRÉATION DES TABLES TEMPORAIRES ISSUES DES JEUX DE DONNÉES EN CSV
-- le but de ce script est de créer une table temporaire pour les jeux de données
-- ainsi que de premiers traitements de qualité de la donnée (formats, noms de colonnes...)

begin ;

-- facilite l'écriture des requêtes en évitant d'avoir à spécifier le schéma et la table à chaque fois
set search_path to madata_db ;

-- corrige des erreurs de traitement des dates lors de l'exécution du script
SET DateStyle TO european ;

-- jeu de données #1, les activités du SDP du MAD

CREATE TABLE IF NOT EXISTS TMP_ACTIVITES_SDP AS(
-- on débute le traitement par le nettoyage des données et l'attribution de noms de colonnes corrects dans un CTE
-- il s'agit ici d'abord d'effectuer des trims, de corriger l'écriture et d'entrer les formats de données corrects
-- un seul traitement important s'impose ici, le découpage de la colonne 'types de public' avec 'unnest(string_to_array)'
-- car celui-ci ne pouvait pas être réalisé en même temps que celui qui était nécessaire pour les salles
with CTE_FORMATTAGE_ACTSDP as(
select
	CAST (Initcap(trim(NOM)) as text) as NOM_SEANCE,
	CAST (lower("type d'activité") as varchar(50)) as TYPE_ACTIVITE,
	CAST (trim(unnest(string_to_array("types de public",','))) as varchar(50)) as TYPE_PUBLIC, -- plusieurs valeurs
	CAST (lower(trim(EXPOSITION)) as varchar(50)) as EXPOSITION,
	CAST (trim("réservation") as varchar(50)) as RESERVATION, -- valeurs vides
	CAST (trim("nature de client") as varchar(20)) as NATURE_CLIENT, -- valeurs vides
	CAST (trim("type de client") as varchar(50)) as TYPE_CLIENT, -- valeurs vides
	CAST (trim("catégorie de client") as varchar(50)) as CATEGORIE_CLIENT, -- valeurs vides
	CAST (trim("niveau de groupe") as varchar(50)) as NIVEAU_GROUPE, -- valeurs vides
	CAST (trim("langue du groupe") as varchar(20)) as LANGUE_GROUPE, -- valeurs vides
	CAST ("thème" as varchar(10)) as THEME, -- colonne vide
	CAST (date AS DATE) AS DATE_SEANCE,
	CAST (HEURE as time) as HEURE_DEBUT,
	CAST ("durée" as integer) as DUREE_SEANCE,
	CAST (FIN as time) as HEURE_FIN,
	CAST ("en vente" as boolean) as EN_VENTE, -- boolean
	CAST ("nature de la séance" as varchar(10)) as NATURE_SEANCE,
	CAST (Initcap(trim(regexp_replace(SALLES,'\s-\s','_','g'))) as varchar(100)) as SALLES, -- plusieurs valeurs
	cast ("langues de l'activite" as varchar(10)) as LANGUE_ACTIVITE,
	cast ("matériels" as varchar(50)) as MATERIELS, -- valeurs vides
	cast ("places ouvertes" as integer) as PLACES_OUVERTES, -- integer
	cast ("places vendues" as integer) as PLACES_VENDUES, -- integer
	cast ("places disponibles" as integer) as PLACES_DISPONIBLES, -- integer
	cast (OVERBOOKING as integer) as OVERBOOKING,
	cast ("overbooking vendu" as integer) as OVERBOOKING_VENDU, -- integer
	cast ("overbooking disponible" as integer) as OVERBOOKING_DISPONIBLE, -- integer
	cast ("taux de remplissage" as integer) as TAUX_REMPLISSAGE, -- integer
	cast ("Montant" AS integer) as MONTANT, -- integer
	cast ("temps de préparation" as integer) as TEMPS_PREPARATION, -- integer
	cast ("temps de rangement" as integer) as TEMPS_RANGEMENT, -- integer
	cast ("temps annexe total" as integer) as TEMPS_ANNEXE_TOTAL, -- integer
	-- les tables ci-dessous sont partielles et représentent un effort interne du MAD pour croiser les données
	-- faut-il les garder ? La question se pose.
	cast (trim("Types de public (croisement col C et F)") AS varchar(20)) AS TYPE_PUBLIC_CROISEMENT,
	cast (trim("AGE ( Type de client ? Col H)") AS varchar(20)) as AGE_CLIENT, -- valeurs vides
	cast (trim("Niveau groupe / détail âge (col I)") AS varchar(100)) as NIVEAU_GROUPE_PAR_AGE, -- valeurs vides
	cast (LANGUE AS varchar(20)) as LANGUE, -- valeurs vides
	cast (trim(lower("TARIF")) AS varchar(20)) AS TARIF -- valeurs vides
FROM activites_sdp -- importation des données depuis le csv d'entrée
)
-- après le CTE, on réemploie les données corrigées immédiatement pour un deuxième traitement
-- ici la création d'un ID et le unnesting des valeurs
select
	-- le premier élément ajouté est un identifiant de séance construit avec la concaténation de 4 éléments
	-- la date, l'heure de début de séance, le type d'activité recensé et l'exposition
	concat(
		cast(to_char(DATE_SEANCE,'yyyymmdd') as varchar(30)), -- to_char transforme la date en string selon le format spécifié
		'_', -- intervalles permettant de différencier visuellement les parties de l'id
		cast (to_char(HEURE_DEBUT,'HH24MI') as varchar(10)), -- pareil ici pour le format time
		'_',
		case -- ce case permet de raccourcir les éléments constitutifs de l'id pour maximiser l'information sans la rendre trop longue
			when TYPE_ACTIVITE = 'visite guidée' then 'VG'
			when TYPE_ACTIVITE = 'visite-atelier' then 'VA'
			when TYPE_ACTIVITE = 'groupe en visite libre' then 'VL'
			when TYPE_ACTIVITE = 'visite théâtralisée' then 'VT'
			when TYPE_ACTIVITE = 'événement' then 'EV'
			when TYPE_ACTIVITE = 'parcours' then 'PA'
			when TYPE_ACTIVITE = 'atelier de pratique artistique' then 'AP'
			when TYPE_ACTIVITE = 'hors public' then 'HP'
			when TYPE_ACTIVITE = 'privatisation' then 'PR'
			when TYPE_ACTIVITE = 'stage' then 'ST'
			when TYPE_ACTIVITE = 'conference' then 'CO'
			else 'XX' -- le 'else' est indiqué ici afin de pouvoir repérer rapidement des erreurs ou des manques d'information
		end, -- fin du case
		'_',
		case -- même logique ici que pour le case précédent
			when EXPOSITION = 'rococo & co. de nicolas pineau à cindy sherman' then 'ROC'
			when EXPOSITION = '1925-2025. cent ans d''art déco' then 'CAD'
			when EXPOSITION = 'paul poiret, la mode est une fête' then 'POI'
			when EXPOSITION = 'l''intime, de la chambre aux réseaux sociaux' then 'INT'
			when EXPOSITION = 'la mode en modèles' then 'MOD'
			when EXPOSITION = 'galerie des bijoux' then 'BIJ'
			when EXPOSITION = 'parcours mode, bijoux, design' then 'MBD'
			when EXPOSITION = 'christofle, une brillante histoire' then 'CHR'
			when EXPOSITION = 'musée des arts décoratifs - collections' then 'COL'
			when EXPOSITION = 'mon ours en peluche' then 'OUR'
			else 'XXX'
		end)
	as ID_SEANCE,	
	NOM_SEANCE,
	TYPE_ACTIVITE,
	TYPE_PUBLIC,
	EXPOSITION,
	RESERVATION,
	NATURE_CLIENT,
	TYPE_CLIENT,
	CATEGORIE_CLIENT,
	NIVEAU_GROUPE,
	LANGUE_GROUPE,
	THEME,
	DATE_SEANCE,
	HEURE_DEBUT,
	DUREE_SEANCE,
	HEURE_FIN,
	EN_VENTE,
	NATURE_SEANCE,
	trim(unnest(string_to_array(SALLES,','))) as SALLES, -- comme pour TYPE_PUBLIC plus haut, la multitude de salles doit être transformée en produits cartésiens
	LANGUE_ACTIVITE,
	MATERIELS,
	PLACES_OUVERTES,
	PLACES_VENDUES,
	PLACES_DISPONIBLES,
	OVERBOOKING,
	OVERBOOKING_VENDU,
	OVERBOOKING_DISPONIBLE,
	TAUX_REMPLISSAGE,
	MONTANT,
	TEMPS_PREPARATION,
	TEMPS_RANGEMENT,
	TEMPS_ANNEXE_TOTAL,
	TYPE_PUBLIC_CROISEMENT,
	AGE_CLIENT,
	NIVEAU_GROUPE_PAR_AGE,
	LANGUE,
	TARIF
from CTE_FORMATTAGE_ACTSDP -- appel du CTE défini plus haut afin d'employer les données nettoyées
);

-- jeu de données #2, la liste des billets vendus
create table if not exists TMP_BILLETS_VENDUS AS(
with CTE_FORMATTAGE_BILLETS as(
select
	cast ("Date De Création" as date) as DATE_CREATION_BILLET,
	cast ("Heure D'Opération (opération)" AS time) as HEURE_OPERATION_BILLET,
	cast ("Numéro (opération)" as varchar(100)) as NUM_OPERATION_BILLET,
	cast (trim("Nom (activité)") as varchar(100)) as NOM_ACTIVITE,
	cast (lower(trim("Nom (exposition)")) as varchar(100)) as EXPOSITION,
	cast ("Date De Séance (seance)" as date) as DATE_SEANCE,
	cast ("Heure De Début (seance)" as time) as HEURE_DEBUT,
	cast ("Nom" as varchar(100)) as NOM_CLIENT, -- il faudra retirer les prénoms encore
	cast (trim("Code Postal") as varchar(50)) as CODE_POSTAL,
	cast (trim(Initcap("Ville")) as varchar(100)) AS VILLE,
	cast (trim(Initcap("Pays")) as varchar(50)) AS PAYS,
	cast ("Numéro Du Billet" as varchar(100)) as NUMERO_BILLET,
	cast ("Type De Billet" as varchar(50)) as TYPE_BILLET, -- une seule valeur
	cast (trim("Tarif") as varchar) as TARIF_BILLET,
	cast ("Pu Net Ttc" as integer) as PRIX_UNITAIRE_TTC,
	cast ("Quantité" AS integer) as QUANTITE_BILLET, -- une seule valeur
	cast (trim("État") as varchar(10)) as ETAT_BILLET,
	cast ("Code-Barres Du Billet" AS varchar(100)) as CODE_BARRE_BILLET
FROM billets_vendus_forfaits
)
select
	concat(
		cast(to_char(DATE_SEANCE,'yyyymmdd') as varchar(30)), -- to_char transforme la date en string selon le format spécifié
		'_', -- intervalles permettant de différencier visuellement les parties de l'id
		cast (to_char(HEURE_DEBUT,'HH24MI') as varchar(10)), -- pareil ici pour le format time
		'_',
		case -- ce case permet de raccourcir les éléments constitutifs de l'id pour maximiser l'information sans la rendre trop longue
			when NOM_ACTIVITE like 'VG%' then 'VG'
			when NOM_ACTIVITE like 'VA%' then 'VA'
			when NOM_ACTIVITE like 'VL%' then 'VL'
			when NOM_ACTIVITE like 'VT%' then 'VT'
			when NOM_ACTIVITE like 'événement' then 'EV'
			when NOM_ACTIVITE like 'PARCOURS%' then 'PA'
			when NOM_ACTIVITE like 'APA%' then 'AP'
			when NOM_ACTIVITE like 'ATELIER%' then 'AT'
			when NOM_ACTIVITE like 'SUPPLEMENT%' then 'SU'
			else 'XX' -- le 'else' est indiqué ici afin de pouvoir repérer rapidement des erreurs ou des manques d'information
		end, -- fin du case
		'_',
		case -- même logique ici que pour le case précédent
			when EXPOSITION = 'rococo & co. de nicolas pineau à cindy sherman' then 'ROC'
			when EXPOSITION = '1925-2025. cent ans d''art déco' then 'CAD'
			when EXPOSITION = 'paul poiret, la mode est une fête' then 'POI'
			when EXPOSITION = 'l''intime, de la chambre aux réseaux sociaux' then 'INT'
			when EXPOSITION = 'la mode en modèles' then 'MOD'
			when EXPOSITION = 'galerie des bijoux' then 'BIJ'
			when EXPOSITION = 'parcours mode, bijoux, design' then 'MBD'
			when EXPOSITION = 'christofle, une brillante histoire' then 'CHR'
			when EXPOSITION = 'musée des arts décoratifs - collections' then 'COL'
			when EXPOSITION = 'mon ours en peluche' then 'OUR'
			when EXPOSITION = 'la naissance des grands magasins' then 'GMG'
			when EXPOSITION = 'cabinet des dessins, papiers peints, photographies' then 'DPP'
			else 'XXX'
		end)
		AS ID_SEANCE,
		*
	from CTE_FORMATTAGE_BILLETS
);

-- jeu de données #3, musées de France et données handicap requêtés sur wikidata 
create table if not exists TMP_WIKIDATA_MDF AS(
select
	cast (trim("musee") as varchar(20)) as LIEN_WIKIDATA, 
	cast (trim("idMuseofile") as varchar(20)) as ID_MUSEOFILE,
	cast (trim("museeLabel") as varchar(300)) as NOM_MUSEE,
	cast (trim(initcap("villeLabel")) as varchar(100)) as VILLE,
	cast (trim("description") as text) as DESCRIPTION,
	cast (trim("labelTourismeHandicap") as varchar(100)) as LABEL_TH,
	cast (trim("accessibilitePMRLabel") as text) as ACCESSIBILITE_PMR

FROM wikidata_mdf
);

-- jeu de données #4, Fréquentation des musées de France issu de data.gouv
create table if not exists TMP_FREQUENTATION_MDF AS(
select
	CAST(TRIM("IDPatrimostat") AS VARCHAR(20)) AS ID_PATRIMOSTAT,
	CAST(TRIM("IDMuseofile") AS VARCHAR(20)) AS ID_MUSEOFILE,
	CAST(TRIM(INITCAP("region")) AS VARCHAR(100)) AS REGION,
	CAST(TRIM(INITCAP("departement")) AS VARCHAR(100)) AS DEPARTEMENT,
	CAST("dateappellation" AS DATE) AS DATE_APPELLATION,
	CAST(TRIM("ferme") AS VARCHAR(10)) AS EST_FERME,
	CAST(NULLIF(CAST("anneefermeture" AS TEXT), 'Inconnu') AS INTEGER) AS ANNEE_FERMETURE,
	CAST(TRIM("nom_du_musee") AS VARCHAR(300)) AS NOM_DU_MUSEE,
	CAST(TRIM(CAST("lien_avec" AS TEXT)) AS VARCHAR(100)) AS LIEN_AVEC,  
	CAST(TRIM("ville") AS VARCHAR(100)) AS VILLE, 	
	CAST(TRIM("codeInseeCommune") AS VARCHAR(20)) AS CODE_INSEE,
	CAST(NULLIF(CAST("annee" AS TEXT), 'Inconnu') AS INTEGER) AS ANNEE,
	CAST(NULLIF(CAST("payant" AS TEXT), 'Inconnu') AS INTEGER) AS PAYANT,
	CAST(NULLIF(CAST("gratuit" AS TEXT), 'Inconnu') AS INTEGER) AS GRATUIT,
	CAST(NULLIF(CAST("total" AS TEXT), 'Inconnu') AS INTEGER) AS TOTAL,
	CAST(NULLIF(CAST("individuel" AS TEXT), 'Inconnu') AS INTEGER) AS INDIVIDUEL,
	CAST(NULLIF(CAST("scolaires" AS TEXT), 'Inconnu') AS INTEGER) AS SCOLAIRES,
	CAST(NULLIF(CAST("groupes_hors_scolaires" AS TEXT), 'Inconnu') AS INTEGER) AS GROUPES_HORS_SCOLAIRES,
	CAST(NULLIF(CAST("moins_18_ans_hors_scolaires" AS TEXT), 'Inconnu') AS INTEGER) AS MOINS_18_HORS_SCOLAIRE,
	CAST(NULLIF(CAST("_18_25_ans" AS TEXT), 'Inconnu') AS INTEGER) AS VISITEURS_18_25

FROM frequentation_mdf
);

commit ;