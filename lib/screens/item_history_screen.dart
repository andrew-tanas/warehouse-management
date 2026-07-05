import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/item_history.dart';
import '../db/database_helper.dart';

class ItemHistoryScreen extends StatefulWidget {
  final Item item;
  const ItemHistoryScreen({super.key, required this.item});

  @override
  State<ItemHistoryScreen> createState() => _ItemHistoryScreenState();
}

class _ItemHistoryScreenState extends State<ItemHistoryScreen> {
  List<ItemHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await DatabaseHelper.instance.getItemHistories(widget.item.id!);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.item.name} (${widget.item.size})'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No history found for this item.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final h = _history[index];
                    final isPositive = h.amountChange > 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isPositive ? Icons.add : Icons.remove,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          h.note,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${h.date.year}-${h.date.month.toString().padLeft(2, '0')}-${h.date.day.toString().padLeft(2, '0')}",
                        ),
                        trailing: Text(
                          (isPositive ? '+' : '') + h.amountChange.toStringAsFixed(1),
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
