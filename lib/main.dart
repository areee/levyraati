import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YoutubeApp());
}

class YoutubeApp extends StatelessWidget {
  const YoutubeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Levyraati',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      debugShowCheckedModeBanner: false,
      home: const YoutubeAppDemo(),
    );
  }
}

class YoutubeAppDemo extends StatefulWidget {
  const YoutubeAppDemo({Key? key}) : super(key: key);

  @override
  _YoutubeAppDemoState createState() => _YoutubeAppDemoState();
}

class _YoutubeAppDemoState extends State<YoutubeAppDemo> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'TicGJQqrq2M',
      params: const YoutubePlayerParams(
        privacyEnhanced: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const player = YoutubePlayerIFrame();
    return YoutubePlayerControllerProvider(
      // Passing controller to widgets below.
      controller: _controller,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            print('constraints.maxWidth: ${constraints.maxWidth}');
            if (kIsWeb && constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: player),
                  SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Controls(),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              children: [
                Stack(
                  children: [
                    player,
                    Positioned.fill(
                      child: YoutubeValueBuilder(
                        controller: _controller,
                        builder: (context, value) {
                          return AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Material(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      YoutubePlayerController.getThumbnail(
                                        videoId:
                                            _controller.params.playlist.first,
                                        quality: ThumbnailQuality.medium,
                                      ),
                                    ),
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                            crossFadeState: value.isReady
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Controls(),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

class Controls extends StatelessWidget {
  const Controls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 10),
          MetaDataSection(),
          SizedBox(height: 10),
          SourceInputSection(),
        ],
      ),
    );
  }
}

class MetaDataSection extends StatelessWidget {
  const MetaDataSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      buildWhen: (o, n) => o.metaData != n.metaData,
      builder: (context, value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${value.metaData.title}'),
          ],
        );
      },
    );
  }
}

class SourceInputSection extends StatefulWidget {
  const SourceInputSection({Key? key}) : super(key: key);

  @override
  _SourceInputSectionState createState() => _SourceInputSectionState();
}

class _SourceInputSectionState extends State<SourceInputSection> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      builder: (context, value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              enabled: value.isReady,
              controller: _textController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter youtube <video id> or <link>',
                fillColor: Theme.of(context).primaryColor.withAlpha(20),
                filled: true,
                hintStyle: const TextStyle(fontWeight: FontWeight.w300),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _textController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            MaterialButton(
              color: Theme.of(context).primaryColor,
              onPressed: () {
                context.ytController.cue(
                  _cleanId(_textController.text) ?? '',
                );
              },
              child: const Text(
                'CUE',
              ),
            ),
          ],
        );
      },
    );
  }

  String? _cleanId(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return YoutubePlayerController.convertUrlToId(source);
    } else if (source.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid video id',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    return source;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
