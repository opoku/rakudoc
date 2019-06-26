use P6doc;

package P6doc::CLI {
	use MONKEY-SEE-NO-EVAL;

	my $PROGRAM-NAME = "p6doc";
	constant INDEX = findbin().add('index.data');

	proto MAIN(|) is export {
		{*}
	}

	# if usage is changed please also update doc/Programs/02-reading-docs.pod6
	sub USAGE() {
		say "You want to maintain the index?";
		say "To build an index for '$PROGRAM-NAME -f'";
		say "          $PROGRAM-NAME build";
		say "\nTo list the index keys";
		say "          $PROGRAM-NAME list";
		say "\nTo display module name(s) containing key";
		say "          $PROGRAM-NAME lookup";
		say "\nTo show where the index file lives";
		say "          $PROGRAM-NAME path-to-index";

		say "\nWhat documentation do you want to read?";
		say "Examples: $PROGRAM-NAME Str";
		say "          $PROGRAM-NAME Str.split";
		say "          $PROGRAM-NAME faq";
		say "          $PROGRAM-NAME path/to/file";
		say "\nSet the POD_TO_TEXT_ANSI if you want to use ANSI escape sequences to enhance text";

		say "\nYou can list some top level documents:";
		say "          $PROGRAM-NAME -l";

		say "\nYou can also look up specific method/routine/sub definitions:";
		say "          $PROGRAM-NAME -f hyper";
		say "          $PROGRAM-NAME -f Array.push";

		say "\nYou can bypass the pager and print straight to stdout:";
		say "          $PROGRAM-NAME -n Str";
	}

	multi MAIN(Bool :h(:$help)?) {
		exit;
	}

	multi sub MAIN('list') {
		if INDEX.IO.e {
			my %data = EVAL slurp INDEX;
			for %data.keys.sort -> $name {
				say $name
				#    my $newdoc = %data{$docee}[0][0] ~ "." ~ %data{$docee}[0][1];
				#    return MAIN($newdoc, :f);
			}
		} else {
			say "First run   $*PROGRAM-NAME build    to create the index";
			exit;
		}
	}

	multi sub MAIN('lookup', $key) {
		if INDEX.IO.e {
			my %data = EVAL slurp INDEX;
			die "not found" unless %data{$key};
			say %data{$key}.split(" ").[0];
		} else {
			say "First run   $*PROGRAM-NAME build    to create the index";
			exit;
		}
	}

	multi sub MAIN($docee, Bool :$n) {
		return MAIN($docee, :f, :$n) if defined $docee.index('.');

		put get-docs(locate-module($docee).IO, :package($docee));
	}

	multi sub MAIN($docee, Bool :$f!, Bool :$n) {

		my ($package, $method) = $docee.split('.');
		if ! $method {

			if not INDEX.IO.e {
				say "building index on first run. Please wait...";
				build_index(INDEX);
			}

			my %data = EVALFILE INDEX;

			my $final-docee = disambiguate-f-search($docee, %data);

			# NOTE: This is a temporary fix, since disambiguate-f-search
			#       does not properly handle independent routines right now.
			if $final-docee eq '' {
				$final-docee = ('independent-routines', $docee).join('.');
			}

			($package, $method) = $final-docee.split('.');

			my $m = locate-module($package);

			put get-docs($m.IO, :section($method), :$package);
		} else {
			my $m = locate-module($package);

			put get-docs($m.IO, :section($method), :$package);
		}
	}

	multi sub MAIN(Bool :$l!) {
		my @paths = search-paths() X~ <Type/ Language/>;
		my @modules;
		for @paths -> $dir {
			for dir($dir).sort -> $file {
				@modules.push: $file.basename.subst( '.'~$file.extension,'') if $file.IO.f;
			}
		}
		@modules.append: list-installed().map(*.name);
		.say for @modules.unique.sort;
	}

	multi sub MAIN(Str $file where $file.IO.e, Bool :$n) {
		put get-docs($file.IO);
	}

	# index related
	multi sub MAIN('path-to-index') {
		say INDEX if INDEX.IO.e;
	}

	multi sub MAIN('build') {
		build_index(INDEX);
	}

}