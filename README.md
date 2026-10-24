# 🎮 ARVR Multiplayer 3D Avatar Lab

An interactive, high-performance 3D multiplayer lab developed in **Godot Engine 4.x**. The project features real-time networked avatars, procedural animations, physics-driven interactions, ladder climbing, dynamic shape pickup/carrying systems, checkpoint validation gates, shape collection baskets, and an authoritative live scoreboard.

---

## 🌟 Key Features

- **🌐 Dedicated Peer-to-Peer / Client-Server Architecture**
  - Built with Godot's high-level multiplayer API (`ENetMultiplayerPeer`, `MultiplayerSpawner`, and `MultiplayerSynchronizer`).
  - Supports up to 16 concurrent peers over low-latency UDP (default port: `8910`).
  - Instant multi-client testing with one-click Player 2 and Player 3 sub-process spawning directly from the UI.

- **🧍 8 Playable 3D Avatars & Customization**
  - Choose between 8 distinct characters: *Cyber Runner, Knight Paladin, Ninja Shadow, Cosmic Astronaut, Urban Brawler, Tech Scientist, Ranger Scout, Mystic Mage*.
  - 8 distinct skin color palettes: *Blue, Red, Green, Yellow, Purple, Orange, Cyan, White*.
  - Configurable player nicknames and workstation/PC serial tags (`PC-01`, `PC-02`, etc.).
  - Dynamic 3D overhead nameplates displaying player name, workstation serial, connection role, carrying status, and score.

- **📦 Interactive Physics & Gameplay Tasks**
  - **Task 1 — Shape Depot & Carrying**: Pick up 3D geometric shapes (*Cube, Sphere, Cone, Cuboid, Star*) using `[E]` or the on-screen HUD button. Includes procedural pickup motions and chest anchoring.
  - **Task 2 — Checkpoint Arch**: Navigate through the illuminated checkpoint gate while carrying a shape to earn checkpoint points (+1 pt). Equipped with shuttle-loop anti-exploit logic to prevent duplicate scoring.
  - **Task 3 — Shape Collection Basket**: Deposit carried shapes into the central collection basket for deposit points (+1 pt). Real-time inventory tracking and dynamic 3D billboard counters.
  - **Task 4 — Vertical Ladder System**: Smooth ladder attachment, directional climbing physics, and automatic ledge dismounting.

- **📊 Live Real-Time Scoreboard & HUD**
  - Press `[Tab]` to toggle an authoritative real-time scoreboard.
  - Tracks player nickname, serial number, selected avatar, individual stopwatch timer, checkpoint gate score, detailed basket breakdown by shape type, and total points.
  - TopBar HUD with live match timer, personal score badge, online peer counter, fullscreen toggle, and quick disconnect button.

---

## 🕹️ Controls & Keybindings

| Action | Primary Key | Secondary Key | Description |
| :--- | :--- | :--- | :--- |
| **Move Forward / Backward** | `W` / `S` | `Up` / `Down` Arrow | Walk in camera-relative direction |
| **Move Left / Right** | `A` / `D` | `Left` / `Right` Arrow | Strafe left or right |
| **Sprint** | `Shift` | — | Run at increased speed (9.5 m/s) |
| **Jump** | `Space` | — | Jump or climb up ladders |
| **Look / Aim** | `Mouse` | — | 360° third-person orbit camera |
| **Interact (Pickup / Deposit)** | `E` | `F` / `Enter` | Pick up shapes or deposit into basket |
| **Toggle Scoreboard** | `Tab` | HUD Toggle Button | Open/close authoritative match table |
| **Toggle Mouse Cursor** | `Esc` | — | Release/capture cursor to interact with HUD |
| **Toggle Fullscreen** | `F11` | `Alt + Enter` | Switch between fullscreen and windowed |

---

## 🚀 How to Run the Project

