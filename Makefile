SRC := openid-federation-trust-mark-requirements-1_0.md

.PHONY: html clean

# Same toolchain as the CI and as the other OpenID Federation extension repos
html:
	docker run --rm -v "$(CURDIR)":/data danielfett/markdown2rfc $(SRC)

clean:
	rm -f *.html *.xml *.txt
