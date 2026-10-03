import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torico/services/audio_service.dart';
import 'package:torico/services/new_sale_tracker.dart';
import 'package:torico/services/firestore_sales_service.dart';

ToricoSaleRecord sale(
  String id, {
  String status = 'approved',
  String platform = 'mercado_pago',
}) => ToricoSaleRecord(
  id: id,
  amount: 1,
  platform: 'Mercado Pago',
  platformId: platform,
  status: status,
  source: 'webhook',
  dateKey: '2026-10-03',
  externalId: id,
  rawPayload: null,
  createdAt: DateTime(2026, 10, 3),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('audio needs explicit activation even with saved preference', () async {
    SharedPreferences.setMockInitialValues({AudioService.preferenceKey: true});
    var plays = 0;
    final audio = AudioService(
      play: () async {
        plays++;
      },
    );
    await audio.loadPreference();
    await audio.playCashSound();
    expect(plays, 0);
    expect(await audio.activate(), true);
    expect(plays, 1);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AudioService.preferenceKey,
      ),
      true,
    );
    await audio.playCashSound();
    expect(plays, 2);
  });
  test('blocked activation cannot enable sale audio', () async {
    SharedPreferences.setMockInitialValues({});
    final audio = AudioService(
      play: () async {
        throw StateError('blocked');
      },
    );
    expect(await audio.activate(), false);
    expect(audio.ready, false);
    await audio.playCashSound();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AudioService.preferenceKey,
      ),
      isNull,
    );
  });
  test(
    'initial history, rejected, cancelled and duplicate sales stay silent',
    () {
      final tracker = NewSaleTracker();
      expect(tracker.observe([sale('old')]), false);
      expect(
        tracker.observe([
          sale('rejected', status: 'rejected'),
          sale('cancelled', status: 'cancelled'),
        ]),
        false,
      );
      expect(tracker.observe([sale('new')]), true);
      expect(tracker.observe([sale('new')]), false);
      expect(tracker.observe([sale('rede', platform: 'rede')]), false);
    },
  );
}
