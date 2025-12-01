# MysticCards Codebase Documentation

This document provides a comprehensive overview of the MysticCards game architecture, scripts, and functionality.

---

## Table of Contents

1. [Game Overview](#game-overview)
2. [Project Structure](#project-structure)
3. [Autoloads (Singletons)](#autoloads-singletons)
4. [Core Scripts](#core-scripts)
5. [Scene Scripts](#scene-scripts)
6. [Visual Effects](#visual-effects)
7. [Multiplayer Architecture](#multiplayer-architecture)
8. [Game Flow](#game-flow)
9. [Card System](#card-system)
10. [Win Conditions](#win-conditions)

---

## Game Overview

MysticCards is a card game built in Godot 4.5 where players compete to achieve one of two win conditions:
- **5 of the same card type** on their field
- **1 of each of the 5 card types** on their field

The game supports:
- Single-player vs AI
- LAN multiplayer (direct connection)
- Online multiplayer (via Nakama server)

---

## Project Structure

```
MysticCards/
├── addons/
│   └── com.heroiclabs.nakama/     # Nakama Godot addon
├── nakama/
│   └── docker-compose.yml         # Local Nakama server config
├── scenes/
│   ├── Card.tscn                  # Card prefab
│   ├── LightningEffect.tscn       # Lightning visual effect
│   ├── Main.tscn                  # Main game scene
│   └── TitleScreen.tscn           # Title/menu scene
├── scripts/
│   ├── AI.gd                      # AI opponent logic
│   ├── BlockedOverlay.gd          # Blocked card visual
│   ├── Card.gd                    # Card behavior & visuals
│   ├── CardAnimations.gd          # Card animation effects
│   ├── EffectAnimations.gd        # Effect animations
│   ├── GameManager.gd             # Core game state (autoload)
│   ├── LightningEffect.gd         # Lightning bolt rendering
│   ├── Main.gd                    # Main game UI controller
│   ├── NakamaManager.gd           # Online multiplayer (autoload)
│   ├── NetworkManager.gd          # Network abstraction (autoload)
│   ├── SettingsManager.gd         # User settings (autoload)
│   ├── ShatterEffect.gd           # Card destruction effect
│   └── TitleScreen.gd             # Title screen controller
├── DEPLOYMENT.md                  # Server deployment guide
├── CODEBASE.md                    # This file
└── project.godot                  # Godot project file
```

---

## Autoloads (Singletons)

These scripts are loaded automatically and accessible globally. Load order matters!

### 1. Nakama (`addons/com.heroiclabs.nakama/Nakama.gd`)
- **Purpose**: Core Nakama addon functionality
- **Access**: `Nakama` or `/root/Nakama`
- **Usage**: Creates Nakama clients and sockets

### 2. SettingsManager (`scripts/SettingsManager.gd`)
- **Purpose**: Manages user preferences
- **Access**: `SettingsManager`
- **Features**:
  - Theme selection (Classic, Pixel, Elegant, Neon, Nature)
  - Animation toggle
  - Card visual styles
- **Signals**:
  - `settings_changed` - Emitted when settings update

### 3. NakamaManager (`scripts/NakamaManager.gd`)
- **Purpose**: Handles all Nakama server communication
- **Access**: `NakamaManager` or `/root/NakamaManager`
- **Features**:
  - Device authentication
  - Socket connection
  - Matchmaking
  - Real-time match communication
- **Key Signals**:
  - `authenticated` / `authentication_failed(error)`
  - `socket_connected` / `socket_closed`
  - `matchmaking_started` / `matchmaking_cancelled`
  - `match_found(match_id)` / `match_joined(match_data)`
  - `player_joined(presence)` / `player_left(presence)`
  - `match_state_received(op_code, data, sender_id)`
- **Op Codes** (message types):
  ```gdscript
  enum OpCode {
      GAME_START = 1,
      CARD_PLAY = 2,
      REACTION = 3,
      EFFECT_CHOICE = 4,
      CHAT = 5,
      REMATCH_REQUEST = 6,
      PLAYER_INFO = 7
  }
  ```

### 4. NetworkManager (`scripts/NetworkManager.gd`)
- **Purpose**: Abstraction layer for LAN and Online multiplayer
- **Access**: `NetworkManager`
- **Modes**:
  ```gdscript
  enum NetworkMode { NONE, LAN, ONLINE }
  ```
- **Features**:
  - Routes game actions to correct network backend
  - Handles ENet (LAN) and Nakama (Online) connections
  - Manages game start synchronization
  - Rematch system
- **Key Signals**:
  - `connection_succeeded` / `connection_failed`
  - `game_started`
  - `opponent_played_card(card_type)`
  - `opponent_reacted(did_react)`
  - `opponent_effect_choice(choice_data)`
  - `rematch_requested` / `rematch_accepted`

### 5. GameManager (`scripts/GameManager.gd`)
- **Purpose**: Core game logic and state management
- **Access**: `GameManager`
- **Features**:
  - Turn management
  - Card playing and effects
  - Reaction/blocking system
  - Win condition checking
  - Multiplayer game synchronization

### 6. AI (`scripts/AI.gd`)
- **Purpose**: AI opponent decision making
- **Access**: `AI`
- **Features**:
  - Card selection strategy
  - Blocking decisions
  - Effect targeting (Fire, Grass, Water)

---

## Core Scripts

### GameManager.gd

The heart of the game logic.

#### Card Types
```gdscript
enum CardType { FIRE, GRASS, LIGHTNING, DARKNESS, WATER }
```

#### Game States
```gdscript
enum GameState { 
    SETUP,
    PLAYER_TURN_DRAW,
    PLAYER_TURN_PLAY,
    PLAYER_EFFECT,
    AI_TURN_DRAW,
    AI_TURN_PLAY,
    AI_EFFECT,
    OPPONENT_TURN,      # Multiplayer: waiting for remote player
    REACTION_WINDOW,
    GAME_OVER
}
```

#### Key Data Arrays
```gdscript
var player_deck: Array[CardType] = []
var player_hand: Array[CardType] = []
var player_field: Array[CardType] = []
var player_discard: Array[CardType] = []

var ai_deck: Array[CardType] = []      # Also opponent's deck in multiplayer
var ai_hand: Array[CardType] = []      # Also opponent's hand in multiplayer
var ai_field: Array[CardType] = []
var ai_discard: Array[CardType] = []
```

#### Key Signals
```gdscript
signal game_state_changed(new_state: GameState)
signal hand_updated(is_player: bool)
signal field_updated(is_player: bool)
signal deck_updated(is_player: bool)
signal discard_updated(is_player: bool)
signal message_updated(text: String)
signal reaction_window_started(card_played: CardType, is_player_reacting: bool)
signal reaction_window_ended
signal game_over(player_won: bool)
signal effect_target_needed(effect_type: String)
signal card_played(card_type: CardType, is_player: bool)
signal card_resolved(card_type: CardType, is_player: bool)
signal card_blocked(card_type: CardType, is_player: bool, blocker_is_player: bool)
```

#### Key Functions
- `start_game()` - Initialize single-player game
- `start_multiplayer_game(...)` - Initialize multiplayer with seeds
- `player_play_card(hand_index)` - Play a card from hand
- `start_reaction_window(card, is_player_reacting)` - Open block opportunity
- `player_react()` / `player_pass_reaction()` - Handle blocking
- `execute_reaction(is_player)` - Process a block
- `resolve_card()` - Execute card effect after reaction window
- `execute_effect(card, is_player)` - Run card-specific effect
- `check_win_condition(is_player)` - Check for victory

---

### NetworkManager.gd

Abstracts networking for both LAN and Online play.

#### Key Functions (LAN)
```gdscript
func host_game(player_name, port) -> Error
func join_game(player_name, ip, port) -> Error
```

#### Key Functions (Online)
```gdscript
func start_online_multiplayer(player_name) -> bool      # Quick Match
func create_online_match(player_name) -> bool           # Create Room
func join_online_match(player_name, match_id) -> bool   # Join Room
```

#### Broadcasting Functions
```gdscript
func broadcast_card_play(card_type: int)
func broadcast_reaction(did_react: bool)
func broadcast_effect_choice(choice_data: Dictionary)
func request_rematch()
```

---

### AI.gd

Implements AI opponent logic.

#### Key Functions
- `play_turn()` - Main AI turn execution
- `choose_best_card()` - Select optimal card to play
- `evaluate_card(card, field)` - Score a card's value
- `decide_reaction(card, chain_depth)` - Decide whether to block
- `is_threatening_card(card)` - Check if card is worth blocking
- `choose_fire_target()` - Select card to destroy
- `choose_grass_target()` - Select card to retrieve from discard
- `decide_water_effect()` - Decide whether to use Water effect

---

## Scene Scripts

### Main.gd

Controls the main game scene UI.

#### Responsibilities
- Renders cards in hands, fields, decks, discards
- Handles user input (clicking cards, buttons)
- Manages reaction timer and panel
- Shows effect choice dialogs
- Displays game log
- Animates card effects

#### Key State
```gdscript
var reaction_timer: float = 0.0
var reaction_active: bool = false
var current_effect: String = ""  # "fire", "grass", "water"
```

#### Card Display Functions
```gdscript
func refresh_player_hand()
func refresh_ai_hand()
func refresh_player_field()
func refresh_ai_field()
func create_card_stack(cards, type, is_player) -> Control
```

---

### TitleScreen.gd

Controls the title/menu screen.

#### Menu Options
- Single Player - Start game vs AI
- Multiplayer - Opens multiplayer panel
  - Quick Match (Online) - Nakama matchmaking
  - Create Online Room - Host a Nakama match
  - Join Online Room - Join with match ID
  - Host LAN Game - ENet server
  - Join LAN Game - ENet client
- Settings - Theme and animation options
- Quit - Exit game

---

### Card.gd

Individual card behavior and rendering.

#### Properties
```gdscript
@export var card_type: GameManager.CardType
@export var face_up: bool = true
@export var clickable: bool = false
@export var highlighted: bool = false
@export var on_field: bool = false      # Enables passive animations
@export var draggable: bool = false     # Enable drag and drop
```

#### Features
- Visual styling based on theme
- Passive particle animations per card type
- Hover and click feedback
- Drag and drop support
- Glow/highlight effects

#### Passive Animations (when on field)
- **Fire**: Rising flame particles
- **Water**: Floating bubbles
- **Grass**: Drifting leaves
- **Darkness**: Orbiting dark orbs
- **Lightning**: Electric bolts along edges

---

## Visual Effects

### CardAnimations.gd
- Card play animations
- Card resolve/success effects
- Card block animations

### EffectAnimations.gd
- Fire destruction effect
- Grass retrieval effect
- Lightning draw effect
- Darkness discard effect

### ShatterEffect.gd
- Card shatter/destruction particles

### LightningEffect.gd
- Animated lightning bolt between points

### BlockedOverlay.gd
- Visual overlay for blocked cards

---

## Multiplayer Architecture

### Connection Flow (Online)

```
1. Player clicks "Quick Match"
2. TitleScreen calls NetworkManager.start_online_multiplayer()
3. NetworkManager calls NakamaManager.authenticate_device()
4. NakamaManager authenticates with server
5. NetworkManager calls NakamaManager.connect_socket()
6. NakamaManager opens WebSocket connection
7. NetworkManager calls NakamaManager.start_matchmaking()
8. When match found, NakamaManager emits match_joined
9. Host sends GAME_START message with deck seeds
10. Both clients call GameManager.start_multiplayer_game()
```

### Message Flow (During Game)

```
Player plays card:
1. GameManager.player_play_card() broadcasts via NetworkManager
2. NetworkManager.broadcast_card_play() sends via NakamaManager
3. NakamaManager.send_card_play() sends OpCode.CARD_PLAY
4. Opponent receives via _on_nakama_match_state_received
5. NetworkManager emits opponent_played_card signal
6. GameManager._on_opponent_played_card() processes the play
```

### Deck Synchronization

Both players use seeded random number generators:
```gdscript
func start_multiplayer_game(host_deck_seed, client_deck_seed, host_goes_first, is_local_host):
    if is_local_host:
        player_deck = create_deck_with_seed(host_deck_seed)
        ai_deck = create_deck_with_seed(client_deck_seed)
    else:
        player_deck = create_deck_with_seed(client_deck_seed)
        ai_deck = create_deck_with_seed(host_deck_seed)
```

---

## Game Flow

### Single Player Turn
```
1. PLAYER_TURN_DRAW: Player draws a card (except first turn if going first)
2. PLAYER_TURN_PLAY: Player clicks a card to play
3. Card is placed on field, REACTION_WINDOW opens for AI
4. AI decides to block or pass (5 second timer)
5. If blocked, player can counter-block (reaction chain)
6. Card resolves or is discarded
7. PLAYER_EFFECT: If card resolved, execute its effect
8. Check win conditions
9. AI_TURN begins
```

### Card Effects
- **Fire**: Destroy one card from opponent's field
- **Grass**: Retrieve one card from your discard pile to hand
- **Lightning**: Draw 2 additional cards
- **Darkness**: Opponent discards a random card
- **Water**: Look at top deck card, optionally move to bottom

### Blocking System
- Block with: Water + matching card type
- Counter-block with: 2 Water cards
- Maximum reaction chain depth: 5
- Reaction timer: 5 seconds

---

## Win Conditions

```gdscript
func check_win_condition(is_player: bool) -> bool:
    var field = player_field if is_player else ai_field
    
    # Win condition 1: 5 of the same type
    var type_counts = {}
    for card in field:
        type_counts[card] = type_counts.get(card, 0) + 1
        if type_counts[card] >= 5:
            return true  # Winner!
    
    # Win condition 2: 1 of each type (5 unique)
    var unique_types = {}
    for card in field:
        unique_types[card] = true
    if unique_types.size() >= 5:
        return true  # Winner!
    
    return false
```

---

## Configuration

### Server Configuration (NakamaManager.gd)

```gdscript
# Production (Oracle Cloud)
var server_host: String = "mysticcards.duckdns.org"
var server_port: int = 443
var server_scheme: String = "https"
var socket_scheme: String = "wss"

# Local Development (Docker)
var server_host: String = "127.0.0.1"
var server_port: int = 7350
var server_scheme: String = "http"
var socket_scheme: String = "ws"
```

### Theme Settings (SettingsManager.gd)

Available themes: Classic, Pixel, Elegant, Neon, Nature

Each theme defines:
- Background colors
- Accent colors
- Card corner radius
- Card border width
- Card styling effects

---

## Common Modifications

### Adding a New Card Type
1. Add to `GameManager.CardType` enum
2. Add to `CARD_NAMES`, `CARD_COLORS`, `CARD_SYMBOLS`
3. Implement effect in `execute_effect()`
4. Add AI logic in `AI.gd`
5. Add passive animation in `Card.gd`

### Adding a New Theme
1. Add theme to `SettingsManager.THEMES` dictionary
2. Define colors: background, accent, card style properties
3. Theme will automatically apply to cards and UI

### Modifying Win Conditions
Edit `GameManager.check_win_condition()` function

### Adjusting AI Difficulty
Modify scoring in `AI.evaluate_card()` and decision thresholds in `AI.decide_reaction()`


