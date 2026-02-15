-- Cette vue permet d’identifier les séances relevant du champ social et/ou du handicap
-- L’identification repose sur des marqueurs déclaratifs associés aux groupes accueillis ,
-- sans sur-qualification des publics individuels
begin ;

set search_path to madata_db ;

create  or replace view vw_seances_champ_social_handicap as
	-- Identifiant et caractéristiques temporelles de la séance
	-- Caractéristiques déclaratives des groupes accueillis
	-- Ces champs servent de marqueurs du champ social/handicap
	-- Pour l'analyse le volume d'accueil de publics
	-- Partant de la table séance qui est pour nous le socle de notre analyse nous effectuons trois jointures successives sur les tables  CAPACITE, SEANCE_PUBLICS et GROUPE
select distinct s.id_seance, s.date_seance, s.heure_debut, s.nature_seance, g.nature_client, g.type_client, p2.type_public, c.places_ouvertes, c.places_vendues, c.places_disponibles, c.taux_remplissage from seances s

-- Cette jointure permet d'associer le volumes à chaque séance
left join capacite c
on s.id_seance = c.id_seance

-- La jointure avec les tables de relation SEANCE_PUBLICS et SEANCES_GROUPES nous permettent de matérialiser qu'une séance peut être associée à un ou plusieurs groupe ou publics

left join seances_groupes sg 
on s.id_seance = sg.id_seance

left join seances_publics sp 
on s.id_seance = sp.id_seance

-- Cette jointure lie les informations liées aux types de public

left join publics p2
on p2.id_public = sp.id_public

-- Cette jointure porte les caractéristiques sociales des groupes 

left join groupes g 
on sg.id_groupe = g.id_groupe


 -- Une séance est retenue si et seulement si elle au moins un groupe associé 
 -- un marqueur explicite relevant du champ social ou du handicap

where lower(p2.type_public) like '%handicap%'or lower(g.type_client) like'%social%' or lower(g.nature_client) like '%social%';

-- la vue permet d'identifier les places vendues par mois et par année
-- Elle permet au Service des Publics d'avoir une saisonnière sur ses fréquentations

create or replace view vw_frequentation_mensuelle as 
select 

	-- Il s'agit de faire une extraction et en filtrant à la fois l'année et le mois ( entre 1 à 12) de chaque séance
	-- On identifie et additionnant par la suite le nombre de places vendues et ouvertes  par séance
	-- On aura à la fin le pourcentage moyen de remplissage des séances du mois

	extract (year from s.date_seance) as annee,
	extract(month from s.date_seance) as mois,
	count(distinct s.id_seance) as nb_seance,
	sum(c.places_vendues) as total_places_vendues,
	sum(c.places_ouvertes) as total_places_ouvertes,
	
	-- Ici, on va faire un calcul du taux moyen d'occupation des séances du mois
	
	round(
			case
				when sum(c.places_ouvertes) > 0  -- On evite la division par 0
				then(sum(c.places_vendues)::numeric / sum(c.places_ouvertes)::numeric) * 100
				else null
			end, 2 
			) as taux_remplissage_moyen
from seances s
left join capacite c
on s.id_seance = c.id_seance
group by 1, 2     -- On va faire le regroupement par les deux premières colonnes années et mois
order by 1, 2;    -- On fait le tr du résultat par année puis par mois pour avoir une chronologie. Donc chaque ligne sera égal à un mois dans une année avec le nombre de séances, de places vendues et ouvertes ainsi que le taux moyen 


-- la vue permet de définir l'occupation des salles par différente séance ; voir celles qui ont été sous-utilisées ou sur-utilisées
-- Définir combien de places ont été ouvertes/ vendues 

create or replace view vw_occupation_salles as
select 
	sal.nom_salle,
	
	-- On fait un tri des salles et on garde la somme
	
	count(distinct s.id_seance) as nb_seances,
	sum(c.places_vendues) as total_places_vendues, 
	sum(c.places_ouvertes) as total_places_ouvertes

	-- A travers ces jointures , on relie chaque séances par le nom de la salle ou des salles  dans lesquelles elle a eu lieu
	-- On récupère par la meme occasion le nombre de places ouvertes et vendues, si elle n'a aucune entrée dans la table seances_salles ou capacite, elle apparait quand meme avec des valeurs NULL
	
from seances s
left join seances_salles ss on s.id_seance = ss.id_seance
left join salles sal on ss.id_salle = sal.id_salle
left join capacite c on s.id_seance = c.id_seance

	-- On tri des salles les plus fréquentes aux moins fréquentes

group by sal.nom_salle
order by total_places_vendues desc ;

end;
