-- Marque le début de ma transaction
BEGIN;

-- Toujours utiliser le même schéma. !!ATTENTION!! si vous ne le configurez pas, vous serez obligé de préciser {nom_schema}.{nom_table} pour chaque requête ! Le nom dus schéma ici doit être le même que dans le fichier .env du script python
SET search_path TO film_fr_2026;

-- FILM_SORTIE : Créer une nouvelle table à partir des transformations de la donnée
create table TMP_FILM_SORTIE AS(
SELECT
	CAST(ANNEE as INTEGER),
	cast(CNC as INTEGER),
	cast(visa as INTEGER) as VISA,
	TRIM(INITCAP(titre)) as TITRE,
	TRIM(INITCAP(NATIONALITE)) as nationalite,
	TRIM(INITCAP(DISTRIBUTEUR)) as DISTRIBUTEUR,
	TRIM(classification) as CLASSIFICATION,
	TRIM(INITCAP(genre)) as GENRE,
	cast(SORTIE as DATE),
	cast(case
		when 
art_et_essai = 'OUI' then true
		else false
	end as BOOLEAN) as ART_ET_ESSAI,
	cast(etab_s1 as INTEGER)
FROM
	film_sortie ); 

-- FILM_WIKIDATA : Créer une nouvelle table à partir des transformations de la donnée
create table TMP_FILM_WIKIDATA as(
select 
	FILM as URI_WIKIDATA,
-- suppression des espaces avant et après la valeur
	TRIM(filmlabel) as FILM_LABEL,
-- replacement des vides par null
	nullif(TRIM(altlabel), '') as FILM_ALT_LABEL,
-- replacement des vides par null
	cast(yeardate as INTEGER) as DATE_FILM,
	imdbid as ID_IMDB,
-- replacement des vides par null
	cast(visa as INTEGER) as VISA
from film_wikidata 
);

-- PREMIERS_FILMS_FR : Créer une nouvelle table à partir des transformations de la donnée
create table TMP_PREMIER_FILM as (
WITH TMP_PREM_FILM AS 
(SELECT 
	cast(nullif(replace(visa, '#N/D', ''), '') as INTEGER) as VISA,
	titre,
-- Mettre des majuscule à chaque début de mot
	INITCAP(realisateur) as REALISATEUR,
-- Supprimer les espaces avant et après la valeur
	TRIM(GENRE) as GENRE,
	cast(REGEXP_REPLACE(devis, '[^0-9]', '', 'g') as INTEGER) as DEVIS,
	cast(annee as INTEGER)
FROM premiers_films )
SELECT visa, TITRE, real as REALISATEUR, GENRE, DEVIS, ANNEE
FROM TMP_PREM_FILM
-- Séparer les valeurs réalisateurs
LEFT JOIN LATERAL unnest(string_to_array(realisateur, ' / ')) AS real on TRUE );

-- Marque la fin de ma transaction (et donc de mon script)
COMMIT ;
