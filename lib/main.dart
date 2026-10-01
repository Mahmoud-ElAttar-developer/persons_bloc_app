import 'dart:convert';
import 'dart:io';
import 'dart:math' as devtools;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persons_bloc_app/bloc/bloc_actions.dart';
import 'package:persons_bloc_app/bloc/person.dart';
import 'package:persons_bloc_app/bloc/person_bloc.dart';

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





Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));




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
                      const LoadPersonsAction(url: persons1Url, loader: getPersons),
                    );
                  },
                  child: const Text('Load json #1',style: TextStyle(color: Colors.blue)),
                ), // TextButton
                TextButton(
                  onPressed: () {
                    context.read<PersonsBloc>().add(
                      const LoadPersonsAction(url: persons2Url, loader: getPersons),
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
