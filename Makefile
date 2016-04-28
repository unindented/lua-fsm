.PHONY: clean lint test coveralls

all: lint test

clean:
	rm -rf luacov.*

lint:
	luacheck src spec

test:
	busted --coverage --verbose

coveralls:
	luacov-coveralls --verbose
