#
# Note: call as "make serve" or "make preview" to get the "Last processed" line,
# or "make serve GITHUB_ACCOUNT=<myaccount>"etc. to set the github account to be used when 
# generating links to github.
#
all: preview

gendoc = docs-generated
buildscript = scripts/build_docs.sh

clean-gen:
	/bin/rm -rf $(gendoc)

rebuild-gen:
	$(buildscript) $(GITHUB_ACCOUNT)

build: clean-gen rebuild-gen
	mkdocs build --config-file $(gendoc)/mkdocs.yml

deploy: deploy-origin

deploy-origin: clean-gen rebuild-gen
	mkdocs gh-deploy --force --remote-name origin --config-file $(gendoc)/mkdocs.yml

check test: clean-gen rebuild-gen
	mkdocs build --strict --config-file $(gendoc)/mkdocs.yml

serve preview: clean-gen rebuild-gen
	mkdocs serve --config-file $(gendoc)/mkdocs.yml


