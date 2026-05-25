import 'package:file_picker/file_picker.dart';
import 'package:file_picker/_internal/file_picker_web.dart';

void initFilePicker() {
  try {
    FilePickerWeb.registerWith(null as dynamic);
  } catch (e) {
    print('Error registering FilePickerWeb manually: $e');
  }
}
