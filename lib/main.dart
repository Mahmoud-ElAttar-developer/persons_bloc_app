import 'dart:convert';
import 'dart:io';
import 'dart:math' as devtools;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension Log on Object {
  void log() => devtools.log(toString() as num);
}

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(create: (_) => PersonsBloc(), child: const MainApp()),
    ),
  );
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

enum PersonUrl { person1, person2 }

@immutable
class LoadPersonsAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonsAction({required this.url}) : super();
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.person1:
        return 'http://127.0.0.1:5500/api/person1.json'; // تم تصحيح الرقم لـ 1 واستخدام الـ IP الخاص بك
      case PersonUrl.person2:
        return 'http://127.0.0.1:5500/api/person2.json'; // تم تصحيح الرقم لـ 2 واستخدام الـ IP الخاص بك
    }
  }
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});
  Person.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      age = json['age'] as int;
      @override
      String toString() => 'Person (name = $name, age = $age)';
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult({
    required this.persons,
    required this.isRetrievedFromCache,
  });
  @override
  String toString() =>
      'FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons)';
}

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  // الخريطة (Map) المستخدمة للتخزين المؤقت لمنع جلب البيانات المكررة
  final Map<PersonUrl, Iterable<Person>> _cache = {};

  PersonsBloc() : super(null) {
    on<LoadPersonsAction>((event, emit) async {
      final url = event.url;

      // 1. التحقق مما إذا كانت البيانات موجودة مسبقاً في الـ Cache
      if (_cache.containsKey(url)) {
        // جلب القيمة المخزنة
        final cachedPersons = _cache[url]!;

        // إنشاء النتيجة وتحديد أنها مسترجعة من الـ Cache
        final result = FetchResult(
          persons: cachedPersons,
          isRetrievedFromCache: true,
        );

        // بث (Emit) الحالة الجديدة للمستمعين
        emit(result);
      } else {
        // 2. إذا لم تكن موجودة، يتم جلبها من الإنترنت باستخدام رابط الـ URL الممرر
        final persons = await getPersons(url.urlString);

        // حفظ البيانات الجديدة داخل الـ Cache للمرات القادمة
        _cache[url] = persons;

        // إنشاء النتيجة وتحديد أنها محملة حديثاً وليست من الـ Cache
        final result = FetchResult(
          persons: persons,
          isRetrievedFromCache: false,
        );

        // بث (Emit) الحالة الجديدة للمستمعين
        emit(result);
      }
    });
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Persons Bloc App'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.read<PersonsBloc>().add(
                      const LoadPersonsAction(url: PersonUrl.person1),
                    );
                  },
                  child: const Text('Load json #1',style: TextStyle(color: Colors.blue)),
                ), // TextButton
                TextButton(
                  onPressed: () {
                    context.read<PersonsBloc>().add(
                      const LoadPersonsAction(url: PersonUrl.person2),
                    );
                  },
                  child: const Text('Load json #2',style: TextStyle(color: Colors.blue)),
                ), // TextButton
              ],
            ), // Row
            BlocBuilder<PersonsBloc, FetchResult?>(
              buildWhen: (previousResult, currentResult) {
                return previousResult?.persons != currentResult?.persons;
              },
              builder: (context, fetchResult) {
                fetchResult?.log();
                final persons = fetchResult?.persons;
                if (persons == null) {
                  return const SizedBox();
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      // هنا تم استخدام الـ Subscript Extension الذي كتبناه لجلب العنصر بأمان
                      final person = persons[index]!;
                      return ListTile(
                        title: Text(person.name),
                        subtitle: Text('${person.age} years old'),
                      ); // ListTile
                    },
                  ), // ListView.builder
                ); // Expanded
              },
            ), // BlocBuilder
          ],
        ), // Column
      ),
    );
  }
}
