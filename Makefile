PRODUCT=bin/swift-compilation-database

# Builds the entire program
bin/swift-compilation-database: main.swift
	@echo "Building.."
	@mkdir -p bin
	swiftc main.swift -o $(PRODUCT)

build: bin/swift-compilation-database

# Running: Pipe the parseable output example to the program
.PHONY: run
run: build
	cat parseable-output-example.txt | ./$(PRODUCT)

.PHONY: install
install: build
	ditto $(PRODUCT) /usr/local/bin/
