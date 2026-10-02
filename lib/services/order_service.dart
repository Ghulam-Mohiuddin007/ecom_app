import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_service.dart';

enum OrderStatus {
  confirmed,
  authenticated,
  shipped,
  outForDelivery,
  delivered,
}

class OrderModel {
  final String id;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String buyerAddress;
  final String buyerCity;
  final String postalCode;
  final String paymentMethod;
  final DateTime createdAt;
  OrderStatus status;
  final String courierName;
  final String courierPhone;
  final String estimatedDelivery;

  OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0.0,
    required this.total,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.buyerAddress,
    required this.buyerCity,
    required this.postalCode,
    required this.paymentMethod,
    required this.createdAt,
    this.status = OrderStatus.shipped,
    this.courierName = 'Alex Mercer (VaultRider #42)',
    this.courierPhone = '+1 (555) 019-2834',
    this.estimatedDelivery = 'Tomorrow, by 6:00 PM',
  });

  String get statusDisplay {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.authenticated:
        return '1-of-1 Authenticity Verified';
      case OrderStatus.shipped:
        return 'In Transit with Courier';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  int get statusStep {
    switch (status) {
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.authenticated:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'total': total,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerEmail': buyerEmail,
      'buyerAddress': buyerAddress,
      'buyerCity': buyerCity,
      'postalCode': postalCode,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'estimatedDelivery': estimatedDelivery,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    OrderStatus parsedStatus = OrderStatus.shipped;
    final statusStr = map['status']?.toString();
    if (statusStr != null) {
      for (var s in OrderStatus.values) {
        if (s.name == statusStr || s.toString() == statusStr) {
          parsedStatus = s;
          break;
        }
      }
    }

    final rawItems = map['items'];
    List<Map<String, dynamic>> parsedItems = [];
    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          parsedItems = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}
    } else if (rawItems is List) {
      parsedItems = rawItems
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return OrderModel(
      id:
          map['id']?.toString() ??
          'VV-${DateTime.now().millisecondsSinceEpoch % 100000}',
      items: parsedItems,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      buyerName: map['buyerName']?.toString() ?? '',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      buyerEmail: map['buyerEmail']?.toString() ?? '',
      buyerAddress: map['buyerAddress']?.toString() ?? '',
      buyerCity: map['buyerCity']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? '',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash on Delivery',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: parsedStatus,
      courierName:
          map['courierName']?.toString() ?? 'Alex Mercer (VaultRider #42)',
      courierPhone: map['courierPhone']?.toString() ?? '+1 (555) 019-2834',
      estimatedDelivery:
          map['estimatedDelivery']?.toString() ?? 'Tomorrow, by 6:00 PM',
    );
  }

  factory OrderModel.fromSupabase(Map<String, dynamic> row) {
    OrderStatus parsedStatus = OrderStatus.shipped;
    final statusStr = row['status']?.toString();
    if (statusStr == 'confirmed') {
      parsedStatus = OrderStatus.confirmed;
    }
    if (statusStr == 'authenticated') {
      parsedStatus = OrderStatus.authenticated;
    }
    if (statusStr == 'in_transit' || statusStr == 'shipped') {
      parsedStatus = OrderStatus.shipped;
    }
    if (statusStr == 'out_for_delivery' || statusStr == 'outForDelivery') {
      parsedStatus = OrderStatus.outForDelivery;
    }
    if (statusStr == 'delivered') {
      parsedStatus = OrderStatus.delivered;
    }

    List<Map<String, dynamic>> parsedItems = [];
    final rawItems = row['items'];
    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          parsedItems = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}
    } else if (rawItems is List) {
      parsedItems = rawItems
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return OrderModel(
      id: row['order_id']?.toString() ?? row['id']?.toString() ?? 'VV-00000',
      items: parsedItems,
      subtotal:
          (row['subtotal'] as num?)?.toDouble() ??
          (row['total'] as num?)?.toDouble() ??
          0.0,
      shippingFee: (row['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      total: (row['total'] as num?)?.toDouble() ?? 0.0,
      buyerName:
          row['buyer_name']?.toString() ?? row['buyerName']?.toString() ?? '',
      buyerPhone:
          row['buyer_phone']?.toString() ?? row['buyerPhone']?.toString() ?? '',
      buyerEmail:
          row['buyer_email']?.toString() ?? row['buyerEmail']?.toString() ?? '',
      buyerAddress:
          row['buyer_address']?.toString() ?? row['address']?.toString() ?? '',
      buyerCity: row['buyer_city']?.toString() ?? row['city']?.toString() ?? '',
      postalCode: row['postal_code']?.toString() ?? '',
      paymentMethod: row['payment_method']?.toString() ?? 'Cash on Delivery',
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: parsedStatus,
      courierName:
          row['courier_name']?.toString() ?? 'Elena Rostova (VaultExpress #19)',
      courierPhone: row['courier_phone']?.toString() ?? '+1 (555) 782-9912',
      estimatedDelivery:
          row['estimated_delivery']?.toString() ?? 'Tomorrow, by 6:00 PM',
    );
  }
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._internal();

  static const String _storageKey = 'vibe_vault_saved_orders_v2';

  OrderService._internal() {
    _initSampleOrders();
    _init();
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get activeShipments =>
      _orders.where((o) => o.status != OrderStatus.delivered).toList();
  OrderModel? get activeOrder => _orders.isNotEmpty ? _orders.first : null;
  bool get hasActiveOrder => _orders.isNotEmpty;
  int get deliveryCount => _orders.length;
  bool get isLoading => _isLoading;
  bool _notificationScheduled = false;

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

  void _init() {
    _loadFromLocalDatabase().then((_) => syncWithDatabase());
    _listenAuthAndSync();
  }

  void _listenAuthAndSync() {
    try {
      final client = _supabaseClient;
      if (client != null) {
        client.auth.onAuthStateChange.listen((data) {
          if (data.session != null) {
            syncWithDatabase();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFromLocalDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        final loaded = decoded
            .map((item) => OrderModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
        if (loaded.isNotEmpty) {
          _orders.clear();
          _orders.addAll(loaded);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading orders from local storage: $e');
      return;
    }

    // First time setup fallback
    if (_orders.isEmpty) {
      _initSampleOrders();
      await _saveToLocalDatabase();
    }
  }

  Future<void> _saveToLocalDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _orders.map((o) => o.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving orders to local storage: $e');
    }
  }

  void _initSampleOrders() {
    if (_orders.isEmpty) {
      _orders.add(
        OrderModel(
          id: 'VV-82194',
          items: [
            {
              'id': 'sample-drop-1',
              'title': 'Vintage 90s Leather Bomber',
              'price': 145.0,
              'category': 'Vintage 90s',
              'condition': 'Near Mint',
              'quantity': 1,
              'gradient_colors': ['#3D1E08', '#8B4513'],
            },
          ],
          subtotal: 145.0,
          total: 145.0,
          buyerName: 'Ghulam-Mohiuddn',
          buyerPhone: '+92 318 0072482',
          buyerEmail: 'ghulammohiuddin0088@gmail.com',
          buyerAddress: 'House No 200 B-3 Urdr bazar',
          buyerCity: 'Sahiwal',
          postalCode: '57000',
          paymentMethod: 'Cash on Delivery',
          createdAt: DateTime.now().subtract(const Duration(hours: 18)),
          status: OrderStatus.outForDelivery,
          courierName: 'Elena Rostova (VaultExpress #19)',
          courierPhone: '+1 (555) 782-9912',
          estimatedDelivery: 'Today, by 4:30 PM',
        ),
      );
    }
  }

  Future<void> refreshOrders() async {
    _isLoading = true;
    notifyListeners();
    await _loadFromLocalDatabase();
    await syncWithDatabase();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncWithDatabase() async {
    try {
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}

      if (client == null) return;
      final user = client.auth.currentUser;
      if (user == null) return;

      final data = await client
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (data.isNotEmpty) {
        final remoteOrders = data
            .map((row) => OrderModel.fromSupabase(row))
            .toList();

        final existingIds = _orders.map((o) => o.id).toSet();
        bool hasNew = false;
        for (var remoteOrder in remoteOrders) {
          if (!existingIds.contains(remoteOrder.id)) {
            _orders.add(remoteOrder);
            existingIds.add(remoteOrder.id);
            hasNew = true;
          }
        }

        if (hasNew) {
          _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          await _saveToLocalDatabase();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Supabase orders sync note: $e');
    }
  }

  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel> createOrder({
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    required String buyerAddress,
    required String buyerCity,
    required String postalCode,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double subtotal,
  }) async {
    final now = DateTime.now();
    final randomDigits =
        '${(now.microsecondsSinceEpoch % 900000) + 100000}-${Random().nextInt(900) + 100}';
    final orderId = 'VV-$randomDigits';

    final couriers = [
      {'name': 'Alex Mercer (VaultRider #42)', 'phone': '+1 (555) 019-2834'},
      {'name': 'Marcus Chen (VaultDrone #07)', 'phone': '+1 (555) 604-3319'},
      {'name': 'Sasha Banks (SpeedVault #88)', 'phone': '+1 (555) 412-8801'},
      {
        'name': 'Elena Rostova (VaultExpress #19)',
        'phone': '+1 (555) 782-9912',
      },
    ];
    final courier = couriers[_orders.length % couriers.length];

    final order = OrderModel(
      id: orderId,
      items: List.from(items),
      subtotal: subtotal,
      shippingFee: 0.0,
      total: subtotal,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      buyerAddress: buyerAddress,
      buyerCity: buyerCity,
      postalCode: postalCode,
      paymentMethod: paymentMethod,
      createdAt: now,
      status: OrderStatus.shipped,
      courierName: courier['name']!,
      courierPhone: courier['phone']!,
      estimatedDelivery: 'Tomorrow, by 6:00 PM',
    );

    // Save order immediately to in-memory list and local persistent database
    _orders.insert(0, order);
    await _saveToLocalDatabase();
    notifyListeners();

    // Clear cart completely
    await CartService.instance.clearCart();

    // Background sync with Supabase orders table
    try {
      final supabase = _supabaseClient;
      final user = supabase?.auth.currentUser;
      if (supabase != null && user != null) {
        await supabase.from('orders').insert({
          'order_id': orderId,
          'user_id': user.id,
          'total': subtotal,
          'shipping_fee': 0.0,
          'buyer_name': buyerName,
          'buyer_phone': buyerPhone,
          'buyer_email': buyerEmail,
          'buyer_address': buyerAddress,
          'buyer_city': buyerCity,
          'postal_code': postalCode,
          'payment_method': paymentMethod,
          'status': order.status.name,
          'courier_name': order.courierName,
          'courier_phone': order.courierPhone,
          'estimated_delivery': order.estimatedDelivery,
          'items': items,
          'created_at': now.toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Supabase orders insert notice: $e');
    }

    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = status;
      _saveToLocalDatabase();
      notifyListeners();

      try {
        final supabase = _supabaseClient;
        supabase
            ?.from('orders')
            .update({'status': status.name})
            .eq('order_id', orderId)
            .then((_) {})
            .catchError((_) {});
      } catch (_) {}
    }
  }
}
