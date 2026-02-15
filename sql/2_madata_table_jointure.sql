-- SCRIPT DE JOINTURE ENTRE LES DONNÉES DU MAD
-- le but de ce script est de réaliser la jointure entre les jeux de données
-- cela se fait dans une nouvelle table temporaire qui est la jointure de nos deux jeux

begin ;

set search_path to madata_db;

-- 1. création de la table TMP_MAD_DONNEES qui est la table de jointure entre nos deux jeux internes.

create table if not exists TMP_MAD_DONNEES(
-- création de la table avec la mention 'if not exists' pour itération
	-- on rajoute d'abord les données du jeu #1, 'activites_sdp'
	id_seance_complet varchar,
	id_seance varchar,
	nom_seance varchar,
	date_seance date,
	heure_debut time,
	heure_fin time,
	type_activite varchar,
	type_public varchar,
	exposition varchar,
	reservation varchar,
	nature_client varchar,
	type_client varchar,
	categorie_client varchar,
	niveau_groupe varchar,
	en_vente boolean,
	nature_seance varchar,
	salles varchar,
	langue_activite varchar,
	materiels varchar,
	places_ouvertes integer,
	places_vendues integer,
	places_disponibles integer,
	overbooking integer,
	overbooking_vendu integer,
	overbooking_disponible integer,
	taux_remplissage real,
	montant integer,
	temps_preparation integer,
	temps_rangement integer,
	temps_annexe_total integer,
	tarif varchar,
	-- on y ajoute ensuite les valeurs issues du jeu #2, 'billets_vendus_forfaits'
	nom_activite varchar,
	date_creation_billet date,
	heure_operation_billet time,
	num_operation_billet varchar,
	nom_client varchar,
	code_postal varchar,
	ville varchar,
	pays varchar,
	numero_billet varchar,
	type_billet varchar,
	tarif_billet text,
	prix_unitaire_ttc integer,
	quantite_billet varchar,
	code_barre_billet varchar
);

-- 2. insertion de ces données au sein de la table

truncate TMP_MAD_DONNEES ; -- suppression des données de la table en cas d'itération

