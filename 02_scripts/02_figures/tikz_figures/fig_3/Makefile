FIGURE = fig_3
OUTPUT_DIR = ../../pdf

.PHONY: all clean

all: $(OUTPUT_DIR)/$(FIGURE).pdf

$(FIGURE).pdf: $(FIGURE).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(FIGURE).tex

$(OUTPUT_DIR)/$(FIGURE).pdf: $(FIGURE).pdf
	mkdir -p $(OUTPUT_DIR)
	cp $(FIGURE).pdf $(OUTPUT_DIR)/$(FIGURE).pdf

clean:
	$(RM) $(FIGURE).aux $(FIGURE).log
