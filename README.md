# MaData - projet d'analyse des données du MAD

Ce dépôt est un fork du dépôt TNAH_FILM_DB ([GitHub - LauryneL/TNAH_FILM_DB: Generate a database from data bulk](https://github.com/LauryneL/TNAH_FILM_DB)). IL a été réalisé dans le cadre d'un projet de groupe du M2 TNAH de l'École nationale des Chartes par Léticia Mvogo, Charline Emiry, Neïla Hamoudi et Arthur Douilly, lesquels sont responsables de la création des scripts SQL et de l'anonymisation des données.

**Le crédit pour la réalisation des scripts et du dépôt GitHub originel revient à Maxime CHALLON et Lauryne LEMOSQUET. Les données de la base appartiennent au MAD.**

### Étapes à suivre pour créer et remplir la base de données

1. Création d'un environnement virtuel venv au sein de ce dossier, à côté de run.py et de `requirements.txt`. Activation de la base avec `source {nom_env}/bin/activate`. Ni les scripts, ni les modules n'ont étés changés par rapport au dépôt original.

2. Installation des modules nécessaires avec pip install -r requirements.txt

3. Modification du fichier .env avec les éléments suivants : 
   
   - `"madata"` comme nom de Database Postgresql ;
   
   - `"madata_db"` comme nom de schéma ;
   
   - Indiquer le port postgresql dans pgPort ;
   
   - Indiquer le host dans pgHost.
   
   ```env
   pgDatabase="madata"
   pgUser=str
   pgPassword=str
   pgPort=int
   pgHost=str
   pgSchemaImportsCsv="madata_db"
   failOnFirstSqlError=True
   failOnFirstCsvError=True
   ```

4. Création de la base de données et du schéma avec les requêtes suivantes :
   Créer une nouvelle base de données (crédit : Lauryne Lemosquet) :
   
   ```sql
   CREATE DATABASE madata ;
   ```
   
   Créer un nouveau schéma :
   
   ```sql
   CREATE SCHEMA madata_db ;
   ```

5. Lancer le script principal depuis le terminal avec `python run.py` ou `python3 run.py`.

Au terme de ces étapes, la base de données et les vues associées à celle-ci seront chargées dans la session postgresql correspondante. Celle-ci devrait correspondre au modèle logique joint nommé `madata_modèle_logique_final.png`.
