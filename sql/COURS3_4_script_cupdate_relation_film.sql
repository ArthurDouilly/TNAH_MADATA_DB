-- Marque le début de ma transaction (début du script)
BEGIN ;

-- Toujours utiliser le même schéma. !!ATTENTION!! si vous ne le configurez pas, vous serez obligé de préciser {nom_schema}.{nom_table} pour chaque requête ! Le nom dus schéma ici doit être le même que dans le fichier .env du script python
SET search_path TO film_fr_2026;

-- update id_distributeur 
update film 
set id_distributeur = b.id_distributeur
from tmp_film_donnees a 
inner join distributeur b on a.distributeur = b.nom 
where film.id_visa = a.visa ;

-- update id_nationalite
update film 
set id_nationalite = b.id_nationalite
from tmp_film_donnees a 
inner join nationalite b on a.nationalite = b."label" 
where film.id_visa = a.visa ;

-- update id_genre
update film 
set id_genre = b.id_genre
from tmp_film_donnees a 
inner join genre b on a.genre = b."label" 
where film.id_visa = a.visa ;

-- Marque la fin de ma transaction (fin du script)
COMMIT ;
