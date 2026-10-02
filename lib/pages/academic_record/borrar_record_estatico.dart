// lib/pages/academic_record/borrar_record_estatico.dart
//
// «Borrar mi récord de ULima++» en el Perfil de la versión estática
// (specs/features/modo-estatico/modo-estatico.spec.md, RF-EST-10). El récord
// queda oculto, pero la copia que el alumno importó de miUlima sigue en el
// servidor, y RF-REC-5 le da derecho a borrarla cuando quiera. Llama a
// `DELETE /academic-record/me` sin mostrar el récord ni volver a pedirlo, y no
// registra `AcademicRecordService`.

import 'package:flutter/material.dart';

import '../../services/academic_record_service.dart';
import 'academic_record_page.dart';

class BorrarRecordEstatico extends StatefulWidget {
  const BorrarRecordEstatico({super.key, this.servicio});

  /// Solo para pruebas. Sin él, una instancia propia que no se registra en GetX.
  final AcademicRecordService? servicio;

  static const Key botonKey = Key('perfil-borrar-record');
  static const String dialogoCuerpo =
      'Se borra la copia de tu récord guardada en ULima++. Tu malla no cambia.';
  static const String avisoBorrado = 'Tu récord se borró de ULima++.';

  @override
  State<BorrarRecordEstatico> createState() => _BorrarRecordEstaticoState();
}

class _BorrarRecordEstaticoState extends State<BorrarRecordEstatico> {
  bool _borrando = false;

  Future<void> _confirmarYBorrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AcademicRecordPage.deleteDialogTitle),
        content: const Text(BorrarRecordEstatico.dialogoCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AcademicRecordPage.deleteCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AcademicRecordPage.deleteConfirmLabel,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _borrando = true);
    String aviso = BorrarRecordEstatico.avisoBorrado;
    try {
      await (widget.servicio ?? AcademicRecordService()).deleteRecord(
        recargar: false,
      );
    } on AcademicRecordFailure catch (e) {
      aviso = e.message;
    }
    if (!mounted) return;
    setState(() => _borrando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton.icon(
        key: BorrarRecordEstatico.botonKey,
        onPressed: _borrando ? null : _confirmarYBorrar,
        icon: const Icon(Icons.delete_outline),
        label: const Text(AcademicRecordPage.deleteButtonLabel),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
