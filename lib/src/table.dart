import 'package:web/web.dart' as web;

import 'json.dart';

final class JsonTable {
  final List<String> columns;
  final List<List<Object?>> rows;

  JsonTable(Map<String, Object?> data)
      : columns = jsonList(data['columns'], 'table columns').map((value) {
          return jsonString(value, 'table column');
        }).toList(),
        rows = jsonList(data['rows'], 'table rows').map((value) {
          return jsonList(value, 'table row');
        }).toList() {
    if (columns.isEmpty) throw FormatException('table must have columns');
    for (final row in rows) {
      if (row.length != columns.length) throw FormatException('table row length must match columns');
    }
  }

  void bind(web.HTMLTableElement table, void Function(int index) onRow) {
    final head = table.tHead ?? table.createTHead();
    head.textContent = '';
    final headingRow = head.insertRow();
    for (final column in columns) {
      final cell = web.document.createElement('th');
      cell.textContent = column;
      headingRow.appendChild(cell);
    }
    final body = (table.tBodies.item(0) ?? table.createTBody()) as web.HTMLTableSectionElement;
    body.textContent = '';
    for (var i = 0; i < rows.length; i++) {
      final row = body.insertRow();
      row.setAttribute('data-row', '$i');
      row.tabIndex = 0;
      for (final value in rows[i]) {
        final cell = row.insertCell();
        cell.textContent = value?.toString() ?? '';
      }
      row.onClick.listen((_) => onRow(i));
      row.onKeyDown.listen((event) {
        if (event.key == 'Enter' || event.key == ' ') onRow(i);
      });
    }
    table.setAttribute('data-bound', 'true');
  }
}
