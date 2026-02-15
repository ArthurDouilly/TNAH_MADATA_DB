-- SCRIPT DE SUPPRESSION DES TABLES TEMPORAIRES
-- dernier script, chargé de supprimer les tables temporaires afin de nettoyer la base de données
-- il ne doit rester que les tables finales après l'exécution de ce script !

begin ;

set search_path to madata_db ;

-- la suppression des tables est assurée par le biais d'un 'drop table'
-- le 'if exists' est une mesure de sécurité ici, utile pour la répétition du travail sur la base de données

drop table if exists activites_sdp ; -- suppression du csv

drop table if exists billets_vendus_forfaits ; -- suppression du csv

drop table if exists tmp_billets_vendus ; -- suppression de tmp_billets_vendus

drop table if exists tmp_activites_sdp ; -- suppression de tmp_activites_sdp

drop table if exists tmp_mad_donnees ; -- suppression de tmp_mad_donnees

drop table if exists wikidata_mdf ; -- suppression de wikidata_mdf

drop table if exists frequentation_mdf ; -- suppression de frequentation_mdf

drop table if exists TMP_WIKIDATA_MDF ; -- suppression de TMP_WIKIDATA_MDF

drop table if exists TMP_FREQUENTATION_MDF ; -- suppression de TMP_FREQUENTATION_MDF

drop table if exists TMP_DONNEES_EXTERNES ; -- suppression de TMP_DONNEES_EXTERNES

commit ;