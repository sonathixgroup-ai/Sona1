import 'package:flutter/material.dart';
const kNavyDeep = Color(0xFF0A1F44);
const kAccent = Color(0xFF2D6CDF);
const kGold = Color(0xFFE3B23C);

class UploadProgress extends StatelessWidget {
  final double progress; // 0.0 à 1.0
  final String fileName;
  final String status;
  const UploadProgress({super.key, required this.progress, required this.fileName, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.cloud_upload_rounded, size: 16, color: kAccent),
          SizedBox(width: 8),
          Expanded(child: Text(fileName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kNavyDeep), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${(progress*100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kAccent)),
        ]),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, backgroundColor: Color(0xFFE7EEFC), valueColor: AlwaysStoppedAnimation(kAccent), minHeight: 6),
        ),
        SizedBox(height: 6),
        Text(status, style: TextStyle(fontSize: 10, color: Color(0xFF7386A8))),
      ]),
    );
  }
}
