import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:persons_bloc_app/bloc/bloc_actions.dart';
import 'package:persons_bloc_app/bloc/person.dart';
import 'package:persons_bloc_app/bloc/person_bloc.dart';

const mockedPersons1 = [
  Person(age: 20, name: 'Foo'),
  Person(age: 30, name: 'Bar'),
];

const mockedPersons2 = [Person(age: 25, name: 'Baz')];

Future<Iterable<Person>> mockGetPersons1(String _) =>
    Future.value(mockedPersons1);

Future<Iterable<Person>> mockGetPersons2(String _) =>
    Future.value(mockedPersons2);

void main() {
  group('Testing bloc', () {
    // تعريف متغير الـ Bloc الذي سنستخدمه في الاختبارات
    late PersonsBloc bloc;

    // يتم تشغيل هذه الدالة قبل كل اختبار لتصفية الـ Bloc وبدء حالة جديدة نظيفة
    setUp(() {
      bloc = PersonsBloc();
    });

    // الاختبار الأول: التحقق من الحالة الابتدائية للـ Bloc (يجب أن تكون null)
    // الاختبار الثاني: جلب البيانات لأول مرة واختبار الكاش عند تكرار الطلب
    blocTest<PersonsBloc, FetchResult?>(
      'Mock retrieving persons from first iterable',
      build: () => bloc,
      verify: (bloc) => (bloc.state != null),
      act: (bloc) {
        // المرة الأولى: جلب من الـ loader
        bloc.add(
          LoadPersonsAction(
            url: 'dummy_Url_1', // استخدمنا الـ enum الذي عرفناه سابقاً
            loader: mockGetPersons1,
          ),
        );
        // المرة الثانية: تكرار الطلب لنفس الرابط للتأكد من تشغيل الكاش
        bloc.add(
          LoadPersonsAction(url: 'dummy_Url_1', loader: mockGetPersons1),
        );
      },
      expect: () => [
        const FetchResult(persons: mockedPersons1, isRetrievedFromCache: false),
        const FetchResult(persons: mockedPersons1, isRetrievedFromCache: true),
      ],
      // هنا المحاضر سيضيف جزء الـ expect والـ verify في الثواني القادمة ليتحقق من النتيجة المتوقعة
    );
  });
}
