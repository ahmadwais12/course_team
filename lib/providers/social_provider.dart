import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialLink {
  final String id;
  final String platform;
  final IconData icon;
  final String url;
  final int displayOrder;

  SocialLink({
    required this.id,
    required this.platform,
    required this.icon,
    required this.url,
    this.displayOrder = 0,
  });
}

class SocialNotifier extends StateNotifier<List<SocialLink>> {
  SocialNotifier() : super([]) {
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final data = await Supabase.instance.client
          .from('social_media_links')
          .select()
          .order('display_order', ascending: true);
      state = data.map<SocialLink>((row) {
        return SocialLink(
          id: row['id']?.toString() ?? '',
          platform: row['platform']?.toString() ?? '',
          icon: _iconFromString(row['icon']?.toString() ?? ''),
          url: row['url']?.toString() ?? '',
          displayOrder: (row['display_order'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (e) {
      state = [];
    }
  }

  static IconData _iconFromString(String name) {
    switch (name.toLowerCase()) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'twitter':
        return Icons.alternate_email_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'linkedin':
        return Icons.business_rounded;
      case 'youtube':
        return Icons.play_circle_filled_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Future<void> addLink(String platform, String iconName, String url) async {
    try {
      final response = await Supabase.instance.client
          .from('social_media_links')
          .insert({
            'platform': platform,
            'icon': iconName,
            'url': url,
            'display_order': state.length,
            'is_active': true,
          })
          .select()
          .single();

      state = [
        ...state,
        SocialLink(
          id: response['id']?.toString() ?? '',
          platform: platform,
          icon: _iconFromString(iconName),
          url: url,
          displayOrder: (response['display_order'] as num?)?.toInt() ?? state.length,
        ),
      ];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLink(String id, String newUrl) async {
    final previousState = [...state];
    state = [
      for (final link in state)
        if (link.id == id)
          SocialLink(
            id: link.id,
            platform: link.platform,
            icon: link.icon,
            url: newUrl,
            displayOrder: link.displayOrder,
          )
        else
          link,
    ];
    try {
      await Supabase.instance.client
          .from('social_media_links')
          .update({'url': newUrl})
          .eq('id', id);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await Supabase.instance.client
          .from('social_media_links')
          .delete()
          .eq('id', id);
      state = state.where((link) => link.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderLink(String id, int newIndex) async {
    await Supabase.instance.client
        .from('social_media_links')
        .update({'display_order': newIndex})
        .eq('id', id);
    await _loadLinks();
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, List<SocialLink>>((ref) {
  return SocialNotifier();
});
