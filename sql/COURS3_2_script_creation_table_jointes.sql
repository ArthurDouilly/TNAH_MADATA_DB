-- Marque le début de ma transaction (début du script)
BEGIN ;

-- Toujours utiliser le même schéma. !!ATTENTION!! si vous ne le configurez pas, vous serez obligé de préciser {nom_schema}.{nom_table} pour chaque requête ! Le nom dus schéma ici doit être le même que dans le fichier .env du script python
SET search_path TO film_fr_2026;

-- Créer la table consolidée pour les données jointes
create table tmp_film_donnees
(
	annee INTEGER,
	cnc INTEGER,
	visa INTEGER,
	titre VARCHAR,
	nationalite varchar,
	distributeur varchar, 
	classification varchar,  
	genre varchar,
	sortie date, 
	art_et_essai boolean, 
	etab_s1 integer, 
	realisateur varchar, 
	devis integer, 
	uri_wikidata varchar, 
	film_label varchar, 
	id_imdb varchar
);

-- Insérer les données des différentes sources : nous utilisons le LEFT JOIN afin de conserver la vue 'film distribué en France'
insert into tmp_film_donnees
(annee, cnc, visa, titre, nationalite, distributeur, classification, genre, sortie, art_et_essai, etab_s1, realisateur, devis, uri_wikidata, film_label, id_imdb)
select distinct
	a.annee,
	a.cnc,
	a.visa,
	a.titre,
	a.nationalite,
	a.distributeur,
	a.classification,
	a.genre,
	a.sortie,
	a.art_et_essai,
	a.etab_s1,
	b.realisateur,
	b.devis,
	c.uri_wikidata,
	c.film_label,
	c.id_imdb 
from tmp_film_sortie a 
left join tmp_premier_film b on a.visa = b.visa
left join tmp_film_wikidata c on a.visa = c.visa ;

-- Mettre à jour les données de tmp_film_donnees avec les information WIKIDATA récupérer grâce à une jointure faite sur le titre et la date des films
with wikidata as (select distinct a.visa, a.titre,  b.uri_wikidata, b.film_label, b.id_imdb  
from tmp_film_sortie a 
inner join tmp_film_wikidata b 
on  b.DATE_FILM between cast(TO_CHAR(sortie - interval '3 years', 'YYYY') as INTEGER) and CAST(TO_CHAR(sortie + interval '3 years', 'YYYY') as INTEGER)
and (LOWER(REGEXP_REPLACE(a.titre, '[^a-zA-Z0-9 ]', '', 'g')) = LOWER(REGEXP_REPLACE(b.film_label, '[^a-zA-Z0-9 ]', '', 'g'))) and b.visa is null )
update tmp_film_donnees 
set uri_wikidata = a.uri_wikidata, film_label = a.film_label, id_imdb = a.id_imdb
from wikidata a
where tmp_film_donnees.visa = a.visa;

select * from tmp_film_donnees ;

-- Marque la fin de ma transaction (fin du script)
COMMIT ;


