import 'package:flutter/material.dart';

class Mood {
  final String name;
  final String imagePath;

  Mood(this.name, this.imagePath);
}

class MoodPickerPage extends StatefulWidget {
  @override
  _MoodPickerPageState createState() => _MoodPickerPageState();
}

class _MoodPickerPageState extends State<MoodPickerPage> {
  final List<Mood> moods = [
    Mood('Sad', 'assets/sad.png'),
    Mood('Inlove', 'assets/inlove.png'),
    Mood('Happy', 'assets/happy.png'),
    Mood('Sleepy', 'assets/sleepy.png'),
    Mood('Surprise', 'assets/surprise.png'),
    // Add more moods here
  ];

  String _selectedMood = '';

  void _setMood(String moodName) {
    Mood selectedMood = moods.firstWhere((mood) => mood.name == moodName);
    Navigator.pop(context, selectedMood); // Return the selected mood
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Your Mood'),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        children: moods.map((mood) {
          return GestureDetector(
            onTap: () => _setMood(mood.name),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedMood == mood.name
                      ? Colors.blue
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    mood.imagePath,
                    height: 60, // Set a fixed height for the image
                  ),
                  SizedBox(height: 8),
                  Text(mood.name),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
