import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'resources/locations_resource.dart';
import 'resources/scales_resource.dart';
import 'resources/suppliers_resource.dart';
import 'resources/freight_suppliers_resource.dart';
import 'resources/customers_resource.dart';
import 'resources/drivers_resource.dart';
import 'resources/trucks_resource.dart';
import 'resources/products_resource.dart';
import 'resources/purchase_orders_resource.dart';
import 'resources/sales_orders_resource.dart';
import 'resources/operators_resource.dart';
import 'resources/tickets_resource.dart';
import 'resources/queue_resource.dart';
import 'resources/webhook_configs_resource.dart';
import 'resources/sync_resource.dart';

// ---------------------------------------------------------------------------
// Change only these two constants when moving from mock → production.
// ---------------------------------------------------------------------------

const _mockBaseUrl =
    'https://anypoint.mulesoft.com/mocking/api/v1/sources/exchange/assets'
    '/01ee6a03-37fb-4d1a-9ae6-e55548f59804/lnc-scale-api/1.0.0/m';

// Production URL — fill in once MuleSoft deployment is live.
const _prodBaseUrl = '';

class LncApiClient {
  LncApiClient({
    bool useMock = true,
    String? apiKey,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    final baseUrl = useMock ? _mockBaseUrl : _prodBaseUrl;

    _dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (apiKey != null) 'x-api-key': apiKey,
      },
    ));

    // Log requests/responses in debug mode.
    _dio.interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
      logPrint: (o) => _debugPrint(o.toString()),
    ));

    // Convert Dio errors into ApiException.
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        final response = e.response;
        if (response != null) {
          final body = response.data;
          if (body is Map<String, dynamic>) {
            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: ApiException.fromJson(response.statusCode ?? 0, body),
              response: response,
            ));
          }
        }
        handler.next(e);
      },
    ));

    locations       = LocationsResource(_dio);
    scales          = ScalesResource(_dio);
    suppliers       = SuppliersResource(_dio);
    freightSuppliers = FreightSuppliersResource(_dio);
    customers       = CustomersResource(_dio);
    drivers         = DriversResource(_dio);
    trucks          = TrucksResource(_dio);
    products        = ProductsResource(_dio);
    purchaseOrders  = PurchaseOrdersResource(_dio);
    salesOrders     = SalesOrdersResource(_dio);
    operators       = OperatorsResource(_dio);
    tickets         = TicketsResource(_dio);
    queue           = QueueResource(_dio);
    webhookConfigs  = WebhookConfigsResource(_dio);
    sync            = SyncResource(_dio);
  }

  late final Dio _dio;

  late final LocationsResource       locations;
  late final ScalesResource          scales;
  late final SuppliersResource       suppliers;
  late final FreightSuppliersResource freightSuppliers;
  late final CustomersResource       customers;
  late final DriversResource         drivers;
  late final TrucksResource          trucks;
  late final ProductsResource        products;
  late final PurchaseOrdersResource  purchaseOrders;
  late final SalesOrdersResource     salesOrders;
  late final OperatorsResource       operators;
  late final TicketsResource         tickets;
  late final QueueResource           queue;
  late final WebhookConfigsResource  webhookConfigs;
  late final SyncResource            sync;
}

void _debugPrint(String msg) {
  assert(() {
    // ignore: avoid_print
    print('[LncApiClient] $msg');
    return true;
  }());
}
