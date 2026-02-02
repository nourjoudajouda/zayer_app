import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/product_link_import_repository.dart';

final productLinkImportRepositoryProvider =
    Provider<ProductLinkImportRepository>((_) => ProductLinkImportRepositoryMock());
