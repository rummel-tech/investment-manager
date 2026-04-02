import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import '../../stock.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _currentPriceController = TextEditingController();

  @override
  void dispose() {
    _symbolController.dispose();
    _sharesController.dispose();
    _priceController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final shares = double.parse(_sharesController.text.trim());
    final purchasePrice = double.parse(_priceController.text.trim());
    final currentPrice = _currentPriceController.text.trim().isNotEmpty
        ? double.parse(_currentPriceController.text.trim())
        : purchasePrice;

    final stock = Stock(
      symbol: symbol,
      shares: shares,
      purchasePrice: purchasePrice,
      currentPrice: currentPrice,
    );

    Navigator.pop(context, stock);
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
    if (double.parse(v.trim()) <= 0) return 'Must be greater than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(RummelBlueSpacing.base),
          children: [
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Ticker Symbol',
                hintText: 'e.g. AAPL',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: _requiredValidator,
              autofocus: true,
            ),
            const SizedBox(height: RummelBlueSpacing.base),
            TextFormField(
              controller: _sharesController,
              decoration: const InputDecoration(
                labelText: 'Shares',
                hintText: 'e.g. 10',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _numberValidator,
            ),
            const SizedBox(height: RummelBlueSpacing.base),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                prefixText: '\$',
                hintText: 'e.g. 150.00',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _numberValidator,
            ),
            const SizedBox(height: RummelBlueSpacing.base),
            TextFormField(
              controller: _currentPriceController,
              decoration: const InputDecoration(
                labelText: 'Current Price (optional)',
                prefixText: '\$',
                hintText: 'Defaults to purchase price',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: RummelBlueSpacing.lg),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add to Portfolio'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
