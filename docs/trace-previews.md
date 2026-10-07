# Pad-center trace previews

These full-board images use the footprint fixes from
[ergogen-footprints PR #85](https://github.com/ceoloide/ergogen-footprints/pull/85).
The footprint submodule includes that implementation plus the separate
[MX net correction in PR #86](https://github.com/ceoloide/ergogen-footprints/pull/86).

The first two MCU examples on each board are reversible, demonstrating rectangular
and chevron jumpers. `choc_demo` uses nice!nano and `mx_demo` uses SuperMini. The
second Choc switch demonstrates same-side hotswap routing, while other switch
examples retain their existing opposed-side routes.

## Copper-only views

These KiCad exports omit silkscreen and solder mask so the traces are visible.
Both copper layers are shown from above; the back copper views are not mirrored.
Only empty white page margins have been trimmed.

| Board | Front copper | Back copper |
| --- | --- | --- |
| Choc / nice!nano | [Image](images/pad-center-traces/copper/choc_demo-F-Cu.png) | [Image](images/pad-center-traces/copper/choc_demo-B-Cu.png) |
| MX / SuperMini | [Image](images/pad-center-traces/copper/mx_demo-F-Cu.png) | [Image](images/pad-center-traces/copper/mx_demo-B-Cu.png) |

## Physical board renders

KiBot/PcbDraw renders include silkscreen and solder mask. Back views are mirrored,
as when turning over a physical board.

| Board | Front | Back |
| --- | --- | --- |
| Choc / nice!nano | [Image](images/pad-center-traces/choc_demo-top.png) | [Image](images/pad-center-traces/choc_demo-bottom.png) |
| MX / SuperMini | [Image](images/pad-center-traces/mx_demo-top.png) | [Image](images/pad-center-traces/mx_demo-bottom.png) |

## Reproduce

```sh
git submodule update --init
npm ci
npm run debug
for board in choc_demo mx_demo; do
  docker run --rm -w /board -v "$PWD:/board" \
    ghcr.io/inti-cmnb/kicad9_auto:latest \
    kibot -b "pcbs/$board.kicad_pcb" -c docs/trace-preview.kibot.yaml
  for side in F B; do
    kicad-cli pcb export svg --layers "$side.Cu" --page-size-mode 2 \
      --exclude-drawing-sheet \
      --output "docs/images/pad-center-traces/copper/$board-$side-Cu.svg" \
      "pcbs/$board.kicad_pcb"
  done
done
```

The copper SVGs were exported with KiCad CLI 8.0.9, then rasterized with
`rsvg-convert --background-color '#ffffff' --width 5000`. The PNGs retain all copper
geometry, with whitespace trimmed using Pillow's background-difference bounding
box and a 40-pixel margin. The physical renders use the corney-island KiBot Docker
workflow at 900 dpi. Both boards were generated with the locked Ergogen 4.1.0.
