import 'api_client.dart';

class GroupsApi {
  final ApiClient _client;

  GroupsApi(this._client);

  Future<List<dynamic>> listMyGroups() =>
      _client.get('/community/groups').then((r) => r['groups'] as List? ?? []);

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String? emoji,
  }) =>
      _client.post('/community/groups', body: {
        'name': name,
        if (description != null) 'description': description,
        if (emoji != null) 'emoji': emoji,
      });

  Future<Map<String, dynamic>> getInviteCode(String groupId) =>
      _client.post('/community/groups/$groupId/invite');

  Future<Map<String, dynamic>> joinGroup(String inviteCode) =>
      _client.post('/community/groups/join', body: {'invite_code': inviteCode});

  Future<void> leaveGroup(String groupId) =>
      _client.post('/community/groups/$groupId/leave');

  Future<List<dynamic>> getMembers(String groupId) =>
      _client.get('/community/groups/$groupId/members').then(
          (r) => r['members'] as List? ?? []);
}
