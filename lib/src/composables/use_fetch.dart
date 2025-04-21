import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:vortex/src/reactive/ref.dart';
import 'package:vortex/src/utils/logger.dart';

/// A class representing the result of a fetch operation
class FetchResult<T> {
  final Ref<T?> data;
  final Ref<DioException?> error;
  final Ref<String> status;
  final Future<void> Function([FetchOptions?]) refresh;
  final Future<void> Function([FetchOptions?]) execute;
  final void Function() clear;

  FetchResult({
    required this.data,
    required this.error,
    required this.status,
    required this.refresh,
    required this.execute,
    required this.clear,
  });

  /// Check if the request is pending
  bool get pending => status.value == 'pending';

  /// Check if the request is successful
  bool get success => status.value == 'success';

  /// Check if the request has an error
  bool get hasError => status.value == 'error';
}

/// Options for fetch operations
class FetchOptions {
  final String? key;
  final String method;
  final Map<String, dynamic>? query;
  final dynamic body;
  final Map<String, String>? headers;
  final String? baseURL;
  final bool lazy;
  final bool immediate;
  final String? dedupe;
  final List<String>? pick;
  final Function(RequestContext)? onRequest;
  final Function(ErrorContext)? onRequestError;
  final Function(ResponseContext)? onResponse;
  final Function(ResponseErrorContext)? onResponseError;

  FetchOptions({
    this.key,
    this.method = 'GET',
    this.query,
    this.body,
    this.headers,
    this.baseURL,
    this.lazy = false,
    this.immediate = true,
    this.dedupe,
    this.pick,
    this.onRequest,
    this.onRequestError,
    this.onResponse,
    this.onResponseError,
  });
}

/// Context for request hooks
class RequestContext {
  final String request;
  final Options options;

  RequestContext({required this.request, required this.options});
}

/// Context for response hooks
class ResponseContext {
  final String request;
  final Response response;
  final Options options;

  ResponseContext({
    required this.request,
    required this.response,
    required this.options,
  });
}

/// Context for request error hooks
class ErrorContext {
  final String request;
  final RequestOptions options;
  final DioException error;

  ErrorContext({
    required this.request,
    required this.options,
    required this.error,
  });
}

/// Context for response error hooks
class ResponseErrorContext {
  final String request;
  final Response? response;
  final RequestOptions options;
  final DioException error;

  ResponseErrorContext({
    required this.request,
    required this.response,
    required this.options,
    required this.error,
  });
}

// Global Dio instance for fetch operations
final _dio = Dio(BaseOptions(validateStatus: (status) => true));

// Cache for fetch results
final Map<String, FetchResult> _cache = {};

/// Composable function for making HTTP requests
Future<FetchResult<T>> useFetch<T>(
  String url, {
  String? key,
  String method = 'GET',
  Map<String, dynamic>? query,
  dynamic body,
  Map<String, String>? headers,
  String? baseURL,
  bool lazy = false,
  bool immediate = true,
  String? dedupe,
  List<String>? pick,
  Function(RequestContext)? onRequest,
  Function(ErrorContext)? onRequestError,
  Function(ResponseContext)? onResponse,
  Function(ResponseErrorContext)? onResponseError,
}) async {
  // Generate a cache key if not provided
  key ??= '$method:$url:${jsonEncode(query ?? {})}';

  // Return cached data if available
  if (_cache.containsKey(key)) {
    return _cache[key] as FetchResult<T>;
  }

  // Create reactive refs
  final data = Ref<T?>(null);
  final error = Ref<DioException?>(null);
  final status = Ref<String>('idle');

  // Create the result object
  final result = FetchResult<T>(
    data: data,
    error: error,
    status: status,
    refresh:
        ([opts]) => _execute<T>(
          url: url,
          method: opts?.method ?? method,
          query: opts?.query ?? query,
          body: opts?.body ?? body,
          headers: opts?.headers ?? headers,
          baseURL: opts?.baseURL ?? baseURL,
          onRequest: opts?.onRequest ?? onRequest,
          onRequestError: opts?.onRequestError ?? onRequestError,
          onResponse: opts?.onResponse ?? onResponse,
          onResponseError: opts?.onResponseError ?? onResponseError,
          data: data,
          error: error,
          status: status,
          pick: opts?.pick ?? pick,
          dedupe: opts?.dedupe ?? dedupe,
          cause: 'refresh:manual',
        ),
    execute:
        ([opts]) => _execute<T>(
          url: url,
          method: opts?.method ?? method,
          query: opts?.query ?? query,
          body: opts?.body ?? body,
          headers: opts?.headers ?? headers,
          baseURL: opts?.baseURL ?? baseURL,
          onRequest: opts?.onRequest ?? onRequest,
          onRequestError: opts?.onRequestError ?? onRequestError,
          onResponse: opts?.onResponse ?? onResponse,
          onResponseError: opts?.onResponseError ?? onResponseError,
          data: data,
          error: error,
          status: status,
          pick: opts?.pick ?? pick,
          dedupe: opts?.dedupe ?? dedupe,
          cause: 'execute',
        ),
    clear: () {
      data.value = null;
      error.value = null;
      status.value = 'idle';
      _cache.remove(key);
    },
  );

  // Cache the result
  _cache[key] = result;

  // Execute immediately if not lazy and immediate
  if (!lazy && immediate) {
    await result.execute();
  }

  return result;
}

