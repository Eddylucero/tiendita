import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  final ImagePicker _picker = ImagePicker();

  // SELECCIONAR Y GUARDAR IMAGEN
  Future<String?> seleccionarYGuardarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (imagen == null) return null;

    final directorioApp = await getApplicationDocumentsDirectory();

    final directorioImagenes = Directory(
      p.join(directorioApp.path, 'productos'),
    );

    if (!await directorioImagenes.exists()) {
      await directorioImagenes.create(recursive: true);
    }

    final extension = p.extension(imagen.path).toLowerCase();

    final nombreArchivo = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final rutaDestino = p.join(directorioImagenes.path, nombreArchivo);

    final archivo = await File(imagen.path).copy(rutaDestino);

    return archivo.path;
  }

  // ELIMINAR IMAGEN GUARDADA
  Future<void> eliminarImagen(String? ruta) async {
    if (ruta == null || ruta.isEmpty) return;

    final directorioApp = await getApplicationDocumentsDirectory();

    final directorioProductos = p.normalize(
      p.join(directorioApp.path, 'productos'),
    );

    final rutaNormalizada = p.normalize(ruta);

    // Solo permitir eliminar imágenes de productos.
    if (!p.isWithin(directorioProductos, rutaNormalizada)) {
      return;
    }

    final archivo = File(rutaNormalizada);

    if (await archivo.exists()) {
      await archivo.delete();
    }
  }
}
