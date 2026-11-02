import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../model/ids.dart';
import '../providers/app_providers.dart';

/// A photo of the medicine (the strip or the bottle), so someone who cannot
/// read the name can still tell which one to take. One file per medicine, in
/// the vault folder, so it travels with backups.
File medicinePhotoFile(Directory vault, MedicationCourseId id) =>
    File(p.join(vault.path, 'medicine', '${id.value}.jpg'));

Future<void> saveMedicinePhoto(Directory vault, MedicationCourseId id, File picked) async {
  final target = medicinePhotoFile(vault, id);
  await target.parent.create(recursive: true);
  await picked.copy(target.path);
}

Future<void> deleteMedicinePhoto(Directory vault, MedicationCourseId id) async {
  final f = medicinePhotoFile(vault, id);
  if (await f.exists()) await f.delete();
}

/// The photo if there is one. Invalidate after a change.
final medicinePhotoProvider = FutureProvider.family<File?, MedicationCourseId>((ref, id) async {
  final f = medicinePhotoFile(await ref.watch(vaultDirectoryProvider.future), id);
  return await f.exists() ? f : null;
});
