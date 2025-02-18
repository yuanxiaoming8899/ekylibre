# Séquences 

Les séquences permettent de **préciser le format des numéros apparaissant sur les pièces** reçues ou produites par la société.

Le lien <i />{:.icon .icon-load}**Charger** vous permet de créer automatiquement les séquences que vous ne possédez pas ou plus et de les **associer au bon paramètre de configuration** de votre société.

Vous ne pouvez pas supprimer une séquence à partir du moment ou celle-ci est utilisée.


## Composer le format de la séquence 

{:.alert .alert-success}
Pour garantir une lisibilité des numéros, **chaque format de numéro est unique**. Ce qui fait que chaque numéro produit sera unique et il ne sera pas possible de confondre un numéro de facture et un numéro d'achat

Le numéro utilisé dans le format pourra être remis à zéro périodiquement : année, mois ou semaine.

Pour composer le format vous avez 4 mots clés :

* **number** numéro en cours
* **cweek** numéro de la semaine _commerciale_ en cours dans l'année, de 1 à 52 ou 53
* **month** numéro du mois en cours dans l'année, de 1 à 12
* **year** numéro de année en cours, 2008, 2009...

Vous devez les mettre entre crochets pour bien les identifier. De plus, si vous souhaitez compléter les numéros par des zéros vous pouvez spécifier ce paramètre en faisant suivre le mot clé du caractère **|** et du nombre de caractères désiré. Exemple : **NUM[number|12]** pourra donner un chiffre comme **NUM000000000085**.


