import '../models/networking_model.dart';
import 'api_client.dart';

abstract class NetworkingGateway {
  Future<NetworkingCardDto> fetchMine();

  Future<NetworkingCardDto> updateMine(NetworkingCardDto card);

  Future<PublicNetworkingCardDto> fetchVisibleByUserId(int userId);
}

class NetworkingService implements NetworkingGateway {
  NetworkingService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<NetworkingCardDto> fetchMine() async {
    final response = await _api.getJson('/networking/me');
    return NetworkingCardDto.fromJson(response);
  }

  @override
  Future<NetworkingCardDto> updateMine(NetworkingCardDto card) async {
    final response = await _api.putJson('/networking/me', body: card.toJson());
    return NetworkingCardDto.fromJson(response);
  }

  @override
  Future<PublicNetworkingCardDto> fetchVisibleByUserId(int userId) async {
    final response = await _api.getJson('/networking/users/$userId');
    return PublicNetworkingCardDto.fromJson(response);
  }
}
