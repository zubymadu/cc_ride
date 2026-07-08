import 'package:get_storage/get_storage.dart';

final getData = GetStorage();
save(key, val) {
  final data = GetStorage();
  data.write(key, val);
}
