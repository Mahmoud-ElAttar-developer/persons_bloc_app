import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persons_bloc_app/bloc/bloc_actions.dart';
import 'package:persons_bloc_app/bloc/person.dart';

extension IsEqualToIgnoringOrdering<T> on Iterable<T> {
  bool isEqualToIgnoringOrdering(Iterable<T> other) =>
      length == other.length &&
      {...this}.intersection({...other}).length == length;
}

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

  @override
  bool operator ==(covariant FetchResult other) =>
      persons.isEqualToIgnoringOrdering(other.persons) &&
      isRetrievedFromCache == other.isRetrievedFromCache;

  @override
  int get hashCode => Object.hash(persons, isRetrievedFromCache);
}

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  // الخريطة (Map) المستخدمة للتخزين المؤقت لمنع جلب البيانات المكررة
  final Map<String, Iterable<Person>> _cache = {};

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
        final loader = event.loader;
        // 2. إذا لم تكن موجودة، يتم جلبها من الإنترنت باستخدام رابط الـ URL الممرر
        final persons = await loader(url);

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
