#
# -*- Prerequisites -*-
#

# the fact that 'I am Node.js' is unquoted here looks wrong to me but it
# CAN'T be quoted, I tried. Apparently in GNU Makefiles, in the paren+comma
# syntax for conditionals, quotes are literal; and because the $(shell...)
# call has parentheses and single and double quotes, the quoted syntaxes
# don't work (I tried), we HAVE to use the paren+comma syntax
ifneq ($(shell node -e 'console.log("I am Node.js")'), I am Node.js)
  ifeq ($(shell nodejs -e 'console.log("I am Node.js")' 2>/dev/null), I am Node.js)
    $(error You have /usr/bin/nodejs but no /usr/bin/node, please 'sudo apt-get install nodejs-legacy' (see http://stackoverflow.com/a/21171188/362030 ))
  endif

  $(error Please install Node.js: https://nodejs.org/ )
endif

#
# -*- Configuration -*-
#

# inputs
SRC_DIR = ./src
INTRO = $(SRC_DIR)/intro.js
OUTRO = $(SRC_DIR)/outro.js

BASE_SOURCES = \
  $(SRC_DIR)/utils.ts \
  $(SRC_DIR)/dom.ts \
  $(SRC_DIR)/unicode.ts \
  $(SRC_DIR)/mathVariantMap.ts \
	$(SRC_DIR)/browser.ts \
  $(SRC_DIR)/animate.ts \
  $(SRC_DIR)/services/aria.ts \
  $(SRC_DIR)/domFragment.ts \
  $(SRC_DIR)/tree.ts \
  $(SRC_DIR)/cursor.ts \
  $(SRC_DIR)/controller.ts \
  $(SRC_DIR)/publicapi.ts \
  $(SRC_DIR)/services/parser.util.ts \
  $(SRC_DIR)/services/saneKeyboardEvents.util.ts \
  $(SRC_DIR)/services/exportText.ts \
  $(SRC_DIR)/services/focusBlur.ts \
  $(SRC_DIR)/services/keystroke.ts \
  $(SRC_DIR)/services/latex.ts \
  $(SRC_DIR)/services/mouse.ts \
  $(SRC_DIR)/services/scrollHoriz.ts \
  $(SRC_DIR)/services/textarea.ts

SOURCES_FULL = \
  $(BASE_SOURCES) \
  $(SRC_DIR)/commands/math.ts \
  $(SRC_DIR)/commands/text.ts \
  $(SRC_DIR)/commands/math/advancedSymbols.ts \
  $(SRC_DIR)/commands/math/basicSymbols.ts \
  $(SRC_DIR)/commands/math/commands.ts \
  $(SRC_DIR)/commands/math/LatexCommandInput.ts


SOURCES_BASIC = \
  $(BASE_SOURCES) \
  $(SRC_DIR)/commands/math.ts \
  $(SRC_DIR)/commands/math/basicSymbols.ts \
  $(SRC_DIR)/commands/math/commands.ts

CSS_DIR = $(SRC_DIR)/css
CSS_MAIN = $(CSS_DIR)/main.less
CSS_SOURCES = $(shell find $(CSS_DIR) -name '*.less')

# Font build configuration.
# Override the font selection at build time: make MATH_FONT=stix2
# Custom fonts: add src/css/fonts/myfont.less, then: make MATH_FONT=myfont font
MATH_FONT ?= ncm

NCM_FONT_LESS = $(CSS_DIR)/fonts/ncm.less
STX_FONT_LESS = $(CSS_DIR)/fonts/stix2.less
NCM_CSS       = $(BUILD_DIR)/mathquill-ncm.css
STX_CSS       = $(BUILD_DIR)/mathquill-stix2.css
FONT_CSS      = $(BUILD_DIR)/mathquill-font.css

NCM_FONT_DIR  = $(BUILD_DIR)/fonts/ncm
STX_FONT_DIR  = $(BUILD_DIR)/fonts/stix2
# Font packages are not npm dependencies — install manually before running font targets:
#   npm install @mathjax/mathjax-newcm-font   (for NCM)
#   npm install @mathjax/mathjax-stix2-font   (for STIX2)
NCM_SRC       = ./node_modules/@mathjax/mathjax-newcm-font/chtml/woff2
STX_SRC       = ./node_modules/@mathjax/mathjax-stix2-font/chtml/woff2

NCM_FONTS = mjx-ncm-n.woff2 mjx-ncm-mi.woff2 mjx-ncm-i.woff2 mjx-ncm-b.woff2 \
            mjx-ncm-ss.woff2 mjx-ncm-m.woff2 mjx-ncm-ds.woff2 mjx-ncm-f.woff2 \
            mjx-ncm-s.woff2 mjx-ncm-lo.woff2
STX_FONTS = mjx-stx-n.woff2 mjx-stx-mi.woff2 mjx-stx-i.woff2 mjx-stx-b.woff2 \
            mjx-stx-ss.woff2 mjx-stx-m.woff2 mjx-stx-ds.woff2 mjx-stx-f.woff2 \
            mjx-stx-s.woff2 mjx-stx-lo.woff2


TEST_SUPPORT = ./test/support/assert.ts ./test/support/trigger-event.ts ./test/support/jquery-stub.ts
UNIT_TESTS = ./test/unit/*.test.js ./test/unit/*.test.ts

# outputs
VERSION ?= $(shell node -e "console.log(require('./package.json').version)")

BUILD_DIR = ./build
BUILD_JS = $(BUILD_DIR)/mathquill.js
BASIC_JS = $(BUILD_DIR)/mathquill-basic.js
BUILD_CSS = $(BUILD_DIR)/mathquill.css
BASIC_CSS = $(BUILD_DIR)/mathquill-basic.css
BUILD_TEST = $(BUILD_DIR)/mathquill.test.js
UGLY_JS = $(BUILD_DIR)/mathquill.min.js
UGLY_BASIC_JS = $(BUILD_DIR)/mathquill-basic.min.js

# programs and flags
UGLIFY ?= ./node_modules/.bin/uglifyjs
UGLIFY_OPTS ?= --mangle --compress hoist_vars=true --comments /maintainers@mathquill.com/

LESSC ?= ./node_modules/.bin/lessc
LESS_OPTS ?=
ifdef OMIT_FONT_FACE
  LESS_OPTS += --modify-var="omit-font-face=true"
endif

# Empty target files whose Last Modified timestamps are used to record when
# something like `npm install` last happened (which, for example, would then be
# compared with its dependency, package.json, so if package.json has been
# modified since the last `npm install`, Make will `npm install` again).
# http://www.gnu.org/software/make/manual/html_node/Empty-Targets.html#Empty-Targets
NODE_MODULES_INSTALLED = ./node_modules/.installed--used_by_Makefile
BUILD_DIR_EXISTS = $(BUILD_DIR)/.exists--used_by_Makefile

# environment constants

#
# -*- Build tasks -*-
#

.PHONY: all basic dev js uglify css fonts font convert-fonts clean setup-gitconfig prettify-all
all: css font uglify
basic: $(UGLY_BASIC_JS) $(BASIC_CSS)
unminified_basic: $(BASIC_JS) $(BASIC_CSS)
# dev is like all, but without minification
dev: css font js
js: $(BUILD_JS)
uglify: $(UGLY_JS)
css: $(BUILD_CSS)
# Build all built-in fonts and the active font selection
fonts: $(NCM_CSS) $(STX_CSS) $(FONT_CSS)
# Build only the selected font (faster; also entry point for custom fonts)
font: $(BUILD_DIR)/mathquill-$(MATH_FONT).css $(FONT_CSS)
clean:
	rm -rf $(BUILD_DIR)
# This adds an entry to your local .git/config file that looks like this:
# [include]
# 	path = ../.gitconfig
# that tells git to include the additional configuration specified inside the .gitconfig file that's checked in here.
setup-gitconfig:
	@git config --local include.path ../.gitconfig
prettify-all:
	npx prettier --write '**/*.{ts,js,css,html}'

$(BUILD_JS): $(INTRO) $(SOURCES_FULL) $(OUTRO) $(BUILD_DIR_EXISTS)
	cat $^ | ./script/escape-non-ascii | ./script/tsc-emit-only > $@
	perl -pi -e s/mq-/$(MQ_CLASS_PREFIX)mq-/g $@
	perl -pi -e s/{VERSION}/v$(VERSION)/ $@

$(UGLY_JS): $(BUILD_JS) $(NODE_MODULES_INSTALLED)
	$(UGLIFY) $(UGLIFY_OPTS) < $< > $@

$(BASIC_JS): $(INTRO) $(SOURCES_BASIC) $(OUTRO) $(BUILD_DIR_EXISTS)
	cat $^ | ./script/escape-non-ascii | ./script/tsc-emit-only > $@
	perl -pi -e s/mq-/$(MQ_CLASS_PREFIX)mq-/g $@
	perl -pi -e s/{VERSION}/v$(VERSION)/ $@

$(UGLY_BASIC_JS): $(BASIC_JS) $(NODE_MODULES_INSTALLED)
	$(UGLIFY) $(UGLIFY_OPTS) < $< > $@

$(BUILD_CSS): $(CSS_SOURCES) $(NODE_MODULES_INSTALLED) $(BUILD_DIR_EXISTS)
	$(LESSC) $(LESS_OPTS) $(CSS_MAIN) > $@
	perl -pi -e s/mq-/$(MQ_CLASS_PREFIX)mq-/g $@
	perl -pi -e s/{VERSION}/v$(VERSION)/ $@

$(BASIC_CSS): $(CSS_SOURCES) $(NODE_MODULES_INSTALLED) $(BUILD_DIR_EXISTS)
	$(LESSC) --modify-var="basic=true" $(LESS_OPTS) $(CSS_MAIN) > $@
	perl -pi -e s/mq-/$(MQ_CLASS_PREFIX)mq-/g $@
	perl -pi -e s/{VERSION}/v$(VERSION)/ $@

$(NCM_CSS): $(NCM_FONT_LESS) $(NODE_MODULES_INSTALLED) $(BUILD_DIR_EXISTS)
	mkdir -p $(NCM_FONT_DIR)
	cp $(addprefix $(NCM_SRC)/,$(NCM_FONTS)) $(NCM_FONT_DIR)/
	$(LESSC) $(LESS_OPTS) $(NCM_FONT_LESS) > $@

$(STX_CSS): $(STX_FONT_LESS) $(NODE_MODULES_INSTALLED) $(BUILD_DIR_EXISTS)
	mkdir -p $(STX_FONT_DIR)
	cp $(addprefix $(STX_SRC)/,$(STX_FONTS)) $(STX_FONT_DIR)/
	$(LESSC) $(LESS_OPTS) $(STX_FONT_LESS) > $@

# Active font CSS — whichever MATH_FONT selects (default: ncm)
$(FONT_CSS): $(BUILD_DIR)/mathquill-$(MATH_FONT).css
	cp $< $@

# WOFF2 → OTF/EOT/SVG conversion (not in default build; requires external tools)
# Toolchain: woff2 CLI (WOFF2→OTF), ttf2eot (OTF→EOT), fonttools (OTF→SVG)
convert-fonts: $(NCM_CSS) $(STX_CSS)
	@echo "Convert WOFF2 → OTF/EOT/SVG for each font in build/fonts/ncm/ and build/fonts/stix2/"
	@echo "Requires: woff2_decompress, ttf2eot, python3 -m fonttools"
	@echo "Example per file:"
	@echo "  woff2_decompress build/fonts/ncm/mjx-ncm-n.woff2"
	@echo "  ttf2eot < build/fonts/ncm/mjx-ncm-n.otf > build/fonts/ncm/mjx-ncm-n.eot"
	@echo "  python3 -m fonttools otf2svg build/fonts/ncm/mjx-ncm-n.otf"

$(NODE_MODULES_INSTALLED): package.json
	test -e $(NODE_MODULES_INSTALLED) || rm -rf ./node_modules/ # robust against previous botched npm install
	NODE_ENV=development npm ci
	touch $(NODE_MODULES_INSTALLED)

$(BUILD_DIR_EXISTS):
	mkdir -p $(BUILD_DIR)
	touch $(BUILD_DIR_EXISTS)

#
# -*- Test tasks -*-
#
.PHONY:
lint:
	npx tsc --noEmit
  # Make sure that the public, standalone type definitions do not depend on any internal sources.
	npx tsc --noEmit -p test/tsconfig.public-types-test.json

.PHONY: test server benchmark
server:
	node script/test_server.js
test: dev $(BUILD_TEST) $(BASIC_JS) $(BASIC_CSS)
	@echo
	@echo "** now open test/{unit,visual}.html in your browser to run the {unit,visual} tests. **"
benchmark: dev $(BUILD_TEST) $(BASIC_JS) $(BASIC_CSS)
	@echo
	@echo "** now open benchmark/{render,select,update}.html in your browser. **"

$(BUILD_TEST): $(INTRO) $(SOURCES_FULL) $(TEST_SUPPORT) $(UNIT_TESTS) $(OUTRO) $(BUILD_DIR_EXISTS)
	cat $^ | ./script/tsc-emit-only > $@
	perl -pi -e s/{VERSION}/v$(VERSION)/ $@
