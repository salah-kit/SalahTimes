# Contributing to SalahTimes

Thank you for helping. Bug reports, timetable comparisons, method corrections and code are all
welcome. The org-wide [code of conduct](https://github.com/salah-kit/.github) applies.

## Build and test

You need Swift 6.0 or later, on macOS or Linux.

```sh
swift build
swift test
```

The tests use Swift Testing. They include the JSON vectors, parity checks against adhan-swift's
test data, and tests that run every code sample in the documentation.

## Format

The repo uses the formatter that ships with Swift, with the shared `.swift-format`
configuration. Format your changes, then check them as CI does:

```sh
swift format --in-place --recursive Package.swift Sources Tests Examples
swift format lint --strict --recursive Package.swift Sources Tests Examples
```

## Vectors

`Vectors/` holds the JSON test vectors that every SalahTimes engine passes, in any language.
[Vectors/README.md](Vectors/README.md) documents the schema. An independent reference
implementation in Python generates them from [docs/algorithm.md](docs/algorithm.md):

```sh
python3 Vectors/reference/generate.py
```

Regenerate the vectors when you change the algorithm or add a case, and commit the script's
changes and the JSON together. Explain any changed expectation in your pull request.

## Platform builds

CI builds the package for every Apple platform. To do the same on a Mac:

```sh
xcodebuild build -scheme SalahTimes -destination 'generic/platform=iOS' -derivedDataPath .derived
```

Use `watchOS`, `tvOS` or `visionOS` in place of `iOS` for the others.

The example also builds with both default-isolation settings. It needs Swift 6.2 or later, and
`SALAHTIMES_EXAMPLE_ISOLATION=MainActor` makes its own code main-actor isolated by default, as
an app target can be:

```sh
swift build --package-path Examples/PrayerTimesCLI
SALAHTIMES_EXAMPLE_ISOLATION=MainActor swift build --package-path Examples/PrayerTimesCLI \
  --build-path Examples/PrayerTimesCLI/.build-mainactor
```

## Documentation

Every public symbol has a DocC comment. The articles live in
`Sources/SalahTimes/SalahTimes.docc`. Their Swift code comes from
`Tests/SalahTimesTests/DocumentationExampleTests.swift`: change the sample there, between its
marker comments, and copy it into the article. A test fails when the two differ.

To build the site locally, as the docs workflow does:

```sh
xcodebuild docbuild -scheme SalahTimes -destination 'generic/platform=macOS' \
  -derivedDataPath .derived
xcrun docc process-archive transform-for-static-hosting \
  .derived/Build/Products/Debug/SalahTimes.doccarchive \
  --hosting-base-path SalahTimes --output-path .derived/site
```

Fix every warning DocC reports.

## Method corrections

The presets and the country suggestions must match what each authority publishes.
[METHODS.md](METHODS.md) gives the source for every value. If one is wrong or out of date,
open an issue with the `calculation-method` label. Link the authority's own publication, and a
timetable from it if you have one. A timetable that disagrees with SalahTimes is useful even
without a diagnosis; label it `timetable`.

Comparisons that need someone with a timetable or a language, such as authorities SalahTimes
hasn't been compared with yet, are open issues labelled
[`help wanted`](https://github.com/salah-kit/SalahTimes/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).
Each one says what to do and what to record. `Validation/official-timetables/README.md`
explains how the existing comparisons fetch their sources and run.

## API changes

Changes to the public API go through an RFC. Copy the structure of
[docs/rfcs/0001-api.md](docs/rfcs/0001-api.md) into `docs/rfcs/NNNN-title.md`, open a pull
request with the `rfc` label, and discuss it in GitHub Discussions. Bug fixes and additive
changes that don't touch the public API don't need one.

## Pull requests

- Keep each pull request to one topic, on a branch named for it.
- Add a test for every change in behavior. A bug fix comes with a test that would have caught
  the bug.
- CI must pass: build and test on macOS and Linux, the platform builds, and lint.
- Add a line to the Unreleased section of [CHANGELOG.md](CHANGELOG.md).

## Releasing

A maintainer releases from `main`, as the ecosystem standard's
[Releases](https://github.com/salah-kit/.github/blob/main/STANDARD.md#releases) section describes.
Versions follow Semantic Versioning, and tags have no `v` (`0.1.0`). Below 1.0, a minor release
may change the API.

1. **Prepare the release** in a pull request: move the Unreleased entries of
   [CHANGELOG.md](CHANGELOG.md) into a new `## [X.Y.Z] - YYYY-MM-DD` section and update the
   comparison links at the bottom, update the version in the README's installation snippet when
   adopters should require the new release, and update the status line of an RFC whose change
   ships.
2. **Merge it, and wait for CI and Docs to pass** on the commit you'll tag.
3. **Tag that commit** and push the tag:

   ```sh
   git tag -a X.Y.Z -m "SalahTimes X.Y.Z"
   git push origin X.Y.Z
   ```

   Apps pin tags, so never move or delete one; a mistake is fixed with a new release.
4. **Publish a GitHub release** for the tag, with three headings:
   - **Proven:** the gates and their evidence, such as the CI run on the tagged commit;
   - **Pending:** what still needs a person, a device or elapsed time, each item linked to the
     `help wanted` issue that tracks it (open one if none exists);
   - **Known limitations.**

   A check that didn't run is never listed as proven.
5. **Check the documentation site** at https://salah-kit.github.io/SalahTimes/ once the Docs
   workflow has deployed `main`.
