// GENERATED: merges the per-area catalogs.
import 'lang.dart';
import 'catalogs/en_ai_1.dart';
import 'catalogs/pt_ai_1.dart';
import 'catalogs/es_ai_1.dart';
import 'catalogs/en_ai_2.dart';
import 'catalogs/pt_ai_2.dart';
import 'catalogs/es_ai_2.dart';
import 'catalogs/en_ai_3.dart';
import 'catalogs/pt_ai_3.dart';
import 'catalogs/es_ai_3.dart';
import 'catalogs/en_cli_1.dart';
import 'catalogs/pt_cli_1.dart';
import 'catalogs/es_cli_1.dart';
import 'catalogs/en_cli_2.dart';
import 'catalogs/pt_cli_2.dart';
import 'catalogs/es_cli_2.dart';
import 'catalogs/en_cli_3.dart';
import 'catalogs/pt_cli_3.dart';
import 'catalogs/es_cli_3.dart';
import 'catalogs/en_cli_4.dart';
import 'catalogs/pt_cli_4.dart';
import 'catalogs/es_cli_4.dart';

const Map<ShepherdLang, Map<String, String>> catalogs = {
  ShepherdLang.en: {
    ...enAi1,
    ...enAi2,
    ...enAi3,
    ...enCli1,
    ...enCli2,
    ...enCli3,
    ...enCli4,
  },
  ShepherdLang.pt: {
    ...ptAi1,
    ...ptAi2,
    ...ptAi3,
    ...ptCli1,
    ...ptCli2,
    ...ptCli3,
    ...ptCli4,
  },
  ShepherdLang.es: {
    ...esAi1,
    ...esAi2,
    ...esAi3,
    ...esCli1,
    ...esCli2,
    ...esCli3,
    ...esCli4,
  },
};
