// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:dmg/dmg.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'setting',
      help:
          'Path of the modified `setting.py` file. Use default setting if not provided',
    )
    ..addOption(
      'license-path',
      help: 'Path of the license file.',
    )
    ..addOption(
      'app',
      help:
          'Path of the input .app file (Generated by XCode). Ex: "./data/releases/name.app"',
    )
    ..addOption(
      'dmg',
      help: 'Path of the output .dmg file. Ex: "./data/releases/name.dmg',
    )
    ..addOption(
      'volume-name',
      help: 'Name of the volume',
    )
    ..addOption(
      'sign-certificate',
      help:
          'The certificate that you are signed. Ex: `Developer ID Application: Your Company`',
    )
    ..addOption(
      'notary-profile',
      help:
          'Name of the notary profile that created by `xcrun notarytool store-credentials`. Use `dart run build_dmg:norary_profile` to create if you don\'t have.',
    );
  final param = parser.parse(args);

  final setting = param['setting'] as String?;
  final licensePath = param['license-path'] as String?;
  final app = param['app'] as String;
  final dmg = param['dmg'] as String;
  final volumeName = param['volume-name'] as String;
  final signCertificate = param['sign-certificate'] as String;
  final notaryProfile = param['notary-profile'] as String;

  final settingPath = getSettingPath(setting, licensePath);

  runDmgBuild(settingPath, app, dmg, volumeName);
  print('Done dmg buil.');

  runCodeSign(dmg, signCertificate);
  print('Done codesign.');

  final notaryOutput = runNotaryTool(dmg);
  print('Done notary.');

  final regex = RegExp(r'id: (\w+-\w+-\w+-\w+-\w+)');
  final match = regex.firstMatch(notaryOutput);
  final noratyId = match!.group(1) as String;

  final dmgPath = (dmg.split('/')..removeLast()).join('/');
  final developerLog = '$dmgPath/notary_log.json';
  final logFile = File(developerLog);

  final success = await waitAndCheckNoratyState(
    notaryOutput,
    dmg,
    notaryProfile,
    noratyId,
    logFile,
  );

  if (success) {
    runStaple(dmg);
    print('Stapled.');
  }

  print('Done.');
}
