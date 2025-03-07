import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Add this import
import 'dart:io';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Box',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF24293E)),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MusicPlayerPage(),
    );
  }
}

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<File> _musicFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadFiles();
  }

  Future<void> _requestPermissionAndLoadFiles() async {
    setState(() => _isLoading = true);
    PermissionStatus status = Platform.isAndroid 
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();

    if (status.isGranted) {
      await _loadMusicFiles();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please grant storage permission in settings'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await openAppSettings();
                if (await Permission.manageExternalStorage.isGranted) {
                  _loadMusicFiles();
                }
              },
            ),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMusicFiles() async {
    try {
      final storageDir = Directory('/storage/emulated/0/Download/');
      if (await storageDir.exists()) {
        var files = storageDir.listSync(recursive: true)
            .where((file) => file.path.toLowerCase().endsWith('.mp3') ||
                file.path.toLowerCase().endsWith('.wav') ||
                file.path.toLowerCase().endsWith('.m4a') ||
                file.path.toLowerCase().endsWith('.aac'))
            .whereType<File>()
            .toSet()
            .toList();

        if (mounted) {
          setState(() => _musicFiles = files);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading files: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(File file, int index) async {
    try {
      await file.delete();
      setState(() {
        _musicFiles.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF24293E),
      appBar: AppBar(
        title: const Text('Music Box'),
        backgroundColor: Color(0xFF24293E),
        foregroundColor: Color(0xFFF4F5FC),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _musicFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off, size: 80, color: Color(0xFF24293E)),
                      const SizedBox(height: 20),
                      Text(
                        'No music found yet!',
                        style: TextStyle(fontSize: 20, color: Color(0xFFF4F5FC)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _musicFiles.length,
                  itemBuilder: (context, index) {
                    final file = _musicFiles[index];
                    final fileName = file.path.split('/').last;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF24293E).withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF24293E),
                          child: Icon(Icons.music_note, color: Color(0xFFCCCCCC)),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(file.path.split('/Download/').last),
                        // trailing: IconButton(
                        //   icon: const Icon(Icons.delete, color: Colors.red),
                        //   onPressed: () async {
                        //     final confirm = await showDialog(
                        //       context: context,
                        //       builder: (context) => AlertDialog(
                        //         title: const Text('Delete Track'),
                        //         content: Text('Remove "$fileName" from your device?'),
                        //         actions: [
                        //           TextButton(
                        //             onPressed: () => Navigator.pop(context, false),
                        //             child: const Text('Cancel'),
                        //           ),
                        //           TextButton(
                        //             onPressed: () => Navigator.pop(context, true),
                        //             child: const Text('Delete'),
                        //           ),
                        //         ],
                        //       ),
                        //     );
                        //     if (confirm == true) {
                        //       _deleteFile(file, index);
                        //     }
                        //   },
                        // ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                musicFiles: _musicFiles,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 110, 112, 120),
        onPressed: _requestPermissionAndLoadFiles,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final List<File> musicFiles;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.musicFiles,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late int _currentIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initPlayer();
    _playMusic();
  }

  void _initPlayer() {
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((event) => _playNext());
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _playMusic() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(widget.musicFiles[_currentIndex].path));
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing music: $e')),
      );
    }
  }

  void _playPauseMusic() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.resume();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing music: $e')),
      );
    }
  }

  void _playNext() {
    if (_currentIndex < widget.musicFiles.length - 1) {
      setState(() {
        _currentIndex++;
        _position = Duration.zero;
      });
      _playMusic();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _position = Duration.zero;
      });
      _playMusic();
    }
  }

  void _shareMusic() async {
    try {
      // Convert File to XFile
      final xFile = XFile(widget.musicFiles[_currentIndex].path);
      await Share.shareXFiles(
        [xFile],
        text: 'Check out this music: ${widget.musicFiles[_currentIndex].path.split('/').last}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing music: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.musicFiles[_currentIndex].path.split('/').last;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24293E)!, Color(0xFFCCCCCC)!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFF4F5FC)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Playing from your library',
                        style: TextStyle(
                          color: Color(0xFFF4F5FC),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Color(0xFFF4F5FC)),
                      onPressed: _shareMusic,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _isPlaying
                                  ? _animationController.value * 2 * math.pi
                                  : 0,
                              child: Container(
                                height: 230,
                                width: 230,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF24293E).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 180,
                                      width: 180,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF24293E),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.music_note,
                                      size: 100,
                                      color: Color.fromARGB(255, 110, 112, 120),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4F5FC),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.musicFiles[_currentIndex].path.split('/Download/').last,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFF4F5FC),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 40),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Slider(
                            activeColor: Color(0xFFF4F5FC),
                            inactiveColor: Colors.white24,
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) async {
                              final position = Duration(seconds: value.toInt());
                              await _audioPlayer.seek(position);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(color: Color(0xFFF4F5FC)),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(color: Color(0xFFF4F5FC)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: _currentIndex > 0 ? 1.0 : 0.8,
                              child: IconButton(
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 40,
                                color: Color(0xFFF4F5FC),
                                onPressed: _currentIndex > 0 ? _playPrevious : null,
                              ),
                            ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: 1.0,
                              child: IconButton(
                                icon: const Icon(Icons.replay_10),
                                iconSize: 40,
                                color: Color(0xFFF4F5FC),
                                onPressed: () => _audioPlayer.seek(
                                  _position - const Duration(seconds: 10),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF4F5FC),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF24293E).withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 50,
                                  color: Color(0xFF24293E),
                                ),
                                onPressed: _playPauseMusic,
                              ),
                            ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: 1.0,
                              child: IconButton(
                                icon: const Icon(Icons.forward_10),
                                iconSize: 40,
                                color: Color(0xFFF4F5FC),
                                onPressed: () => _audioPlayer.seek(
                                  _position + const Duration(seconds: 10),
                                ),
                              ),
                            ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: _currentIndex < widget.musicFiles.length - 1 ? 1.0 : 0.8,
                              child: IconButton(
                                icon: const Icon(Icons.skip_next),
                                iconSize: 40,
                                color: Color(0xFFF4F5FC),
                                onPressed: _currentIndex < widget.musicFiles.length - 1
                                    ? _playNext
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}