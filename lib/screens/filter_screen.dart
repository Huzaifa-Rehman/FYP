import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilterScreen extends StatefulWidget {
  final List<String> initialCategories;
  final List<String> initialVendors;
  
  const FilterScreen({
    super.key, 
    this.initialCategories = const [],
    this.initialVendors = const [],
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late List<String> _selectedCategories;
  late List<String> _selectedVendors;
  
  List<String> _allCategories = ['All'];
  List<String> _allVendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.initialCategories);
    _selectedVendors = List.from(widget.initialVendors);
    _fetchFilterData();
  }

  Future<void> _fetchFilterData() async {
    try {
      final db = FirebaseFirestore.instance;
      
      final catSnap = await db.collection('categories').get();
      final List<String> fetchedCats = catSnap.docs
          .map((doc) => doc.data()['label'] as String)
          .toList();
          
      final vendorSnap = await db.collection('users').where('role', isEqualTo: 'Vendor').get();
      final List<String> fetchedVendors = vendorSnap.docs
          .map((doc) => doc.data()['business_name'] as String)
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() {
        _allCategories.addAll(fetchedCats.toSet());
        _allVendors = fetchedVendors.toSet().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Filters', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._allCategories.map((cat) {
                  return CheckboxListTile(
                    title: Text(cat),
                    value: _selectedCategories.contains(cat),
                    activeColor: AppColors.primaryGreen,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (cat == 'All') {
                            _selectedCategories = ['All'];
                          } else {
                            _selectedCategories.remove('All');
                            _selectedCategories.add(cat);
                          }
                        } else {
                          _selectedCategories.remove(cat);
                          if (_selectedCategories.isEmpty) {
                            _selectedCategories = ['All'];
                          }
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 24),
                const Text('Vendors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_allVendors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No vendors found.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  )
                else
                  ..._allVendors.map((vendor) {
                    return CheckboxListTile(
                      title: Text(vendor),
                      value: _selectedVendors.contains(vendor),
                      activeColor: AppColors.primaryGreen,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedVendors.add(vendor);
                          } else {
                            _selectedVendors.remove(vendor);
                          }
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'categories': _selectedCategories,
                    'vendors': _selectedVendors,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
