import 'package:course_emis/repositories/base_repository.dart';

class HeroSectionRepository extends BaseRepository {
  HeroSectionRepository() : super('home_hero_sections');

  Future<List<Map<String, dynamic>>> getActiveHeroSections() async {
    return await getAll(
      filters: {'is_active': true},
      orderBy: 'display_order',
      ascending: true,
    );
  }
}

class FeatureRepository extends BaseRepository {
  FeatureRepository() : super('home_features');

  Future<List<Map<String, dynamic>>> getActiveFeatures() async {
    return await getAll(
      filters: {'is_active': true},
      orderBy: 'display_order',
      ascending: true,
    );
  }
}

class StatRepository extends BaseRepository {
  StatRepository() : super('home_stats');

  Future<List<Map<String, dynamic>>> getActiveStats() async {
    return await getAll(
      filters: {'is_active': true},
      orderBy: 'display_order',
      ascending: true,
    );
  }
}

class TestimonialRepository extends BaseRepository {
  TestimonialRepository() : super('home_testimonials');

  Future<List<Map<String, dynamic>>> getActiveTestimonials() async {
    return await getAll(
      filters: {'is_active': true},
      orderBy: 'display_order',
      ascending: true,
    );
  }
}
