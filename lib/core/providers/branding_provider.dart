import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/branding_config.dart';

final brandingProvider = Provider((ref) => BrandingConfig());
