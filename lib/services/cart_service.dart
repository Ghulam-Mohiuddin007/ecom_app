import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem {
  final String id;
  final String productId;
  final Map<String, dynamic> product;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'cart_item_id': id,
      'quantity': quantity,
      ...product,
    };
  }
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();

  CartService._internal() {
    _init();
  }

  final List<CartItem> _items = [];
  bool _isLoading = false;
  bool _hasSupabaseTable = true;
  bool _notificationScheduled = false;

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void notifyListeners() {
    try {
      final binding = WidgetsBinding.instance;
      if (binding.schedulerPhase == SchedulerPhase.idle) {
        super.notifyListeners();
      } else {
        if (!_notificationScheduled) {
          _notificationScheduled = true;
          binding.addPostFrameCallback((_) {
            _notificationScheduled = false;
            super.notifyListeners();
          });
        }
      }
    } catch (_) {
      super.notifyListeners();
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);
  List<Map<String, dynamic>> get mappedItems => _items.map((i) => i.toMap()).toList();
  bool get isLoading => _isLoading;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(
        0.0,
        (sum, item) {
          final price = double.tryParse(item.product['price']?.toString() ?? '0') ?? 0.0;
          return sum + (price * item.quantity);
        },
      );

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  void _init() {
    try {
      final client = _supabaseClient;
      if (client != null) {
        client.auth.onAuthStateChange.listen((data) {
          if (data.session != null) {
            syncWithSupabase();
          } else {
            _items.clear();
            notifyListeners();
          }
        });
      }
    } catch (_) {}
    syncWithSupabase();
  }

  Future<void> syncWithSupabase() async {
    try {
      final supabase = _supabaseClient;
      if (supabase == null) return;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      _isLoading = true;
      notifyListeners();

      final data = await supabase
          .from('cart_items')
          .select('id, product_id, quantity')
          .eq('user_id', user.id);

      final List<CartItem> loadedItems = [];
      for (var row in data) {
        try {
          final productRes = await supabase
              .from('products')
              .select()
              .eq('id', row['product_id'])
              .maybeSingle();

          if (productRes != null) {
            loadedItems.add(
              CartItem(
                id: row['id'].toString(),
                productId: row['product_id'].toString(),
                product: productRes,
                quantity: (row['quantity'] as num?)?.toInt() ?? 1,
              ),
            );
          }
        } catch (err) {
          debugPrint('Error fetching product for cart item: $err');
        }
      }

      // Always update items, even if loadedItems is empty (cleared cart)
      _items.clear();
      _items.addAll(loadedItems);
    } catch (e) {
      debugPrint('Error syncing cart with Supabase: $e');
      if (e.toString().contains('PGRST205') || e.toString().contains('not find the table')) {
        _hasSupabaseTable = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    final productId = product['id']?.toString() ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final existingIndex = _items.indexWhere((item) => item.productId == productId);

    int currentQty = quantity;
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      currentQty = _items[existingIndex].quantity;
    } else {
      final cartItemId = 'item_${DateTime.now().millisecondsSinceEpoch}_${_items.length}';
      _items.add(
        CartItem(
          id: cartItemId,
          productId: productId,
          product: Map<String, dynamic>.from(product),
          quantity: quantity,
        ),
      );
    }
    notifyListeners();

    // Background sync with Supabase
    try {
      final supabase = _supabaseClient;
      if (supabase != null && _hasSupabaseTable) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final existing = await supabase
              .from('cart_items')
              .select('id, quantity')
              .eq('user_id', user.id)
              .eq('product_id', productId)
              .maybeSingle();

          if (existing != null) {
            final updatedQty = (existing['quantity'] as num?)?.toInt() ?? currentQty;
            final newQty = existingIndex >= 0 ? currentQty : updatedQty + quantity;
            await supabase
                .from('cart_items')
                .update({'quantity': newQty})
                .eq('id', existing['id']);

            final idx = _items.indexWhere((item) => item.productId == productId);
            if (idx >= 0) {
              _items[idx] = CartItem(
                id: existing['id'].toString(),
                productId: productId,
                product: _items[idx].product,
                quantity: newQty,
              );
            }
          } else {
            final inserted = await supabase
                .from('cart_items')
                .insert({
                  'user_id': user.id,
                  'product_id': productId,
                  'quantity': quantity,
                })
                .select('id')
                .single();

            final idx = _items.indexWhere((item) => item.productId == productId);
            if (idx >= 0) {
              _items[idx] = CartItem(
                id: inserted['id'].toString(),
                productId: productId,
                product: _items[idx].product,
                quantity: quantity,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase cart sync error: $e');
      if (e.toString().contains('PGRST205') || e.toString().contains('not find the table')) {
        _hasSupabaseTable = false;
      }
    }
  }

  Future<void> updateQuantity(String cartItemId, int delta) async {
    final index = _items.indexWhere((item) => item.id == cartItemId || item.productId == cartItemId);
    if (index >= 0) {
      final newQty = _items[index].quantity + delta;
      final productId = _items[index].productId;
      if (newQty <= 0) {
        await removeFromCart(cartItemId);
        return;
      }
      _items[index].quantity = newQty;
      notifyListeners();

      try {
        final supabase = _supabaseClient;
        if (supabase != null && _hasSupabaseTable) {
          final user = supabase.auth.currentUser;
          if (user != null) {
            await supabase
                .from('cart_items')
                .update({'quantity': newQty})
                .eq('user_id', user.id)
                .eq('product_id', productId);
          }
        }
      } catch (e) {
        debugPrint('Error updating quantity in Supabase: $e');
      }
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId || item.productId == cartItemId);
    if (index == -1) return;

    final itemToRemove = _items[index];
    final productId = itemToRemove.productId;
    final realId = itemToRemove.id;

    _items.removeAt(index);
    notifyListeners();

    try {
      final supabase = _supabaseClient;
      if (supabase != null && _hasSupabaseTable) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          // Delete by both user_id and product_id to ensure reliable deletion regardless of local vs remote ID
          await supabase
              .from('cart_items')
              .delete()
              .eq('user_id', user.id)
              .eq('product_id', productId);

          // Also attempt delete by id if it looks like a UUID
          if (!realId.startsWith('item_')) {
            await supabase.from('cart_items').delete().eq('id', realId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting cart item from Supabase: $e');
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    try {
      final supabase = _supabaseClient;
      if (supabase != null && _hasSupabaseTable) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase.from('cart_items').delete().eq('user_id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cart in Supabase: $e');
    }
  }
}
