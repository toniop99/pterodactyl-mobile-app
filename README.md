# pterodactyl_app

## Testing
```bash
flutter pub run build_runner build --delete-conflicting-outputs

flutter test
```

## Update icons
```bash
dart run flutter_launcher_icons
```

## Build

```bash
flutter build ipa --export-options-plist=ExportOptions.plist
```