#! /usr/bin/env bash
#
# This is a script to build the markdown pages for the documentation
# of a separate easyconfig repository.
#

# That cd will work if the script is called by specifying the path or is simply
# found on PATH. It will not expand symbolic links.
cd $(dirname $0)
cd ..
repodir=$PWD
repo=${PWD##*/}

if (( $# == 1 ))
then
    github_account="$1"
else
    github_account="klust"
fi

gendoc='docs-generated'
userinfo='USER.md'
package_preamble="Install with the EasyBuild-user module:\n\
\`\`\`\`\n\
eb <easyconfig> -r\n
\`\`\`\`\n\
To access module help after installation and get reminded for which stacks and partitions the module is\n\
installed, use \`module spider <name>/<version>\`.\n\n\
EasyConfig:\n"
module_preamble="Install with the EasyBuild-user module:\n\
\`\`\`\`\n\
eb <easyconfig> -r\n
\`\`\`\`\n\
To access module help after installation and get reminded for which stacks and partitions the module is\n\
installed, use \`module spider <name>/<version>\`.\n\n\
[Direct link to <easyconfig> in GitHub](https://github.com/<github_account>/<repo>/blob/main/easybuild/easyconfigs/<file_with_prefix>)\n\n
EasyConfig:\n"
archived_module_preamble="This software is archived in the\n\
[$repo](https://github.com/$github_account/$repo) GitHub repository as\n\
[easybuild/easyconfigs/\_\_archive\_\_/<file_with_prefix>](https://github.com/$github_account/$repo/blob/main/easybuild/easyconfigs/__archive__/<file_with_prefix>).\n\
The corresponding module would be <name>/<version>.\n\n
Easyconfig:\n"

#
# Search priorities
# These seem to be multipliers: multiply the number of occurrences on a page with this factor
# to get the actual priority of a page.
#
# EasyConfigs are excluded from the search to avoid building a too large and impractical
# search index. (Alternative: give them a very low priority such as 0.01, but this still
# creates a large search database.) 
#
search_packagelist='0.5'
#search_new='1'     # Hard-coded in whats_new.md
#search_issues='2'  # Hard-coded in known_issues.md
search_package='10'

>&2 echo "Working in repo $repo in $repodir."

#
# Some functions and variables for this section
#

function die () {

    echo "$*" 1>&2
    exit 1

}

#
# create_link
#
# Links a file but first tests if the target already exists to avoid error messages.
#
# Input arguments:
#   + First input argument: The source file
#   + Second and mandatory argument: The target file
#
create_link () {

    #echo "Linking (source file): $1"
    #echo "Linking to (name of the link): $2"
    #test -s "$2" && echo "File $2 found."
    #test -s "$2" || echo "File $2 not found."
    test -s "$2" || ln -s "$1" "$2" || die "Failed to create a $2 (target) linking to $1 (source)."

}

#
# Print a string and indent.
#

indent() {

    # The first call to perl is a trick to remove trailing newlines.
    # The second call to perl adds the indentation to all but the first line.
    echo -e "$2$1" | perl -pe 'chomp if eof' | perl -pe "s|\n|\n$2|" 

}

#
# Extract docs
#
extract_docs() {

    #egrep '#DOC' $1 | sed -e 's|#DOC *||' | tr '\n' ' '
    egrep '#DOC' $1 | sed -e 's|#DOC *||'

}

#
# Print the EasyConfig docs (if any)
#
add_easyconfig_docs () {

    # Input parameters:
    # $1: The (path to the) EasyConfig file
    # $2: The file to print to
    # $3: The indent.

    doccomment="$(extract_docs $1)"
    if [ -n "$doccomment" ]
    then

        # Add the documentation text with 4 spaces of indent.
        indent "$doccomment" "$3" >>$2
        # Then add a newline and empty line
        printf "\n\n"             >>$2

    fi

}

#
# Print the EasyConfig docs (if any) - second variant
#
add_easyconfig_docs_em () {

    # Input parameters:
    # $1: The (path to the) EasyConfig file
    # $2: The file to print to

    doccomment="$(extract_docs $1)"
    if [ -n "$doccomment" ]
    then

        printf "<em>"           >>$2
        # Add the documentation text with 4 spaces of indent.
        indent "$doccomment" "" >>$2
        # Then add a newline and empty line
        printf "</em>\n\n"      >>$2

    fi

}

#
# Create a markdown document for an EasyConfig.
#
easyconfig_to_md () {

    # Input arguments:
    # - $1: The (path to the) EasyConfig file
    # - $2: The (path to the) markdown file. This file will be created or overwritten.
    # - $3: The preamble to be used

    local work
    local easyconfig
    local package
    local package_group
    local version
    local preamble

    easyconfig="${1##*/}"        # Remove everything up to and including the last /
    work="${1%/$easyconfig}"     # work is the relative path to $easyconfig
    package="${work##*/}"        # Extract the last part of that path, the package name.
    work="${work%/$package}"     # Now also remove the package name from the path.
    package_group="${work##*/}"  # Extract again the last part of the path.
    work="${easyconfig%%.eb}"    # work is $easyconfig without the extension,
    version="${work##$package-}" # so we can remove the package name part to get the version

    preamble="${3//<name>/$package}"                 # Substitute the package in the preamble
    preamble="${preamble//<version>/$version}"       # Substitute the version in the preamble
    preamble="${preamble//<easyconfig>/$easyconfig}" # Substitute the easyconfig in the preamble
    preamble="${preamble//<file_with_prefix>/$package_group/$package/$easyconfig}"
    preamble="${preamble//<github_account>/$github_account}"
    preamble="${preamble//<repo>/$repo}"
    
    #
    # Generate the easyconfig file for $package/$version
    #

    echo -e "---\ntitle: $package/$version ($easyconfig) - $package"     >$2
    echo -e "search:\n  exclude: true"                                  >>$2
    echo -e "hide:\n- navigation\n- toc\n---\n"                         >>$2
    echo -e "[[$package]](index.md) [[package list]](../../index.md)\n" >>$2
    echo -e "# $package/$version ($easyconfig)\n"                       >>$2

    add_easyconfig_docs_em $1 $2

    echo -e "$preamble\n"                                               >>$2
    echo -e '``` python'                                                >>$2
    cat $1                                                              >>$2
    echo -e '\n```\n'                                                   >>$2
    echo -e "[[$package]](index.md) [[package list]](../../index.md)"   >>$2
    # Note the extra \n in front of the last ``` as otherwise files that do not end
    # with a newline would cause trouble.

}

#
# Make sure the working directory exists.
#
mkdir -p $gendoc || die "Failed to create the working directory $repodir/$gendoc."

#
# Prepare the structure:
# - Copy the template for the mkdocs.yml file
# - Make the docs subdirectory
# - Link the stylesheets to the docs subdirectory.
# - TO CONSIDER: We may have overrides in the future also. 
# 
[[ -f $gendoc/mkdocs.yml ]] && /bin/rm -f $gendoc/mkdocs.yml
/bin/cp -f config/mkdocs.tmpl.yml $gendoc/mkdocs.yml || die "Failed to copy mkdocs.yml from the template."
echo -e "\nnav:" >>$gendoc/mkdocs.yml

mkdir -p $gendoc/docs

[[ -h $gendoc/mkdocs_lumi ]]      || create_link $repodir/mkdocs_lumi      $repodir/$gendoc/mkdocs_lumi
[[ -h $gendoc/docs/assets ]]      || create_link $repodir/docs/assets      $repodir/$gendoc/docs/assets
[[ -h $gendoc/docs/stylesheets ]] || create_link $repodir/docs/stylesheets $repodir/$gendoc/docs/stylesheets

echo "Searching for files in repo doc."
for file in $(find docs -maxdepth 1 -name "*.md")
do
    echo "Found file $file."
    [[ -h $gendoc/$file ]] || create_link $repodir/$file $repodir/$gendoc/$file
done

#
# Where do we find the EasyConfig files and other documentation?
#
prefix_easyconfigs="${repodir}/easybuild/easyconfigs"

>&2 echo "Easyconfig directory: $prefix_easyconfigs"

#
# Set up the package list file
#
package_list="$gendoc/docs/index.md"

echo -e "---\ntitle: Package overview"                                                                                          >$package_list
echo -e "search:\n  boost: ${search_packagelist}"                                                                              >>$package_list
echo -e "hide:\n- navigation\n---\n"                                                                                           >>$package_list
echo -e "# Package list\n"                                                                                                     >> $package_list
echo -e "Last processed: $(date -u)\n"                                                                                     >> $package_list
echo -e "<span class='lumi-software-smallbutton-userdoc'></span>: Specific user documentation available\n"                     >> $package_list
echo -e "<span class='lumi-software-smallbutton-techdoc'></span>: Technical documentation available\n"                         >> $package_list
echo -e "<span class='lumi-software-smallbutton-archive'></span>: Archived application\n"                                      >> $package_list

#
# Some initialisations
#
last_group='.'

#
# Loop over all packages
#
# Below: Letter p and all special packages as then we have a bit of everything to test.
#for package_dir in $(/bin/ls -1 $prefix_easyconfigs/p/*/*.eb $prefix_easyconfigs/__archive__/p/*/*.eb $prefix_contrib/p/*/*.eb $prefix_contrib/__archive__/p/*/*.eb $prefix_container/p/*/*.eb $prefix_container/__archive__/p/*/*.eb $prefix_other/*/*/*.md | sed -e 's|.*/easyconfigs/\(.*/.*\)/.*\.eb|\1|' | sed -e 's|__archive__/||' sed -e 's|.*/other_packages/\(.*/.*\)/.*\.md|\1|' | sort -uf)
for package_dir in $(/bin/ls -1 $prefix_easyconfigs/*/*/*.eb $prefix_easyconfigs/__archive__/*/*/*.eb \
                     | sed -e 's|.*/easyconfigs/\(.*/.*\)/.*\.eb|\1|' | sed -e 's|__archive__/||' \
                     | sort -uf)
do

	>&2 echo "Processing $package_dir..." 

	# Extract the first letter and the name of the package.
	package=${package_dir##[0-9a-z]/}   # Name of the package.
	group=${package_dir%%/$package}     # A single letter or number, the first subdirectory in which the package subdirectory resides
	
	>&2 echo "Identified group $group, package $package"

    #
    # Check the nature of the package
    #
    is_readme=0    # Variable: Will be set to 1 if a README.md file is available
    is_user=0      # Variable: Will be set to 1 if a USER.md file is available
    is_license=0   # Variable: Will be set to 1 if a LICENSE.md file is available

    is_easyconfig=0           # Variable: Set to 1 if there are active EasyConfigs in the repository for this package
    is_archived_easyconfig=0  # Variable: Set to 1 if there are archived EasyConfigs in the repository for this package
    is_container_easyconfig=0 # Variable: For future use, set to 1 if we detect EasyConfigs to install containers.
    if [ -d $prefix_easyconfigs/$package_dir ]
    then
        [ -f $prefix_easyconfigs/$package_dir/README.md ]                      && is_readme=1
        [ -f $prefix_easyconfigs/$package_dir/$userinfo ]                      && is_user=1  
        [ -f $prefix_easyconfigs/$package_dir/LICENSE.md ]                     && is_license=1
        (( $(find $prefix_easyconfigs/$package_dir -name "*.eb" | wc -l) ))    && is_easyconfig=1
    fi
    if [ -d $prefix_easyconfigs/__archive__/$package_dir ]
    then
        (( $(find $prefix_easyconfigs/__archive__/$package_dir -name "*.eb" | wc -l) )) && is_archived_easyconfig=1
    fi
    is_archived=0
    (( !is_easyconfig && is_archived_easyconfig )) && is_archived=1
    >&2 echo "$package: README: $is_readme, USER: $is_user, LICENSE: $is_license, EB: $is_easyconfig, archived EB: $is_archived_easyconfig."

    #
    # Build the package file
    #
    # - Package file header
    #

    mkdir -p $gendoc/docs/$package_dir
    package_file="$gendoc/docs/$package_dir/index.md"

	echo -e "---\ntitle: $package"                 >$package_file
    echo -e "search:\n  boost: ${search_package}" >>$package_file
	echo -e "hide:\n- navigation\n---\n"          >>$package_file
    echo -e "[[package list]](../../index.md)\n"  >>$package_file
	echo -e "# $package\n"                        >>$package_file
    echostring=""
    (( is_archived )) && echostring="$echostring<span class='lumi-software-button-archivedapp-hover'><span class='lumi-software-button-archivedapp'></span></span>"
    echo -e "$echostring\n"                       >>$package_file

    #
    # - License (if present), priority to the information in the stack, then contrib and finaly other_packages
    #
    if (( is_license ))
    then

        echo -e "## License information\n"                                            >>$package_file
        egrep -v "^# " "$prefix_easyconfigs/$package_dir/LICENSE.md" | sed -e 's|^##|###|'  >>$package_file

        # Make sure there is an empty line at the end of the text added by this block to avoid
        # wrong formatting of subsequent text.
        printf "\n\n"                                                                 >>$package_file

    fi

    #
    # - Software user information (if present)
    #
    if (( is_user ))
    then
        echo -e "## User documentation\n"                                                 >>$package_file
        egrep -v "^# " "$prefix_easyconfigs/$package_dir/$userinfo" | sed -e 's|^##|###|' >>$package_file

        # Make sure there is an empty line at the end of the text added by this block to avoid
        # wrong formatting of subsequent text.
        printf "\n\n"                                                             >>$package_file

        # If there is a files subdirectory, copy the content to the files subdirectory in
        # in the $gendoc tree.
        if [ -d "$prefix_easyconfigs/$package_dir/files" ]
        then
            >&2 echo "Subdirectory $prefix_easyconfigs/$package_dir/files detected, copying data."
            mkdir -p "$gendoc/docs/$package_dir/files" || die "Failed to create $gendoc/docs/$package_dir/files."
            # Note that using quotes below with the * does not work as it turns globbing off
            /bin/cp -r $prefix_easyconfigs/$package_dir/files/* "$gendoc/docs/$package_dir/files/" || 
                die "Failed to copy files from $prefix_easyconfigs/$package_dir/files to $gendoc/docs/$package_dir/files."
        fi
    fi

    #
    # - Centrally installed modules
    #
    if (( is_easyconfig ))
    then

        prefix="$prefix_easyconfigs/$package_dir"

        #
        # Title of the section
        #

        echo -e "## Available modules and corresponding EasyConfigs\n" >>$package_file
        
        work=${package_preamble/<name>/$package}
        echo -e "$work\n"                                              >>$package_file

        #
        # List the modules / EasyConfigs.
        #

        for file in $(/bin/ls -1 $prefix/*.eb | sort -f)
	    do

            easyconfig="${file##$prefix/}"
		    easyconfig_md="$gendoc/docs/$package_dir/${easyconfig/.eb/.md}"

            work=${easyconfig%%.eb}
            version=${work##$package-}

		    >&2 echo "Processing $package/$version, generating $easyconfig_md..."

            #
            # Generate the easyconfig file for $package/$version
            #

            easyconfig_to_md "$file" "$easyconfig_md" "$module_preamble"

            #
            # Add the module / easyconfig to the package file:
            #
            # - Link to the EasyConfig page
            echo -e "-   [$package/$version (EasyConfig: $easyconfig)](${easyconfig/.eb/.md})\n" >>$package_file
            # - #DOC lines, if any
            add_easyconfig_docs $file $package_file "    "

        done # for file in ...

        # Add empty lines at the end of the section
        printf "\n\n"  >>$package_file

    fi # end of if (( is_easyconf ))

    #
    # - Technical information (if present)
    #
    if (( is_readme ))
    then
        echo -e "## Technical documentation\n"                                          >>$package_file
        egrep -v "^# " "$prefix_easyconfigs/$package_dir/README.md" | sed -e 's|^#|##|' >>$package_file
        # Make sure there is an empty line at the end of the text added by this block to avoid
        # wrong formatting of subsequent text.
        printf "\n\n"                                                                   >>$package_file
    fi

    #
    # - Add a list of the archived EasyConfigs
    #
    if (( is_archived_easyconfig ))
    then

        #
        # Title of the section
        #

        echo -e "## Archived EasyConfigs\n" >>$package_file

        if (( is_easyconfig))
        then
            # Text if the package is still available in other configurations.
            echo -e "The EasyConfigs below are additional easyconfigs that are not directly available"  >>$package_file
            echo -e "on the system for installation. Users are advised to use the newer ones and these" >>$package_file
            echo -e "archived ones are unsupported. They are still provided as a source of information" >>$package_file
            echo -e "should you need this, e.g., to understand the configuration that was used for"     >>$package_file
            echo -e "earlier work on the system.\n"                                                     >>$package_file
        else
            # Text if the package is archived
            echo -e "The EasyConfigs below are not directly available on the system for installation."  >>$package_file
            echo -e "They are however still a useful source of information if you want to port the"     >>$package_file
            echo -e "the install recipe to the currently available environments on LUMI.\n"             >>$package_file
        fi

        prefix="$prefix_easyconfigs/__archive__/$package_dir"
        >&2 echo "Checking for archived easyconfigs in $prefix..."

        #
        # List the modules / EasyConfigs.
        #

        for file in $(/bin/ls -1 $prefix/*.eb | sort -f)
	    do

            easyconfig="${file##$prefix/}"  # Extract the filename of the easyconfig out of the $prefix/*.eb name.
		    easyconfig_md="$gendoc/docs/$package_dir/${easyconfig/.eb/.md}" # Compute the location and name for the matching markdown file.

            work=${easyconfig%%.eb}      # Drop the .eb filename extension
            version=${work##$package-}   # Drop the package name part from the extensionless easyconfig file name to compute the version.

		    >&2 echo "Processing $package/$version, generating $easyconfig_md..."

            #
            # Generate the easyconfig file for $package/$version
            #

            easyconfig_to_md "$file" "$easyconfig_md" "$archived_module_preamble"

            #
            # Add the module / easyconfig to the package file
            #
            # - Link to the EasyConfig page
            echo -e "-   [EasyConfig $easyconfig, with module $package/$version](${easyconfig/.eb/.md})\n" >>$package_file
            # - #DOC lines, if any
            add_easyconfig_docs $file $package_file "        "

        done # for file in ...

    fi # end of block to add the title and introduction for the archived easyconfigs.


    #
    # Update the package list
    #
    [[ $group != $last_group ]] && echo -e "## $group\n" >>$package_list
    package_string="-   [$package](${package_file#$gendoc/docs/})"
    (( is_user ))              && package_string="$package_string <span class='lumi-software-smallbutton-userdoc-hover'><span class='lumi-software-smallbutton-userdoc'></span></span>"
    (( is_readme ))            && package_string="$package_string <span class='lumi-software-smallbutton-techdoc-hover'><span class='lumi-software-smallbutton-techdoc'></span></span>"
    (( is_archived ))          && package_string="$package_string <span class='lumi-software-smallbutton-archive-hover'><span class='lumi-software-smallbutton-archive'></span></span>"
    (( is_container_package )) && package_string="$package_string <span class='lumi-software-smallbutton-container-hover'><span class='lumi-software-smallbutton-container'></span></span>"
    echo -e "$package_string\n"                          >>$package_list

    #
    # Add a navigation item if needed.
    #
    [[ $group != $last_group ]] && echo "- $group: index.html#$group" >>$gendoc/mkdocs.yml

    # Set last_group
    last_group=$group

done

#
# Add a navigation items for the other information such as issues and what's new.
#

#echo "- $other_info_label: known_issues.md"  >>$gendoc/mkdocs.yml
#echo "- $whatsnew_label: whats_new.md"  >>$gendoc/mkdocs.yml
