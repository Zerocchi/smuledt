#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main(List<String> args) {

  load(); // load env

  String link = args[0];
  linkParser(link);
}

// Collab class
class Collab {
  String url;
  String description;
  String imageUrl;
}

Collab collabParser(doc) {
  List<Element> metas = doc.getElementsByTagName("meta");
  Collab collab = new Collab();
  //TODO: Refactor this later
  metas.forEach((meta) {
    if(meta.attributes['name'] == "twitter:player:stream") collab.url = meta.attributes['content'].replaceAll('amp;','');
    if(meta.attributes['name'] == "twitter:description") collab.description = meta.attributes['content'].replaceAll('/', ' ').split("on Sing")[0].trim();
    if(meta.attributes['name'] == "twitter:image:src") collab.imageUrl = meta.attributes['content'];
  });
  return collab;
}

linkParser(String link) async {
  print("Parsing the link");
  http.read(link).then((res) {
    var doc = parse(res);
    var collab = collabParser(doc);
    var collabUrl = collab.url;
    var collabDesc = collab.description;
    var collabTitle = titleParser(collabDesc);
    var collabImg = collab.imageUrl;
    print("Downloading: $collabTitle");
    //mediaDownloader(collabUrl, collabDesc);
    getMedia(collabUrl, collabTitle);
  });
}

titleParser(String description) {
  String info = description.split('on Smule')[0];
  String title = info.split('recorded by')[0].trim();
  String singers = info.split('recorded by')[1].replaceAll('and', '&').trim();
  return "${title} (${singers})";
}

@deprecated
Future mediaDownloader(String link, title) async {
  try {
    HttpClientRequest client = await new HttpClient().getUrl(Uri.parse(link));
    HttpClientResponse res = await client.close();
    File file = new File(title);
    Future writing = await res.pipe(file.openWrite());
  } catch (Exception) {
    // later
  }
}

void getMedia(String link, String title) {
  var data = http.readBytes(link);
  data.then((buffer) {
    // TODO: Check if folder exists
    File file = new File("${env['DL_DEFAULT']}/$title.mp4");
    RandomAccessFile rf = file.openSync(mode: FileMode.write);
    rf.writeFromSync(buffer);
    rf.flushSync();
    rf.closeSync();
    print("Downloaded!");
  });
}