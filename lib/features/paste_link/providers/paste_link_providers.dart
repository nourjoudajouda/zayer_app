import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/product_link_import_repository.dart';
import '../repositories/product_link_import_repository_api.dart';

final productLinkImportRepositoryProvider =
    Provider<ProductLinkImportRepository>((_) => ProductLinkImportRepositoryApi());