insert into TMP_MAD_DONNEES -- insertion des données
(id_seance_complet, id_seance, nom_seance, date_seance, heure_debut, heure_fin, type_activite, type_public, exposition, reservation,
nature_client, type_client, categorie_client, niveau_groupe, en_vente, nature_seance, salles, langue_activite, materiels, 
places_ouvertes, places_vendues, places_disponibles, overbooking, overbooking_vendu, overbooking_disponible, taux_remplissage, 
montant, temps_preparation, temps_rangement, temps_annexe_total, tarif, nom_activite, date_creation_billet, heure_operation_billet, 
num_operation_billet, nom_client, code_postal, ville, pays, numero_billet, type_billet, tarif_billet, prix_unitaire_ttc, quantite_billet, code_barre_billet)
-- on débute par un premier CTE permettant la jointure et sélectionnant les colonnes sur lesquelles on veut opérer
with CTE_MAD_DONNEES as(
select 
	-- cas particulier, comme on ne veut avoir qu'un seul ID, le case ci-dessous doit gérer les exceptions
	-- le but est de faire en sorte qu'il y ait aussi peu de NULL que possible
	-- et de faire coincider les deux s'il y a des séances non référencées dans l'un ou l'autre des jeux
	case
		when a.id_seance = b.id_seance then a.id_seance -- si les deux id sont les mêmes, on garde le a
		when a.id_seance is null and b.id_seance is not null then b.id_seance -- si a est vide, on prend b
		when a.id_seance is not null and b.id_seance is null then a.id_seance -- si b est vide, on prend a
		else null -- sinon, valeur NULL
	end 
	as id_seance,
	-- les valeurs a proviennent du jeu #1
	a.nom_seance,
	a.date_seance as date_a,
	a.heure_debut as heure_a,
	a.heure_fin,
	a.type_activite,
	a.type_public,
	a.exposition as expo_a,
	a.reservation,
	a.nature_client,
	a.type_client,
	a.categorie_client,
	a.niveau_groupe,
	a.en_vente,
	a.nature_seance,
	a.salles,
	a.langue_activite,
	a.materiels,
	a.places_ouvertes,
	a.places_vendues,
	a.places_disponibles,
	a.overbooking,
	a.overbooking_vendu,
	a.overbooking_disponible,
	a.taux_remplissage,
	a.montant,
	a.temps_preparation,
	a.temps_rangement,
	a.temps_annexe_total,
	a.tarif,
	-- les valeurs b proviennent du jeu b
	b.date_seance as date_b,
	b.heure_debut as heure_b,
	b.exposition as expo_b,
	b.nom_activite,
	b.date_creation_billet,
	b.heure_operation_billet,
	b.num_operation_billet,
	b.nom_client,
	b.code_postal,
	b.ville,
	b.pays,
	b.numero_billet,
	b.type_billet,
	b.tarif_billet,
	b.prix_unitaire_ttc,
	b.quantite_billet,
	b.code_barre_billet
from tmp_activites_sdp a 
full join tmp_billets_vendus b -- le left join est important pour que toutes les valeurs soient prises en compte
on a.id_seance = b.id_seance -- les deux tables ayant un même id_seance, cela permet de faire la jointure
), 
-- un deuxième CTE utilise ensuite les données d'entrées pour joindre les informations et corriger d'éventuelles erreurs
CTE_ID_COMPLET as (select 
	case -- rajout du nom de la séance dans l'ID_SEANCE afin de limiter le nombre de doublons
		when nom_seance is not null then concat(id_seance,'_',lower(regexp_replace(nom_seance,'[^a-zA-Z0-9]','','g')))
		when nom_seance is null then concat(id_seance,'_',lower(regexp_replace(nom_activite,'[^a-zA-Z0_9]','','g')))
	end as id_seance_complet,
	id_seance,
	case -- case pour récupérer les noms de séance depuis les deux tables temporaires et concaténer
		when nom_seance is null and nom_activite is not null then nom_activite
		else nom_seance
	end as nom_seance,
	case -- pareil pour les dates, qui ont été renommées car les champs de base ont le même nom
		when date_a is null and date_b is not null then date_b
		else date_a
	end as date_seance,
	case -- idem pour l'heure de début de séance
		when heure_a is null and heure_b is not null then heure_b
		else heure_a
	end as heure_debut,
	heure_fin,
	case -- afin de remplir plus en détail la table activité et éviter des doublons comme la table 'billets_vendus' n'a pas de type_activite, on récupère des informations depuis l'ID
		when type_activite is null
		then case
				when substring(id_seance,15,2) like '%VL%' then 'groupe en visite libre'
				when substring(id_seance,15,2) like '%VG%' then 'visite guidée'
				when substring(id_seance,15,2) like '%VT%' then 'visite théâtralisée'
				when substring(id_seance,15,2) like '%VA%' then 'visite-atelier'
				when substring(id_seance,15,2) like '%PA%' then 'parcours'		
				when substring(id_seance,15,2) like '%AT%' then 'atelier'
				when substring(id_seance,15,2) like '%AP%' then 'atelier de pratique artistique'
				when substring(id_seance,15,2) like '%SU%' then 'supplément goûter'
				when substring(id_seance,15,2) like '%XX%' then 'Non renseigné'
				else null
			end
		else type_activite
	end as type_activite,
	type_public,
	case -- pareil que pour les dates, on rassemble les informations sur les expositions depuis les deux tables
		when expo_a = expo_b then expo_a
		when expo_a is null then expo_b
		when expo_b is null then expo_a
		else null
	end as exposition,
	case -- on récupère les informations du client lorsque le dossier de réservation est vide afin d'enrichir les données et de faciliter la constitution d'un id_groupe plus tard
		when reservation is null and nom_client is not null then concat('dossier ', substring(nom_client,1,3))
		else reservation
	end as reservation,
	nature_client,
	type_client,
	categorie_client,
	niveau_groupe,
	en_vente,
	nature_seance,
	salles,
	langue_activite,
	materiels,
	places_ouvertes,
	places_vendues,
	places_disponibles,
	overbooking,
	overbooking_vendu,
	overbooking_disponible,
	taux_remplissage,
	montant,
	temps_preparation,
	temps_rangement,
	temps_annexe_total,
	tarif,
	nom_activite,
	date_creation_billet,
	heure_operation_billet,
	num_operation_billet,
	nom_client,
	code_postal,
	ville,
	pays,
	numero_billet,
	type_billet,
	tarif_billet,
	prix_unitaire_ttc,
	quantite_billet,
	code_barre_billet
from CTE_MAD_DONNEES)
-- une fois que les corrections sont réalisées dans le 2e CTE, on appelle l'ensemble dans la requête finale
-- celle-ci comporte une dernière vague de corrections portant sur des doublons individuels dans 'id_seance_complet'
select 
	case -- case permettant de gérer les derniers doublons d'ID
		when id_seance_complet = '20251114_1230_VG_CAD_vghcentansdartdeco' and nature_seance = 'G' then concat('20251114_1230_VG_CAD_vghcentansdartdeco','_g')
		when id_seance_complet = '20250820_1015_VL_COL_vlcollectionsdedesign' and heure_fin = '11:15:00' then concat('20250820_1015_VL_COL_vlcollectionsdedesign','_1115')
		when id_seance_complet = '20250425_1430_VA_OUR_vamonpetitoursdepoche' and nature_seance = 'A' then concat('20250425_1430_VA_OUR_vamonpetitoursdepoche','_a')
		when id_seance_complet = '20250604_1430_VA_BIJ_vabijouenfolie' and nature_seance = 'G' then concat('20250604_1430_VA_BIJ_vabijouenfolie','_g')
		else id_seance_complet
	end as id_seance_complet,
	id_seance,
	nom_seance,
	date_seance,
	heure_debut,
	heure_fin,
	type_activite,
	type_public,
	exposition,
	reservation,
	nature_client,
	type_client,
	categorie_client,
	niveau_groupe,
	en_vente,
	nature_seance,
	salles,
	langue_activite,
	materiels,
	places_ouvertes,
	places_vendues,
	places_disponibles,
	overbooking,
	overbooking_vendu,
	overbooking_disponible,
	taux_remplissage,
	montant,
	temps_preparation,
	temps_rangement,
	temps_annexe_total,
	tarif,
	nom_activite,
	date_creation_billet,
	heure_operation_billet,
	num_operation_billet,
	nom_client,
	code_postal,
	ville,
	pays,
	numero_billet,
	type_billet,
	tarif_billet,
	prix_unitaire_ttc,
	quantite_billet,
	code_barre_billet
