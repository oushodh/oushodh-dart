# Oushodh for Dart and Flutter

The official SDK for the [Oushodh API](https://oushodh.dev/docs): medicine data for Bangladesh, checked against the DGDA register.

- Pure Dart. It runs in Flutter apps (Android, iOS, desktop and web) and on Dart servers.
- One runtime dependency: [`package:http`](https://pub.dev/packages/http).
- Async throughout: every call returns a `Future`, and paging is a `Stream`.

Full API reference: <https://oushodh.dev/docs>.

## Install

Install from GitHub for now. Add this to your `pubspec.yaml`:

```yaml
dependencies:
  oushodh:
    git:
      url: https://github.com/oushodh/oushodh-dart.git
      ref: main
```

Then run `dart pub get`, or `flutter pub get` in a Flutter app.

The repository is private, so your GitHub account needs access to it.

From pub.dev (coming soon):

```sh
dart pub add oushodh
```

## Quickstart

Make a key on the Keys page of the member portal at <https://app.oushodh.dev>. A key starts with `oush_` and is shown once.

```dart
import 'package:oushodh/oushodh.dart';

Future<void> main() async {
  final oushodh = Oushodh(apiKey: 'oush_...');
  final meta = await oushodh.meta();

  print('${meta.client} ${meta.idProfile} ${meta.medicines}');

  oushodh.close();
}
```

With no `apiKey`, the client reads the `OUSHODH_API_KEY` environment variable. That works where the platform has an environment: the Dart VM, servers and command-line tools. On the web there is none, so pass the key. With no key at all, the constructor throws an `OushodhException`.

### Options

| Option       | Default                   | What it does                                       |
| ------------ | ------------------------- | -------------------------------------------------- |
| `apiKey`     | `OUSHODH_API_KEY`         | Your API key                                       |
| `baseUrl`    | `https://api.oushodh.dev` | Where the API lives                                |
| `timeout`    | 30 seconds                | How long one attempt may take                      |
| `maxRetries` | `2`                       | Retries after a `429`, a `5xx` or a network error  |
| `httpClient` | a new `http.Client`       | Another `http.Client` to use, for tests or a proxy |

Call `close()` when you are done. It closes the `http.Client` the SDK made, and leaves one you passed in open.

## Flutter

The SDK uses no `dart:io` in the library, so the same code runs on mobile, desktop and the web.

Anyone who has your app can read a key that ships inside it. For an app you give to the public, keep the key on your server and let the app ask your server. Put the key in the app only when you control every copy of it, such as an internal tool.

Pictures need no key. Show one with `Image.network(oushodh.imageUrl(file))`.

## Medicines

```dart
final page = await oushodh.listMedicines(limit: 100);

print('${page.total} ${page.items.length} ${page.next}');

final napa = await oushodh.getMedicine('MED-012933');

print('${napa.productName} ${napa.prices.unit?.amount} ${napa.monograph?.indications}');

final hits = await oushodh.search('napa 500', limit: 10);

print('${hits.total} ${hits.items.firstOrNull?.productName}');
```

- `listMedicines()` returns one `Page`: `items`, `next` and `total`. It takes `limit` (1 to 500), `cursor`, `updatedSince` and `q`.
- `getMedicine(ref)` takes an ID in any profile, an old ID or a UUID. It returns a `MedicineDetail`: the medicine with its current ID in your profile, and its `monograph`.
- `search(q)` returns the best matches for a person typing a name, best match first. It takes `limit` (1 to 50) and has no cursor.

Every value no source gives is `null`. Field names are the API's names in camelCase: `product_name` is `productName`.

The API only gains fields in `/v1`. Every model keeps the JSON it came from in `json`, so a field the SDK does not know yet is still there: `medicine.json['new_field']`.

## Paging

`medicines()` pages to the end for you. It returns a `Stream<Medicine>`:

```dart
await for (final medicine in oushodh.medicines(limit: 500)) {
  print('${medicine.id} ${medicine.productName}');
}
```

It takes the same options as `listMedicines()` and follows `next` until it is `null`.

## Sync

Copy the whole database once, then fetch only what changed.

1. The first sync pages through every medicine and keeps the `lastUpdated` of the newest one.
2. Each later sync passes that time as `updatedSince` and pages to the end.

```dart
DateTime? since = await loadLastSync();

await for (final medicine in oushodh.medicines(limit: 500, updatedSince: since)) {
  await save(medicine.uuid, medicine.json);

  if (since == null || medicine.lastUpdated.isAfter(since)) {
    since = medicine.lastUpdated;
  }
}

await storeLastSync(since);
```

- `updatedSince` takes a `DateTime`. The SDK sends it in UTC to the whole second, like `2026-11-08T09:30:00Z`.
- "At or after" means a change in the same second is never missed. The medicine that set the time comes back once more.
- Store the `uuid` as the key: it never changes. Show the `id` to people.
- Medicines are never deleted, and IDs are never reused.

## Errors

Every error extends `OushodhException`. It carries `status` (the HTTP status), `code` (from the API) and `message`.

Match on the class or on `code`, never on `message`. The message is for people and may change.

| Class                     | Status | `code`                           |
| ------------------------- | ------ | -------------------------------- |
| `BadRequestException`     | 400    | `bad_request`                    |
| `AuthenticationException` | 401    | `unauthorized`                   |
| `PlanException`           | 403    | `plan_expired`, `plan_limit`     |
| `NotFoundException`       | 404    | `not_found`                      |
| `RateLimitException`      | 429    | `rate_limited`, `quota_exceeded` |
| `ServerException`         | 5xx    | `internal`                       |
| `ConnectionException`     | none   | none: the network failed         |
| `OushodhTimeoutException` | none   | none: the attempt timed out      |

`OushodhTimeoutException` extends `ConnectionException`. Both have `status` and `code` set to `null`. An answer whose body is not JSON has `code` set to `null` and the message `HTTP <status>`.

```dart
try {
  await oushodh.getMedicine('MED-999999');
} on NotFoundException {
  print('No medicine has that ID');
} on PlanException catch (e) {
  if (e.code == 'plan_limit') {
    print('Upgrade your plan to read this medicine');
  }
} on RateLimitException catch (e) {
  print('Try again in ${e.retryAfter} seconds');
}
```

The SDK never puts your key in an error message or a URL.

## Rate limits

Your plan sets how many requests each key may make in a minute (60 a minute on Developer), and how many your account may make in a month.

- Over the minute's limit, the API answers `429 rate_limited`. The `Retry-After` header says how many seconds to wait. The SDK waits that long and tries again.
- When the month's requests are used up, the API answers `429 quota_exceeded` until the next month. The SDK does not retry it, because `Retry-After` counts the seconds to the next month. It throws at once, and `RateLimitException.retryAfter` holds those seconds.
- After a `5xx` or a network error, the SDK waits a short, growing time and tries again.
- It never retries a `400`, `401`, `403` or `404`: the same request gets the same answer.
- It retries at most `maxRetries` times. Set `maxRetries: 0` to turn retries off.

Every route is a GET, so a retry is always safe.

## Plan limits

Some plans read only the first medicines, in the order of their permanent number. `meta()` returns `medicines`, the number your plan reads.

Lists and search leave out the medicines beyond your plan's number. A lookup by ID of such a medicine throws `PlanException` with `code` `plan_limit`.

An account with no active plan gets `PlanException` with `code` `plan_expired` on every call.

## Images

`productImage` is the address of a medicine's picture, and `images` lists every picture. A picture that Oushodh keeps lives at `/v1/images/<sha256>.jpg`.

```dart
const file = '50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c.jpg';

final url = oushodh.imageUrl(file);
final bytes = await oushodh.getImage(file);
```

Both take the file name, not a URL. Pictures need no key, so `getImage()` sends none and returns the bytes as a `Uint8List`. A picture never changes, so you can cache it for a year.

## Testing your code

Pass a `MockClient` from `package:http/testing.dart` to answer requests without the network:

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final oushodh = Oushodh(
  apiKey: 'oush_test_123',
  httpClient: MockClient(
    (request) async => http.Response('{"client":"test","id_profile":"default","medicines":0,"last_import":null}', 200),
  ),
);
```

## Development

```sh
dart pub get
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart test -p chrome
```

## License

MIT. See [LICENSE](LICENSE).