### Prerequisites
- **[Godot Engine 4.x](https://godotengine.org/download/)** (Standard 64-bit version 4.2, 4.3, or later).

---

### Method 1: Running from the Godot Editor

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/alexnikshith/ARVR_Multiplayer.git
   cd ARVR_Multiplayer
   ```

2. **Open in Godot**:
   - Open Godot Engine Project Manager.
   - Click **Import**.
   - Browse to the cloned directory, select `project.godot`, and click **Import & Edit**.

3. **Run the Game**:
   - Press **`F5`** (or click the **Play** button in the top-right corner).
   - The main scene (`res://scenes/main.tscn`) will launch.

---

### Method 2: Multi-Player Testing on a Single Machine (One-Click)

The project includes built-in multi-instance launchers for fast local testing:

1. **Launch Window 1 (Host)**:
   - Run the game from Godot or launch the project.
   - In the lobby UI, select **Preset 1 (Player 1)** and click **HOST GAME**.
2. **Spawn Player 2 & 3 Automatically**:
   - In either the lobby UI (bottom tools bar) or in-game HUD (top right), click:
     - **`🚀 Launch Window 2 (P2)`**: Automatically launches a 2nd window with `player2` preconfigured, connects to `127.0.0.1:8910`, and spawns the player into the arena.
     - **`🚀 Launch Window 3 (P3)`**: Launches a 3rd window with `player3` preconfigured and joins automatically.
3. You can also configure Godot's built-in multiple instances via:
   - `Debug` -> `Customize Run Instances...` -> Set **Number of Instances** to `2` or `3`.

---

### Method 3: Multiplayer Across Local Network (LAN)

1. **Host Computer**:
   - Launch the game.
   - Enter your nickname and select your avatar.
   - Click **HOST GAME** (default port `8910`).
   - Find your local IP address (e.g. `192.168.1.X` via `ipconfig` on Windows or `ifconfig` on macOS/Linux).
   - Ensure UDP port `8910` is permitted through the host machine's firewall.

2. **Client Computer(s)**:
   - Launch the game on the other computer(s) connected to the same Wi-Fi/LAN.
   - Enter a distinct nickname, skin, and serial ID.
   - Replace `127.0.0.1` with the **Host's Local IP address**.
   - Click **JOIN GAME**.

---

## 📁 Repository Structure

```text
ARVR_Multiplayer/
├── assets/                          # 3D assets, textures, and humanoid models
│   ├── Bestiary - Dungeon Monsters Kit/
│   │   └── Exports/GLB/            # Imp and Puglin 3D character models
│   └── characters/                  # Astronaut, Knight, Ninja, Robot, Archer, Dwarf
├── scenes/                          # Godot scene files (.tscn)
│   ├── arena.tscn                   # 3D stadium, lighting, obstacles, spawn points
│   ├── basket.tscn                  # Shape deposit receptacle & 3D billboard
│   ├── checkpoint_arch.tscn         # Illuminated checkpoint gate with detection area
│   ├── ladder.tscn                  # Interactive climbing ladder with top dismount
│   ├── main.tscn                    # Root scene: Lobby UI, HUD, MultiplayerSpawner
│   ├── pickable_shape.tscn          # Geometric pickable shapes (Cube, Sphere, Cone, etc.)
│   └── player.tscn                  # 3D CharacterBody3D, CameraPivot, Sync nodes
├── scripts/                         # GDScript logic files (.gd)
│   ├── basket.gd                    # Collection basket state, counting & network sync
│   ├── checkpoint_arch.gd           # Checkpoint trigger logic & flash effects
│   ├── humanoid_avatar.gd           # Procedural animations, bone rigs & mesh handling
│   ├── ladder.gd                    # Ladder area enter/exit triggers
│   ├── main.gd                      # Network management, lobby UI, RPCs & scoreboard
│   ├── pickable_shape.gd            # Floating depot idle, pickup & drop mechanics
│   └── player.gd                    # Authority movement, camera orbit, ladder climbing, tasks
├── test_gameplay_tasks.gd           # Automated headless integration tests for all 3 tasks
├── verify_physics_and_air.gd        # Automated physics stability & grounding verifier
├── project.godot                    # Godot 4.x engine configuration
├── .gitignore                       # Excludes .godot cache and build artifacts
└── README.md                        # Documentation and project manual
```

---

## 🧪 Automated Testing Scripts

You can execute the built-in headless verification suites via Godot command line:

- **Gameplay & Tasks Verification**:
  ```bash
  godot --headless -s test_gameplay_tasks.gd
  ```
  *Tests shape pickup, checkpoint passage (+1 pt), duplicate crossing prevention, and basket deposit (+1 pt).*

- **Physics & Grounding Verification**:
  ```bash
  godot --headless -s verify_physics_and_air.gd
  ```
  *Validates multi-player spawn physics, collision layers, and ensures avatars remain grounded without floating.*

---

## 📜 License & Credits

Developed for academic and lab coursework in **Augmented & Virtual Reality (AR/VR)**.
- **Engine**: [Godot Engine 4.x](https://godotengine.org) (MIT License)
- **3D Assets**: Kay Lousberg (KayKit Dungeon Monsters & Character Packs)
