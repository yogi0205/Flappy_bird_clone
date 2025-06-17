import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flappy Bird Game",
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF87CEEB)),
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/images/ground.png',
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/bottom.png',
              width: MediaQuery.of(context).size.width,
              height: 150,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/bird.png',
              width: 34,
              height: 24,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Flappy Bird",
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 66, 153, 188),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameWidget(
                            game: FlappyBirdGame(),
                            overlayBuilderMap: {
                              'gameOver': (context, game) =>
                                  GameOverMenu(game as FlappyBirdGame),
                              'pauseButton': (context, game) =>
                                  PauseButton(game as FlappyBirdGame),
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text("Start Game"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverMenu extends StatelessWidget {
  final FlappyBirdGame game;
  const GameOverMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Game Over",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: ${game.score}',
                style: const TextStyle(
                  fontSize: 35,
                  color: Colors.white,
                ),
              ),
              Text(
                'High Score: ${game.highScore}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 66, 153, 188),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  game.resetGame();
                  game.overlays.remove('gameOver');
                },
                child: const Text("Play Again"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromARGB(255, 66, 153, 188),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PauseButton extends StatelessWidget {
  final FlappyBirdGame game;
  const PauseButton(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 55,
      right: 15,
      child: IconButton(
        onPressed: () {
          if (game.isPaused) {
            game.resumeEngine();
            game.isPaused = false;
          } else {
            game.pauseEngine();
            game.isPaused = true;
          }
        },
        icon: Icon(
          game.isPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class Bird extends SpriteComponent with HasGameRef<FlappyBirdGame> {
  double velocity = 0;
  Bird() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bird.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    velocity += gameRef.gravity * dt;
    position.y += velocity * dt;

    if (position.y < 0) {
      position.y = 0;
      velocity = 0;
    }
  }

  void jump() {
    velocity = -gameRef.jumpForce;
  }
}

class Pipe extends SpriteComponent with HasGameRef<FlappyBirdGame> {
  final bool isBottom;
  bool passed = false;
  Pipe({required this.isBottom}) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(isBottom ? 'pipe_bottom.png' : 'pipe_top.png');
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver || gameRef.isPaused) return;

    super.update(dt);
    position.x -= gameRef.pipeSpeed * dt;

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  bool checkCollision(Bird bird) {
    final birdRect = bird.toRect();
    final pipeRect = toRect();
    return birdRect.overlaps(pipeRect);
  }
}

class Ground extends SpriteComponent with HasGameRef<FlappyBirdGame> {
  Ground({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bottom.png');
  }

  @override
  void update(double dt) {
    if (gameRef.isGameOver || gameRef.isPaused) return;

    super.update(dt);
    position.x -= gameRef.pipeSpeed * dt;

    if (position.x < -size.x) {
      position.x += size.x * 2;
    }
  }
}

class FlappyBirdGame extends FlameGame with TapDetector {
  late Bird bird;
  late SpriteComponent background;
  late Ground ground;
  late TextComponent scoreText;
  late TextComponent scoreLabel;
  late SharedPreferences prefs;
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isPaused = false;
  final double gravity = 800;
  final double jumpForce = 300;
  double pipeSpeed = 100;
  final double pipeSpawnTime = 2.5;
  double timeSinceLastPipe = 0;
  final random = Random();

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;

    await images.loadAll([
      'ground.png',
      'bottom.png',
      'bird.png',
      'pipe_bottom.png',
      'pipe_top.png',
    ]);

    background = SpriteComponent()
      ..sprite = await loadSprite('ground.png')
      ..size = size
      ..anchor = Anchor.topLeft;
    add(background);

    ground = Ground(
      position: Vector2(0, size.y - 150),
      size: Vector2(size.x, 150),
    );
    add(ground);

    Ground ground2 = Ground(
      position: Vector2(size.x, size.y - 150),
      size: Vector2(size.x, 150),
    );
    add(ground2);

    bird = Bird()
      ..position = Vector2(size.x * 0.25, size.y * 0.45)
      ..size = Vector2(43, 24);
    add(bird);

    scoreLabel = TextComponent(
      text: 'Score',
      position: Vector2(size.x / 2.2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreLabel);

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 1.5, 82),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    overlays.add('pauseButton');
  }

  @override
  void update(double dt) {
    if (isGameOver || isPaused) return;
    super.update(dt);

    timeSinceLastPipe += dt;
    if (timeSinceLastPipe >= pipeSpawnTime) {
      _spawnPipes();
      timeSinceLastPipe = 0;
    }

    // Check for collisions
    for (final pipe in children.whereType<Pipe>()) {
      if (pipe.checkCollision(bird)) {
        _gameOver();
        break;
      }

      // Increase score if bird passes pipe
      if (!pipe.passed && pipe.position.x + pipe.size.x / 2 < bird.position.x - bird.size.x / 2) {
        pipe.passed = true;
        if (pipe.isBottom) {
          score++;
          scoreText.text = score.toString();
          FlameAudio.play('score.wav');
          if (score > highScore) {
            highScore = score;
            prefs.setInt('highScore', highScore);
          }
        }
      }
    }

    // Check ground collision
    if (bird.position.y + bird.size.y / 2 >= size.y - 150) {
      _gameOver();
    }
  }

  void _spawnPipes() {
  const double gap = 130;
  const double pipeHeight = 320;

  final centerY = random.nextDouble() * (size.y - gap - 300) + 150;

  final pipeTop = Pipe(isBottom: false)
    ..position = Vector2(size.x + 50, centerY - gap / 2 - pipeHeight / 2)
    ..size = Vector2(52, pipeHeight);
  add(pipeTop);

  final pipeBottom = Pipe(isBottom: true)
    ..position = Vector2(size.x + 50, centerY + gap / 2 + pipeHeight / 2)
    ..size = Vector2(52, pipeHeight);
  add(pipeBottom);
}

  @override
  void onTap() {
    if (!isGameOver && !isPaused) {
      bird.jump();
      FlameAudio.play('flap.wav');
    } else if (isGameOver) {
      resetGame();
    }
  }

  void _gameOver() {
    if (!isGameOver) {
      FlameAudio.play('hit.wav');
      isGameOver = true;
      pauseEngine();
      overlays.add('gameOver');
      overlays.remove('pauseButton');
    }
  }

  void resetGame() {
    score = 0;
    scoreText.text = '0';
    isGameOver = false;
    isPaused = false;
    bird.position = Vector2(size.x * 0.25, size.y * 0.45);
    bird.velocity = 0;

    // Remove all pipes
    children.whereType<Pipe>().forEach((pipe) => pipe.removeFromParent());

    resumeEngine();
    overlays.add('pauseButton');
    overlays.remove('gameOver');
  }
}