Future<void> _execute<T>({
  required String url,
  required String method,
  required Map<String, dynamic>? query,
  required dynamic body,
  required Map<String, String>? headers,
  required String? baseURL,
  required Function(RequestContext)? onRequest,
  required Function(ErrorContext)? onRequestError,
  required Function(ResponseContext)? onResponse,
  required Function(ResponseErrorContext)? onResponseError,
  required Ref<T?> data,
  required Ref<DioException?> error,
  required Ref<String> status,
  required List<String>? pick,
  required String? dedupe,
  required String cause,
}) async {
  // Set status to pending
  status.value = 'pending';
  error.value = null;

  // Store original baseUrl if we need to temporarily change it
  final originalBaseUrl = _dio.options.baseUrl;

  try {
    // Prepare request options
    final options = Options(method: method, headers: headers);

    // Create request context
    final requestContext = RequestContext(request: url, options: options);

    // Call onRequest hook
    if (onRequest != null) {
      onRequest(requestContext);
    }

    // Set baseURL if provided
    if (baseURL != null) {
      _dio.options.baseUrl = baseURL;
    }

    // Make the request
    final response = await _dio.request(
      url,
      queryParameters: query,
      data: body,
      options: options,
    );

    // Create response context
    final responseContext = ResponseContext(
      request: url,
      response: response,
      options: options,
    );

    // Call onResponse hook
    if (onResponse != null) {
      onResponse(responseContext);
    }

    // Process response data
    dynamic responseData = response.data;

    // Apply pick if specified
    if (pick != null && responseData is Map<String, dynamic>) {
      final pickedData = <String, dynamic>{};
      for (final field in pick) {
        if (responseData.containsKey(field)) {
          pickedData[field] = responseData[field];
        }
      }
      responseData = pickedData;
    }

    // Update data
    data.value = responseData as T?;
    status.value = 'success';
  } on DioException catch (e) {
    // Handle request error
    error.value = e;
    status.value = 'error';

    // Create error contexts
    if (e.type == DioExceptionType.badResponse) {
      // Response error
      final responseErrorContext = ResponseErrorContext(
        request: url,
        response: e.response,
        options: e.requestOptions,
        error: e,
      );

      // Call onResponseError hook
      if (onResponseError != null) {
        onResponseError(responseErrorContext);
      }
    } else {
      // Request error
      final errorContext = ErrorContext(
        request: url,
        options: e.requestOptions,
        error: e,
      );

      // Call onRequestError hook
      if (onRequestError != null) {
        onRequestError(errorContext);
      }
    }
  } catch (e) {
    // Handle unexpected errors
    error.value = DioException(
      requestOptions: RequestOptions(path: url),
      error: e,
    );
    status.value = 'error';
    Log.e('Unexpected error in useFetch: $e');
  } finally {
    // Restore original baseUrl
    if (baseURL != null) {
      _dio.options.baseUrl = originalBaseUrl;
    }
  }
}
