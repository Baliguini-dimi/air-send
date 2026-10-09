# Audit Air Send ? suivi s?curit? et robustesse

## R?solution du lot ? 8 octobre 2026

### A4 ? Capacit?s NFC affich?es sans d?tection ? r?solu

`nfcCapabilitiesProvider` interroge s?par?ment `canPresentNfc()` et `canReadNfc()`. `ScanScreen` n'affiche que les actions effectivement disponibles. Si une capacit? manque, l'?cran l'indique avec une piste de v?rification des r?glages syst?me; QR reste propos?.

### S1 ? HCE accessible ?cran verrouill? et r?ponse APDU persistante ? r?solu

`android:requireDeviceUnlock` vaut `true` dans `android/app/src/main/res/xml/apduservice.xml`. `AndroidHceExchangeService.cancel()` retire la r?ponse APDU. `ScanScreen.dispose()` annule la session lorsqu'on quitte l'?cran, y compris par retour arri?re. Un compteur de g?n?ration retire une r?ponse dont l'installation aurait fini apr?s l'annulation.

### S2 ? Injection de formules CSV ? r?solu

Les champs du contact issu du scan (nom, poste, entreprise, t?l?phone et email) sont pr?fix?s par une apostrophe quand la valeur commence par `=`, `+`, `-` ou `@`. Le test du service v?rifie les quatre pr?fixes, notamment le cas `=1+1`.

### S3 ? Export CSV conserv? dans le cache ? r?solu

Le fichier est supprim? dans un `finally` apr?s la fin ou l'annulation de la feuille de partage `share_plus`. Si la suppression ?choue, le prochain export supprime les CSV Air Send de plus de cinq minutes dans le r?pertoire temporaire.

### S6 ? Payload sans version ni limite ? r?solu

Le JSON NFC ?met `v: 1`; l'absence de version reste accept?e comme format historique v1 et toute version inconnue est rejet?e. `decode()` rejette un champ texte de plus de 200 caract?res ou un JSON d?passant 2 048 octets UTF-8. Les choix sont d?taill?s dans `docs/DATA_MODEL.md`.

## V?rification sur appareil

`adb devices -l` ne signale aucun appareil connect? dans cette session. La pr?sentation puis lecture NFC ?cran verrouill?, et l'inspection du CSV via une feuille de partage r?elle, restent ? confirmer physiquement; les tests automatis?s couvrent les r?gles de donn?es.
