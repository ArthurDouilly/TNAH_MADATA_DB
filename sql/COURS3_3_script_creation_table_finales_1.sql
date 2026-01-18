-- Marque le début de ma transaction (début du script)
BEGIN ;

-- Toujours utiliser le même schéma. !!ATTENTION!! si vous ne le configurez pas, vous serez obligé de préciser {nom_schema}.{nom_table} pour chaque requête ! Le nom dus schéma ici doit être le même que dans le fichier .env du script python
SET search_path TO film_fr_2026;

-- supprimer les tables avec clés étrangères (itération)
drop table if exists film ;

-- Créer la table distributeur
CREATE TABLE if not exists  distributeur (
    id_distributeur INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR,
    source VARCHAR
);

truncate table distributeur ;


-- insérer les données dans la table distributeur
insert into distributeur 
(nom, source)
SELECT DISTINCT distributeur as nom, 'CNC' as SOURCE
FROM tmp_film_donnees;

-- créer la table classification
CREATE TABLE if not exists  classification (
    id_classification VARCHAR PRIMARY KEY,
    label VARCHAR,
    source VARCHAR
);

truncate table classification ;

-- insérer les données dans la table classification
insert into classification
(id_classification, label, source)
select distinct classification, 
-- utilisation d'une condition pour créer le label à partir du code CNC
case 
	when classification='TP' then 'Tout public'
	when classification='TPA' then 'Tout public accompagné'
	when classification='12' then 'Interdit aux moins de 12 ans'
	when classification='12A' then 'Interdit aux moins de 12 ans non accompagnés'
	when classification='16' then 'Interdit aux moins de 16 ans'
	when classification='16A' then 'Interdit aux moins de 16 ans non accompagnés'
	when classification='18' then 'Interdit aux moins de 18 ans'
else null end as label,
'CNC' as SOURCE from tmp_film_donnees;

-- créer la table genre
CREATE TABLE if not exists  genre (
    id_genre INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label VARCHAR,
    source VARCHAR
);

truncate table genre ;

-- insérer les données dans la table genre
insert into genre 
(label, source) 
select distinct genre, 'CNC' as source
from tmp_film_donnees ;

-- créer la table nationalité
CREATE TABLE if not exists  nationalite (
    id_nationalite INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label VARCHAR,
    source VARCHAR
);

truncate table nationalite ;

-- insérer les données dans la table nationalite
insert into nationalite 
(label, source)
select distinct nationalite as label, 'CNC' as SOURCE
from tmp_film_donnees
where nationalite is not null ;

-- créer la table titre
CREATE TABLE if not exists  titre (
    id_titre INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label VARCHAR,
    type VARCHAR,
    source VARCHAR
);

truncate table titre ;

-- insérer les données dans la table titre
insert into titre 
(label, type, source)
select distinct titre as label, 'Titre' as type, 'CNC' as SOURCE from tmp_film_donnees
union all
-- Utilisation d'une regex pour exclure les titres qui sont en réalité des id wikidata (Q+chiffres)
select distinct film_label  as label, 'Titre' as type, 'Wikidata' as SOURCE from tmp_film_donnees where film_label !~ 'Q[0-9]+' and film_label is not null ;

-- créer la table realisateur
CREATE TABLE if not exists  realisateur (
    id_realisateur INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR,
    source VARCHAR
);

truncate table realisateur ;

-- insérer les données dans la table realisateur
insert into realisateur
(nom, source)
select distinct realisateur, 'Ministère de la Culture' as source from tmp_film_donnees  ;

-- créer la table film 
CREATE TABLE film 
(
    id_film INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_classification VARCHAR REFERENCES classification(id_classification),
    id_distributeur INTEGER references distributeur(id_distributeur),
    id_nationalite INTEGER references nationalite(id_nationalite),
    id_genre INTEGER references genre(id_genre),
    art_et_essai BOOLEAN,
    date_sortie DATE,
    devis INTEGER,
    sortie_etablissement_s1 INTEGER, 
    id_cnc INTEGER,
    id_imdb VARCHAR,
    id_wikidata VARCHAR, 
    id_visa INTEGER
);

truncate film ;

insert into film
(id_classification, art_et_essai, date_sortie, devis, sortie_etablissement_s1, id_cnc, id_imdb, id_wikidata, id_visa)
select distinct
classification,
art_et_essai,
sortie,
devis,
etab_s1,
cnc,
id_imdb,
uri_wikidata,
visa 
from tmp_film_donnees 
where visa is not null;

select * from film ;

-- Marque la fin de ma transaction (script)
COMMIT ;

