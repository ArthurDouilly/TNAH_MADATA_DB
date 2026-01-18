-- Marque le début de ma transaction (début du script)
BEGIN ;

-- Toujours utiliser le même schéma. !!ATTENTION!! si vous ne le configurez pas, vous serez obligé de préciser {nom_schema}.{nom_table} pour chaque requête ! Le nom dus schéma ici doit être le même que dans le fichier .env du script python
SET search_path TO film_fr_2026;

-- créer la table de relation film_titre 
create table if not exists film_titre 
(
	id_film INTEGER references film(id_film),
	id_titre INTEGER references titre(id_titre)
);

-- créer la table de relation film_realisateur
create table if not exists film_realisateur 
(
	id_film INTEGER references film(id_film),
	id_realisateur INTEGER references realisateur(id_realisateur)
);

-- insérer les données titre (source: CNC) 
truncate film_titre ;

insert into film_titre
(id_film, id_titre)
select a.id_film, c.id_titre
from film a 
inner join tmp_film_donnees b on a.id_visa = b.visa 
inner join titre c on b.titre = c.label 
where c.source='CNC' ;

-- insérer les données titre (source: Wikidata) 
insert into film_titre
(id_film, id_titre)
select a.id_film, c.id_titre
from film a 
inner join tmp_film_donnees b on a.id_visa = b.visa 
inner join titre c on b.titre = c.label 
where c.source='wikidata' ;

truncate film_realisateur ; 

-- insérer les données de relation film_realisateur 
insert into film_realisateur 
(id_film, id_realisateur)
select a.id_film, c.id_realisateur 
from film a 
inner join tmp_film_donnees b on a.id_visa = b.visa 
inner join realisateur c on b.realisateur = c.nom ;

-- Marque la fin de la transaction (script)
COMMIT ;
