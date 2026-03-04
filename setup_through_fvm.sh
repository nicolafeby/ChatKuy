fvm use 3.29.3 && \
fvm global 3.29.3 && \
fvm flutter clean && \
echo "🧹 Removing generated files (g.dart, mocks.dart)..." && \
find lib -name "*.g.dart" -type f -delete && \
find test -name "*.mocks.dart" -type f -delete && \
fvm flutter pub get && \
fvm dart run build_runner clean && \
fvm dart run build_runner build --delete-conflicting-outputs