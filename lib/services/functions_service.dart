import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> callFunction(
      String functionName, Map<String, dynamic> data) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(functionName);
      await callable.call(data);
    } catch (e) {
      throw Exception('Failed to call function $functionName: $e');
    }
  }
}
