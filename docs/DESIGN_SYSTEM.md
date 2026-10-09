# Système de design — Air Send

## Direction visuelle

Interface mobile professionnelle, sobre et lisible, construite autour du bleu corporate `#3B6E91`, du fond navy `#0F1B2D`, de surfaces légèrement plus claires et de texte blanc/atténué. Les rôles de couleur du thème Flutter restent la référence pour boutons, focus et états.

## Carte professionnelle — template Contraste

`BusinessCardPreview` est le widget réutilisable pour l’aperçu Profil et le partage QR.

- Fond : accent du profil assombri. Si le contraste du blanc est inférieur à 4,5:1, le fond navy `#0F1B2D` est utilisé.
- Logo : icône dans un disque clair, teintée par l’accent lorsqu’il reste lisible.
- Hiérarchie : nom en titre gras, poste et entreprise secondaires, puis séparateur et coordonnées.
- Les lignes téléphone, WhatsApp, email, LinkedIn et site web sont conditionnelles et les URL longues restent limitées à deux lignes avec ellipse.
- LinkedIn utilise la marque Font Awesome (`FontAwesomeIcons.linkedin`); téléphone, email et web utilisent Material Icons.
- Les identifiants d’icônes sont sélectionnés dans une grille fixe de dix choix, avec sélection annoncée par semantics et accentuée par la couleur du profil.

## QR

Le QR encode un vCard 3.0 standard au lieu du JSON interne. L’affichage QR place l’aperçu de carte avant le code. Le vCard reprend uniquement les champs de contact disponibles; il ne contient pas le logo ou les couleurs graphiques, qui ne font pas partie du format choisi.

## Typographie et adaptation

Les widgets réutilisent les styles `TextTheme` et gardent l’agrandissement système. Les textes secondaires sont atténués sans être masqués. Les mises en page doivent rester défilables sur petits écrans et lorsque le clavier est ouvert.
## Addendum — Coordonnée WhatsApp

La carte professionnelle ajoute une ligne WhatsApp uniquement quand le champ est renseigné, avec l’icône de marque `FontAwesomeIcons.whatsapp`. Le numéro est indépendant du téléphone. Un tap ouvre le lien `https://wa.me/<chiffres>` dans l’application ou le navigateur externe via `url_launcher`; les espaces, signes et autres caractères du numéro sont retirés pour former le chemin WhatsApp.

Dans le formulaire, WhatsApp est prérempli depuis Téléphone. Cette valeur cesse d’être synchronisée dès que l’utilisateur modifie le champ WhatsApp; il peut aussi l’effacer. Un profil existant sans WhatsApp est prérempli avec son téléphone à l’ouverture du formulaire.