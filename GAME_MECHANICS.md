# Battle Arena - Game Mechanics Guide

## Overview
This is a 2-player battle arena game where players can only defeat each other by hitting them from behind.

## Controls

### Player 1
- **A** - Move Left
- **D** - Move Right
- **W** - Jump
- **F** - Attack

### Player 2
- **J** - Move Left
- **L** - Move Right
- **I** - Jump
- **H** - Attack

## Game Mechanics

### Back-Hit System
The core mechanic of the game is the **back-hit system**:
- Each player has a regular hitbox (in front) and a "back area" (behind them)
- When Player 1 attacks (presses F), they trigger a hit animation
- **Player 2 only dies if Player 1's hitbox overlaps with Player 2's back area**
- This means players must position themselves to hit their opponent from behind
- The same applies vice versa for Player 2 attacking Player 1

### Combat Flow
1. Position yourself behind your opponent
2. Press your attack button (F for Player 1, H for Player 2)
3. If you hit their back area, they are eliminated and you win
4. The winner menu will appear showing which player won

## Game Flow

### Main Menu
- **PLAY** - Start a new game
- **SELECT SKINS** - Choose player colors before playing
- **QUIT** - Exit the game

### Skin Selection Menu
- Choose from 8 different colors for each player
- Click on a color button to select it
- Available colors: Red, Blue, Green, Yellow, Orange, Purple, Cyan, White
- **BACK** button returns to main menu

### During Gameplay
- **ESC** or **Pause Button** - Opens the pause menu
- Attack animations play when you press your attack button
- Players can freely move and jump

### Pause Menu
- **RESUME** - Continue the game
- **MAIN MENU** - Return to main menu (loses current game)
- **QUIT** - Exit the game

### Winner Menu
- Shows which player won the game
- **PLAY AGAIN** - Restart the game
- **MAIN MENU** - Return to main menu
- **QUIT** - Exit the game

## Technical Details

### Hit Detection
- Both players have two collision areas:
  - **Hitbox** - The attack area in front of the player
  - **Backarea** - The vulnerable area behind the player
- The attack function checks if the attacker's hitbox overlaps with the opponent's backarea
- Only then is the opponent eliminated

### Skin System
- Skins are stored in the GameManager singleton
- When a player spawns, their sprite color is set based on the selected skin
- Colors are applied to the AnimatedSprite2D's modulate property
- Default color is white if no skin is selected

### Game Manager
- Global singleton that manages:
  - Game pausing/resuming
  - Player skin selections
  - Game over state and winner determination
- Persists across scene changes
- Handles communication between game scenes and menu scenes

## Files Structure

### Scripts
- `game_manager.gd` - Global game state and signals
- `game_controller.gd` - Game scene setup and initialization
- `player_1.gd` - Player 1 logic (movement, attack, animations)
- `player_2.gd` - Player 2 logic (movement, attack, animations)
- `main_menu.gd` - Main menu UI handling
- `pause_menu.gd` - Pause menu UI handling
- `winner_menu.gd` - Winner menu UI handling
- `skin_menu.gd` - Skin selection UI handling

### Scenes
- `main_menu.tscn` - Main menu UI
- `game.tscn` - Main game scene with both players and ground
- `player_1.tscn` - Player 1 character
- `player_2.tscn` - Player 2 character
- `pause_menu.tscn` - Pause menu overlay
- `winner_menu.tscn` - Winner screen overlay
- `skin_menu.tscn` - Skin selection screen

## Tips for Playing

1. **Positioning** - Stay behind your opponent to guarantee a hit
2. **Movement** - Use the ground level to your advantage
3. **Timing** - Watch your opponent's position before attacking
4. **Strategy** - Try to circle around your opponent to get behind them

## Future Enhancements (Ideas)

- Multiple rounds/best of 3 system
- Health system instead of one-hit elimination
- Different attack patterns and combos
- Power-ups and special abilities
- Sound effects and music
- More varied maps
- Netplay/online multiplayer
