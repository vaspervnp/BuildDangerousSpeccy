# Build Dangerous - ZX Spectrum 48K/128K. Build with rasm and Python 3 (+ Pillow; the `z80`
# module for the tests).
#
#   make            the tape (.tap, .tzx) and snapshots (.z80, 48K and 128K)
#   make art        assets/gfx/*.png again from tools/zxart.py (overwrites edits to them)
#   make run        the tape in FBZX
#   make test       every tests/*.txt script on the headless Spectrum, 48K and 128K
#   make check      the tape loaded through the real 48K and 128K ROMs
#   make manual     the manuals, English and Greek, as PDFs
#   make clean

RASM ?= rasm
PY   ?= python3
FBZX ?= fbzx
B    := build

BUILDINGS := sunnyvale test gallery mall hotel hospital hardknock skyscraper
CAMPAIGN  := sunnyvale mall hotel hospital hardknock skyscraper
ROUTES    := $(CAMPAIGN:%=tests/route_%.txt)
GFX       := tools/zxgfx.py
ASSETS := $(B)/tiles.bin $(B)/tile_attr.asm $(B)/font.bin $(B)/thanos.bin $(B)/vignettes.bin \
          $(B)/hazards.bin $(B)/people.bin $(B)/tasha.bin $(B)/strings.asm \
          $(B)/room_outdoor.asm $(B)/title.asm $(BUILDINGS:%=$(B)/bld_%.asm)
SRC    := $(wildcard src/*.asm)

all: $(B)/bd.tap $(B)/bd48.z80 $(B)/bd128.z80

$(B):
	mkdir -p $@

art:
	$(PY) tools/zxart.py

$(B)/tiles.bin $(B)/tile_attr.asm &: assets/gfx/tiles.png $(GFX) | $(B)
	$(PY) $(GFX) tiles $< $(B)/tiles.bin $(B)/tile_attr.asm

$(B)/font.bin: assets/gfx/font.png $(GFX) | $(B)
	$(PY) $(GFX) font $< $@

$(B)/thanos.bin: assets/gfx/thanos.png $(GFX) | $(B)
	$(PY) $(GFX) sprites $< $@ --mirror

$(B)/vignettes.bin: assets/gfx/vignettes.png $(GFX) | $(B)
	$(PY) $(GFX) sprites $< $@

$(B)/hazards.bin: assets/gfx/hazards.png $(GFX) | $(B)
	$(PY) $(GFX) sprites8 $< $@

$(B)/people.bin: assets/gfx/people.png $(GFX) | $(B)
	$(PY) $(GFX) sprites $< $@

$(B)/tasha.bin: assets/gfx/tasha.png $(GFX) | $(B)
	$(PY) $(GFX) portrait $< $@ 8 22 16 8    # the mouth: MOUTH_* in src/phone.asm

$(B)/title.asm: assets/title.txt $(GFX) | $(B)
	$(PY) $(GFX) tilemap $< $@ title_logo

$(B)/room_outdoor.asm: assets/rooms/outdoor.txt $(GFX) | $(B)
	$(PY) $(GFX) room $< $@ room_outdoor

$(B)/strings.asm: assets/text/strings.txt assets/gfx/font.png $(GFX) | $(B)
	$(PY) $(GFX) text $< $@ assets/gfx/font.png

$(B)/bld_%.asm: assets/buildings/%.txt $(wildcard assets/rooms/*.txt) $(GFX) | $(B)
	$(PY) $(GFX) building $< $@ bld_$*

$(B)/bd.bin $(B)/bd.sym &: $(SRC) $(ASSETS)
	$(RASM) src/main.asm -os $(B)/bd.sym -s -sa 2>&1 | sed 's/\x1b\[[0-9;]*m//g' \
		| grep -Ei "error|warning|code\+data|free" ; test -s $(B)/bd.sym

# The loading screen: the CPC's picture, in Spectrum colours (tools/loadscreen.py).
$(B)/loading.scr: assets/gfx/loadscreen_cartoon.jpg tools/loadscreen.py | $(B)
	$(PY) tools/loadscreen.py $< $@ --preview $(B)/loading.png

# The tape: a BASIC loader, the loading screen, the code.
$(B)/bd.tap: $(B)/bd.bin $(B)/bd.sym $(B)/loading.scr src/loader.bas tools/mktap.py
	$(PY) tools/mktap.py $@ --sym $(B)/bd.sym --tzx $(B)/bd.tzx \
		--basic src/loader.bas BUILDDANGR --screen $(B)/loading.scr BD_SCREEN \
		--code $(B)/bd.bin BD_CODE BIN_START

$(B)/bd48.z80: $(B)/bd.bin $(B)/bd.sym $(B)/loading.scr tools/mkz80.py
	$(PY) tools/mkz80.py $(B)/bd.bin $(B)/bd.sym $(B)/loading.scr $@ --model 48

$(B)/bd128.z80: $(B)/bd.bin $(B)/bd.sym $(B)/loading.scr tools/mkz80.py
	$(PY) tools/mkz80.py $(B)/bd.bin $(B)/bd.sym $(B)/loading.scr $@ --model 128

run: $(B)/bd.tap
	$(FBZX) $<

# Planned clean runs through each campaign building (tools/route.py), run by `make test`.
tests/route_%.txt: assets/buildings/%.txt $(wildcard assets/rooms/*.txt) tools/route.py $(GFX)
	$(PY) tools/route.py $< $@

# Headless runs of every tests/*.txt script, on a 48K and a 128K; screenshots go to
# build/shots/.
test: $(B)/bd.bin $(ROUTES)
	@set -e; for m in 48 128; do for t in tests/*.txt; do \
	  echo "== $$t ($$m K)"; \
	  $(PY) tools/zxrun.py $(B)/bd.bin --sym $(B)/bd.sym --model $$m --script $$t \
	    --out $(B)/shots/$$m; \
	done; done

check: $(B)/bd.tap
	@for m in 48 128; do \
		echo "=== the tape through the real ROM, $$m K ==="; \
		$(PY) tools/zxcheck.py $(B)/bd.tap --sym $(B)/bd.sym --bin $(B)/bd.bin \
			--blocks 6 --model $$m --loading $(B)/loading.scr --png $(B)/check$$m.png; r=$$?; \
		if [ $$r = 2 ]; then echo "    skipped (no emulator or ROM)"; \
		elif [ $$r != 0 ]; then exit 1; fi; done

# The manuals, English and Greek, as PDFs (needs: pip install markdown fpdf2, and the DejaVu
# fonts). Their pictures in docs/img/ are screenshots from make test's runs (build/shots/48/).
manual: manual.pdf manual_gr.pdf

manual.pdf manual_gr.pdf: %.pdf: %.md tools/mkmanual.py $(wildcard docs/img/*.png)
	$(PY) tools/mkmanual.py $< $@

clean:
	rm -rf $(B)

.PHONY: all art run test check manual clean
