# Clay

Dress your whole phone in minutes. Clay is a widget & home-screen customization
studio: compose beautiful widgets from styled blocks (clock, date, calendar,
battery, weather, photos, countdown, quote, steps), customize every visual
layer — material, depth, blur, tint, typography, corner geometry — and add
them to your home and lock screens. Liquid Glass aesthetic, same family as
Clink and Cling.

## Building

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The iUX-ios package must live one level up
(`../iUX-iOS`).

```sh
make project   # regenerate Clay.xcodeproj from project.yml
make build     # build for the iOS simulator
make run       # boot the sim, install, launch
make device    # build + install + launch on a paired iPhone
make test      # run unit tests
make icon      # re-render the app icon
```

## Targets

| Target        | What it is |
|---------------|------------|
| `Clay`        | Container app — widget gallery, live-preview editor, themes, setups. |
| `ClayWidgets` | WidgetKit extension rendering saved designs on home & lock screens. |
| `Sources/ClayKit` | Shared recipe model, App Group store, block modules, and the one true renderer — compiled into both targets. |

See [ARCHITECTURE.md](ARCHITECTURE.md) for the recipe model, block plugin
pattern, and timeline strategy.

## License

Released under the Commons Liberty License (CLL) v1.2 — see
[LICENSE.md](LICENSE.md).
