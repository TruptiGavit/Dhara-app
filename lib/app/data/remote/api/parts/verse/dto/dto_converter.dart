import 'dart:convert';
import 'dart:developer';

import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_foot.dart';
import 'package:dharak_flutter/app/types/verse/verse_head.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';

class VerseDtoConverter {
  static VersesResultRM parseResponse(String rawResponse) {
    List<VerseRM> parsedVerses = [];
    VerseHeadRM? parsedHead; // = [];
    VerseFootRM? parsedFoot; // = [];

    // Split response into lines
    List<String> lines = rawResponse.trim().split("\n");

    for (var line in lines) {
      Map<String, dynamic>? jsonMap;
      try {
        jsonMap = jsonDecode(line);
      } catch (e) {}
      try {
        if (jsonMap == null || jsonMap.isEmpty) continue;
        
        final dataType = jsonMap["data_type"];
        print("line: ${dataType}");

        if (dataType == null || dataType is! String) continue;

        switch (dataType as String) {
          case "head":
            parsedHead = VerseHeadRM.fromJson(jsonMap);
            break;
          case "verse":
            parsedVerses.add(VerseRM.fromJson(jsonMap));
            break;
          case "foot":
            parsedFoot = VerseFootRM.fromJson(jsonMap);
            break;
          case "info":
            // Handle new info type from v2 API - just log it for now
            print("Info data type received: $jsonMap");
            break;
          default:
            print("Unknown data type: $dataType");
        }
      } catch (e) {
        inspect(jsonMap);
        print("JSON Parsing Error: ${e}");
        // print("${jsonMap}")
      }
    }

    return VersesResultRM(
      foot: parsedFoot,
      head: parsedHead,
      verses: parsedVerses,
    );
  }

  static Map<String, dynamic>? parseResponseJson(String rawResponseLine) {
    
    
      Map<String, dynamic>? jsonMap;
      try {
        jsonMap = jsonDecode(rawResponseLine);
      } catch (e) {}
     return jsonMap;

  }
}
