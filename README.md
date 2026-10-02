# Emoji dans les titres de session Claude Code

Chaque nouvelle session de l'onglet **Code** de Claude Desktop prend un titre qui commence par un emoji lié au sujet : `🧾 Relances factures clients`, `🐛 Bug export CSV`, `📧 Dernier mail fournisseur`.

## 1. Ce que c'est

Claude Desktop génère un titre pour chaque session, mais sans emoji. Dans une barre latérale de 50 sessions, on cherche longtemps. Un emoji par sujet permet de retrouver une session d'un coup d'œil.

Les scripts communautaires d'auto-nommage nomment la session au démarrage, d'après le dossier ou la branche Git. À ce moment-là, vous n'avez encore rien écrit, donc ils ne peuvent pas connaître le sujet. Ce hook attend votre premier message.

## 2. Comment ça marche

```
Premier message de la session
        │
        ▼
Hook UserPromptSubmit (emoji-session-title.sh)
        │  1re fois pour cette session ? et session neuve (pas une reprise) ?
        ▼
Ajoute une consigne au contexte de Claude :
« renomme la session : 1 emoji + 3 à 6 mots »
        │
        ▼
Claude appelle l'outil Desktop set_session_title("self", "📧 …")
        │
        ▼
Le titre remplace celui généré par l'app
```

- **Une seule fois par session :** un fichier témoin par session dans `~/.claude/state/emoji-title/`.
- **Pas de renommage des anciennes sessions :** si le transcript contient déjà un message, la session est une reprise et son titre n'est pas modifié. Les commandes slash (`/model`…) ne comptent pas comme des messages.
- **Pas d'appel API en plus :** c'est Claude, dans la session, qui choisit l'emoji. Il connaît déjà le sujet.

### Limites, à connaître avant d'installer

- **Onglet Code de Claude Desktop uniquement :**
  - L'outil de renommage n'existe que là. Dans le `claude` du terminal, le hook ne fait rien.
  - Les conversations de l'onglet **Chat** tournent sur les serveurs de claude.ai : elles ne lisent pas `settings.json` et n'exécutent pas de hooks. Il n'existe aucun moyen officiel d'automatiser leurs titres.
  - Les sessions Code lancées depuis le téléphone ou claude.ai/code tournent dans le cloud, sans vos hooks locaux.
- **Pas garanti à 100 % :** le hook donne une consigne et c'est Claude qui l'exécute. Il peut l'oublier de temps en temps.
- **Mode plan :** l'appel de renommage déclenche une demande d'autorisation. Le repo compagnon [claude-code-plan-mode-auto-reads](https://github.com/Matthieusabourin2/claude-code-plan-mode-auto-reads) l'approuve automatiquement.
- **Format interne :** la détection des sessions reprises lit le transcript `.jsonl` de Claude Code, dont le format n'est pas documenté. Si le format change, le pire cas est que les anciennes sessions reprises soient renommées.

## 3. Comment l'utiliser

### Prérequis

- Claude Desktop (onglet Code) sur macOS. Sous Windows, il faut bash (Git Bash ou WSL) : non testé.
- `jq` (`brew install jq` sur macOS)

### Installation

```bash
git clone https://github.com/Matthieusabourin2/claude-code-emoji-session-titles.git
cd claude-code-emoji-session-titles
./test.sh      # vérifie le script sur de fausses entrées, sans rien toucher
./install.sh
```

`install.sh` copie le hook dans `~/.claude/hooks/` et l'ajoute à `~/.claude/settings.json`. Le fichier est d'abord sauvegardé en `settings.json.bak-<date>`, et vos autres réglages et hooks restent tels quels. Relancer le script ne crée pas de doublon.

### Vérification

Ouvrez une **nouvelle** session dans l'onglet Code et envoyez un premier message. Le titre de la session doit prendre un emoji dans les secondes qui suivent. Les sessions déjà ouvertes ne sont pas concernées.

### Personnaliser

La consigne se trouve dans `~/.claude/hooks/emoji-session-title.sh`, entre les deux `TXT`. Vous pouvez y changer le nombre de mots, imposer une liste d'emojis, etc.

### Désinstaller

```bash
./uninstall.sh
```

Le script laisse en place les fichiers témoins (`~/.claude/state/emoji-title/`) et les sauvegardes `~/.claude/settings.json.bak-<date>`. Vous pouvez les supprimer à la main.

## Licence

MIT
