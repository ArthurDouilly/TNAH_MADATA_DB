-- SCRIPT DE CRÉATION DES TABLES DE RELATIONS
-- ce script assure la création des tables de relations nécessaires aux relations many-to-many
-- ainsi que l'insertion des valeurs liées à ces relations, nécessairement réalisée après la création des tables simples

BEGIN ;

-- path afin de ne pas avoir à noter le schéma à chaque fois que l'on appelle une table
SET search_path TO madata_db ;

-- 1. Création des tables de relations

-- tables seances_publics

CREATE TABLE IF NOT EXISTS SEANCES_PUBLICS (
    id_seance varchar REFERENCES SEANCES(id_seance),
    id_public integer REFERENCES PUBLICS(id_public)
);

-- table seances_groupes

CREATE TABLE IF NOT EXISTS SEANCES_GROUPES (
    id_seance varchar REFERENCES SEANCES(id_seance),
    id_groupe integer REFERENCES GROUPES(id_groupe)
);

-- table billets_publics

CREATE TABLE IF NOT EXISTS BILLETS_PUBLICS (
    id_billet integer REFERENCES BILLETS(id_billet),
    id_public integer REFERENCES PUBLICS(id_public)
);

-- table seances_salles

CREATE TABLE IF NOT EXISTS SEANCES_SALLES (
    id_seance varchar REFERENCES SEANCES(id_seance),
    id_salle integer REFERENCES SALLES(id_salle)
);

-- création de la table expositions_salles
create table if not exists EXPOSITIONS_SALLES(
	id_exposition varchar(10) references expositions(id_exposition),
	id_salle integer references salles(id_salle)
);

-- création de la table bilan_seances
create table if not exists BILAN_SEANCES(
    id_bilan_annuel integer references BILAN_ANNUEL_SDP(id_bilan_annuel),
    id_seance varchar REFERENCES SEANCES(id_seance)
);

-- 2. Insertion des données liées aux relations

-- insertion des données dans seances_publics
TRUNCATE SEANCES_PUBLICS ;

INSERT INTO seances_publics (id_seance, id_public)
SELECT a.id_seance, c.id_public
FROM seances a
INNER JOIN tmp_mad_donnees b ON a.id_seance = b.id_seance_complet
INNER JOIN publics c ON b.type_public = c.type_public ;

-- insertion des données dans seances_groupes
TRUNCATE SEANCES_GROUPES ;

INSERT INTO seances_groupes (id_seance, id_groupe)
SELECT a.id_seance, c.id_groupe
FROM seances a
INNER JOIN tmp_mad_donnees b ON a.id_seance = b.id_seance_complet
INNER JOIN groupes c ON b.reservation = c.reservation ;

-- insertion des données dans billets_publics
TRUNCATE BILLETS_PUBLICS ;

INSERT INTO billets_publics (id_billet, id_public)
SELECT a.id_billet, c.id_public
FROM billets a
INNER JOIN tmp_mad_donnees b ON a.id_seance = b.id_seance_complet  
INNER JOIN publics c ON b.type_public = c.type_public ;

-- insertion des données dans seances_salles
TRUNCATE SEANCES_SALLES ;

INSERT INTO seances_salles (id_seance, id_salle)
SELECT a.id_seance, c.id_salle
FROM seances a
INNER JOIN tmp_mad_donnees b ON a.id_seance = b.id_seance_complet
INNER JOIN salles c ON b.salles = c.nom_salle ;

-- insertion des données dans expositions_salles
TRUNCATE EXPOSITIONS_SALLES ;

INSERT INTO expositions_salles (id_exposition, id_salle)
SELECT a.id_exposition, c.id_salle
FROM expositions a
INNER JOIN tmp_mad_donnees b ON a.nom_exposition = b.exposition
INNER JOIN salles c ON b.salles = c.nom_salle ;

-- insertion des données dans bilan_seances
TRUNCATE BILAN_SEANCES ;

INSERT INTO BILAN_SEANCES (id_bilan_annuel, id_seance)
SELECT ba.id_bilan_annuel, s.id_seance
FROM seances s
INNER JOIN BILAN_ANNUEL_SDP ba ON EXTRACT(YEAR FROM s.date_seance) = ba.annee 
AND ba.id_museofile = 'M5021';

COMMIT ;