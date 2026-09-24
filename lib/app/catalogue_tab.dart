import 'package:flutter/material.dart';
import 'package:serviceflow/doc/doc_list.dart';

/// The Doc List tab — the catalogue of documents and their prices.
///
/// Both roles reach it and both can add to it; only the CEO can change or
/// remove an existing item.
class CatalogueTab extends StatelessWidget {
  const CatalogueTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: DocListView(),
    );
  }
}
