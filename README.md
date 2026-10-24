# 💰 Budget – App iPhone Native (Swift / SwiftUI / SwiftData)

Application iPhone native de suivi de budget personnel à l'extrême simplicité.
Son unique mission : répondre en un coup d'œil à la question **« Combien puis-je encore dépenser sans compromettre mon objectif d'épargne ? »**

---

## ⚡ Principes Clés

- **Simplicité extrême** : aucun artifice, aucune complexité superflue.
- **Saisie ultra-rapide** : enregistrement d'une dépense en 2 ou 3 taps via clavier numérique dédié et grille de catégories.
- **Multi-devises EUR & SEK** : bascule directe `€ / kr`, taux de conversion fixe personnalisable (par défaut `1 € = 11,12 SEK`), aucun appel réseau.
- **Calculs purs et rigoureux** : calculs 100% monétaires avec `Decimal` (jamais de `Double`).
- **100% Local & Privé** : SwiftData (iOS 17+), pas de compte, pas de tracking, pas de backend ni de connexion bancaire.

---

## 📐 Modèle de Calculs

Tous les calculs s'opèrent dans la devise de référence (par défaut EUR pour compte N26) :

$$\text{Budget variable} = \text{Salaire} - \text{Épargne} - \text{Fixes} - \text{Lissées} - \text{Tampon}$$

$$\text{Reste à dépenser} = \text{Budget variable} - \text{Dépenses variables du cycle}$$

$$\text{Par jour} = \frac{\text{Reste à dépenser}}{\text{Jours restants (aujourd'hui compris)}}$$

$$\text{Solde projeté} = \text{Solde initial} + \text{Revenus} - \text{Dépenses réelles}$$

- Si le **Reste à dépenser** devient négatif, il s'affiche en rouge avec le montant du dépassement.
- Les catégories plafonnées affichent une barre de progression dynamique (verte < 80%, orange 80-100%, rouge > 100%).

---

## 📅 Logique du Cycle Budgétaire

- Un cycle s'étend du **jour de paie** au jour précédant la prochaine paie (ex: paie le 25 $\rightarrow$ cycle du 25 octobre au 24 novembre inclus).
- Gestion automatique des fins de mois courts et des mois sans 31e jour (ex: 31 février $\rightarrow$ 28 ou 29 février).
- Option **« Démarrer le nouveau cycle aujourd'hui »** pour adapter le cycle si la paie est versée en avance (week-end ou jour férié).

---

## 🏗 Architecture & Code

- **SwiftUI + SwiftData** (iOS 17.0+)
- **Services Purs & XCTest** : `BudgetCalculator` avec couverture complète des tests de cycles, bissextiles, conversion EUR/SEK et dépassements.
- **Sauvegarde locale** : Export et Import complets au format JSON.

---

## 🚀 Compilation & Signature (GitHub Actions)

Le projet utilise **XcodeGen** (`project.yml`) et compile via GitHub Actions (`.github/workflows/build.yml`) avec le profil de développement Apple :
- **Team ID** : `A63WD37CXZ`
- **Profil** : `Victor Lamache Dev Profile` (`com.victorlamache.*`)
- **Bundle ID** : `com.victorlamache.budgetdev`
- **Artifact généré** : `Budget.ipa` téléchargeable directement après chaque commit.