from CTE_ID_COMPLET
;

-- SCRIPT DE JOINTURE ENTRE LES DONNEES EXTERNES
-- vise à joindre aux données requêtés sur wikidata des données de fréquentation plus en lien avec les données du MAD 

-- création de la table tmp_donnees_externes
create table if not exists TMP_DONNEES_EXTERNES(
	-- Ajout des données du jeu #3, 'wikidata_mdf'
	LIEN_WIKIDATA VARCHAR(20), 
	ID_MUSEOFILE VARCHAR(20),
	NOM_MUSEE VARCHAR(300),
	VILLE VARCHAR(100),
	DESCRIPTION TEXT,
	LABEL_TH VARCHAR(100),
	ACCESSIBILITE_PMR TEXT,
	
	-- Ajout des données du jeu #4, 'frequentation_mdf'
	ANNEE INTEGER,
	PAYANT INTEGER,
	GRATUIT INTEGER,
	TOTAL INTEGER,
	INDIVIDUEL INTEGER,
	SCOLAIRES INTEGER,
	GROUPES_HORS_SCOLAIRES INTEGER,
	MOINS_18_HORS_SCOLAIRE INTEGER,
	VISITEURS_18_25 INTEGER
);

-- creation de la table virtuelle
truncate TMP_DONNEES_EXTERNES ;
insert into TMP_DONNEES_EXTERNES 
(LIEN_WIKIDATA, ID_MUSEOFILE, NOM_MUSEE, VILLE, DESCRIPTION, LABEL_TH, ACCESSIBILITE_PMR, 
 ANNEE, PAYANT, GRATUIT, TOTAL, INDIVIDUEL, SCOLAIRES, GROUPES_HORS_SCOLAIRES, 
 MOINS_18_HORS_SCOLAIRE, VISITEURS_18_25)

with CTE_DONNEES_EXTERNES as (
	select
		-- toutes les colonnes de "Wikidata"
		w.LIEN_WIKIDATA,
		w.ID_MUSEOFILE,
		w.NOM_MUSEE,
		w.VILLE,
		w.DESCRIPTION,
		w.LABEL_TH,
		w.ACCESSIBILITE_PMR,
		
		-- les colonnes de "Fréquentation" qui nous intéressent 
		f.ANNEE,
		f.PAYANT,
		f.GRATUIT,
		f.TOTAL,
		f.INDIVIDUEL,
		f.SCOLAIRES,
		f.GROUPES_HORS_SCOLAIRES,
		f.MOINS_18_HORS_SCOLAIRE,
		f.VISITEURS_18_25
	
	from TMP_WIKIDATA_MDF w
	inner join TMP_FREQUENTATION_MDF f -- inner join pour récupérer seulement les musées de France présents dans les deux jeux
		on w.ID_MUSEOFILE = f.ID_MUSEOFILE
	where f.ANNEE = 2024 -- on récupère uniquement les données de l'année 2024, qui nous intéresse pour la comparaison
)

SELECT * FROM CTE_DONNEES_EXTERNES;

commit ;