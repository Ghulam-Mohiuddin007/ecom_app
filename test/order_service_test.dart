import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecom_app/services/order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OrderService Multi-Delivery & Database Persistence Tests', () {
    test('Initializes with seeded active demo order', () {
      final service = OrderService.instance;
      expect(service.orders.isNotEmpty, true);
      expect(service.activeShipments.isNotEmpty, true);
    });

    test('Handles 2 or more deliveries simultaneously', () async {
      final service = OrderService.instance;
      final initialCount = service.orders.length;

      // Create a 2nd delivery
      final order1 = await service.createOrder(
        items: [
          {'name': 'Vintage Leather Jacket', 'price': 89.99, 'quantity': 1},
        ],
        subtotal: 89.99,
        buyerName: 'Alex Doe',
        buyerPhone: '+1 555-0199',
        buyerEmail: 'alex@example.com',
        buyerAddress: '742 Evergreen Terrace',
        buyerCity: 'Springfield',
        postalCode: '97477',
        paymentMethod: 'Credit Card',
      );

      expect(service.orders.length, initialCount + 1);
      expect(service.orders.first.id, order1.id);
      expect(service.getOrderById(order1.id), isNotNull);

      // Create a 3rd delivery
      final order2 = await service.createOrder(
        items: [
          {'name': 'Chunky Cyber Sneaker', 'price': 120.00, 'quantity': 1},
        ],
        subtotal: 120.00,
        buyerName: 'Casey Smith',
        buyerPhone: '+1 555-0200',
        buyerEmail: 'casey@example.com',
        buyerAddress: '100 Cyberpunk Blvd',
        buyerCity: 'Neo Tokyo',
        postalCode: '10001',
        paymentMethod: 'Apple Pay',
      );

      expect(service.orders.length, initialCount + 2);
      expect(service.orders.length >= 2, true);

      // Verify each delivery has independent tracking IDs, drivers, and items
      expect(order1.id, isNot(equals(order2.id)));
      expect(order1.buyerName, 'Alex Doe');
      expect(order2.buyerName, 'Casey Smith');
      expect(order1.total, 89.99);
      expect(order2.total, 120.00);

      // Verify retrieving both orders works
      final retrieved1 = service.getOrderById(order1.id);
      final retrieved2 = service.getOrderById(order2.id);
      expect(retrieved1?.id, order1.id);
      expect(retrieved2?.id, order2.id);

      // Verify activeShipments contains both
      final activeIds = service.activeShipments.map((o) => o.id).toList();
      expect(activeIds.contains(order1.id), true);
      expect(activeIds.contains(order2.id), true);
    });

    test('Persists 2 or more deliveries across app refresh / reloads', () async {
      final service = OrderService.instance;

      // Add two distinct orders
      final first = await service.createOrder(
        items: [{'name': 'Cyberpunk Tee', 'price': 45.0, 'quantity': 1}],
        subtotal: 45.0,
        buyerName: 'Delivery 1 Recipient',
        buyerPhone: '+1 111-222',
        buyerEmail: 'test1@test.com',
        buyerAddress: '123 Alpha St',
        buyerCity: 'A-City',
        postalCode: '11111',
        paymentMethod: 'COD',
      );

      final second = await service.createOrder(
        items: [{'name': 'Y2K Metallic Pants', 'price': 95.0, 'quantity': 1}],
        subtotal: 95.0,
        buyerName: 'Delivery 2 Recipient',
        buyerPhone: '+1 333-444',
        buyerEmail: 'test2@test.com',
        buyerAddress: '456 Beta Ave',
        buyerCity: 'B-City',
        postalCode: '22222',
        paymentMethod: 'Card',
      );

      final countBeforeRefresh = service.orders.length;
      expect(countBeforeRefresh >= 2, true);

      // SIMULATE APP REFRESH: Reload from persistent database
      await service.refreshOrders();

      // ALL deliveries must still exist after the refresh!
      expect(service.orders.length, countBeforeRefresh);
      expect(service.getOrderById(first.id), isNotNull);
      expect(service.getOrderById(second.id), isNotNull);
      expect(service.getOrderById(first.id)?.buyerName, 'Delivery 1 Recipient');
      expect(service.getOrderById(second.id)?.buyerName, 'Delivery 2 Recipient');
    });

    test('Updating delivery status works independently for each delivery and persists', () async {
      final service = OrderService.instance;
      final order = service.orders.first;

      service.updateOrderStatus(order.id, OrderStatus.outForDelivery);
      final updated = service.getOrderById(order.id);
      expect(updated?.status, OrderStatus.outForDelivery);
      expect(updated?.statusDisplay, 'Out for Delivery');

      // Refresh from DB and verify status persisted
      await service.refreshOrders();
      expect(service.getOrderById(order.id)?.status, OrderStatus.outForDelivery);
    });
  });
}
