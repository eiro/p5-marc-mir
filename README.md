# What is MARC::MIR

The current repo comes with 2 things that must be clearly seperated at some
point: 

* A specification of in memory, [acmeic](http://acmeism.org/)
  representation of MARC records.
* A Perl implementation of this spec. with
  * a very fast ISO2709 serialization/deserialization module
  * very nice set of helpers that make MIR manipulations very easy. 

see lib/MARC/MIR/Tutorial.pod for futher informations. 

# MARC::MIR out of the Perl world

* [MARC::MIR python port](https://github.com/agrausem/pyromarc)
  was written during [pycon.fr 2013](http://www.pycon.fr/2013/). I also seen a
  proto of the MARC::MIR::Template port. 

* I wrote (and have to release) a port of MARC::MIR in ... java :) because it
  was an excuse to learn about NIO2 and it would give us opportunity to use MIR
  from [clojure](http://clojure.org) and [Perl6](http://perl6.org).
  As i have no usage of MARC::MIR anymore, motivation is hard to find.

# Quo vadis, MARC::MIR ?

First steps of this project came fast and promising before it was discontinued
about 2 years ago (last CPAN release in 2013 january).

* All those code were preliminaries of a big project to merge 4 ILS at
  Strasbourg University. This project was canceled as the university decided to 
  use commercial solutions to achieve this work.

* Since then, i occasionally work on MARC records and MARC::MIR is usable
  enough.

* I didn't have the occasion to work directly with librarians to setup a
  complex use case and ensure the whole toolchain can be used without the help
  of a programmer

* As i really expect MARC (as well as some librarians) to die, i had no
  interest on working on this project. even on spare time. 

So if someone want to take over my modules, please feel free. Also, there are 2
ways to increase my own motivation:

* invite me to a workshop with some librarians to work on usecases
  (the mechanics is in good enough shape to come to the battlefield)
* donate or hire me as contractor (the whole todo list, including
  documentations and test suites, is about 1 full-time month, some tasks are
  just few hours).

## Todo

* make a clear separation between specs and implementation 
* complete the reference documentation 
* write/improve tutorials
* complete test suites
  * it SHOULD be done an acmeic way
  * it MUST be battle tested in the case of records written
    from scratch (as it's the case i almost never had to handle)
* finish canceled projects

## Canceled projects

## normalize, validate and query MARC records

As a MIR is just an array of array, very simple validations can be written
using any existing tool which can query/validate a datastructure. I gave 
[Kwalify](http://www.kuwata-lab.com/kwalify/ruby/users-guide.01.html) a try,
you can find the [eg/validate](documented source).

Although, some other pages deserve further reads and tests:

* [rx](http://rx.codesimply.com/)
* [json-schema](http://json-schema.org)
  * ([perl implementation](https://metacpan.org/pod/JSON::Schema))
  * [quick ref from npm](https://www.npmjs.org/package/json-gate)
  * with interesting disgressions like [metawidget](http://metawidget.org/)
* [jsonary](http://jsonary.com/)
* [JSON validation combinators](http://ro-che.info/articles/2014-04-20-json-validation-combinators.html)

But i guess this method would consume a lot of ressources to validate or query
a large set. Plus, rules can be really boring to write if you come with some
cases rarely seen out of the MARC world. What it you want to find a title
matching "rome", "romulus" or "remus" (assuming title
can be `200$a`, `200$b` or `200$c`).

For those range of problems, i use MARC::MIR helpers directly from Perl

    use MARC::MIR;
    use Perlude;

    sub keep_roman_books {
        print if 
                grep $_
                , map_values { /rome|romulus|remus/ }
                    [ 200, [qw( a b c )] ]
                    ,  from_iso2709
    }

Also i can't expect librarians to do so. that's why we need more tools whom

* MUST be [acmeic](http://acmeism.org/)
  (usable from any technology or programming langage)
* MUST be GUI driven (it would be possible to write rules from a web interface)
* MAY come with a DSL: intensive users may probably go crazy with web
  interfaces.
  
S-expr would be perfect. not only because it will be very easy to implement and
port but also because it would be a very pleasant to read and edit 


    (any 200$[abc] (~ "rome|romulus|remus"))

Both GUI and DSL would store a query as a datastructure that can be used by
validation tools. The first to come idea would be (written in YAML). 

    any:
      - field: 200
      - subfield: [a, b, c]
      - value: [match, "rome|romulus|remus" ]

I made [a lightning talk](https://www.youtube.com/watch?v=hHnq-mVK-cg)
of a prototype during the
[French Perl Workshop 2013](http://journeesperl.fr/fpw2013/)
and a nicer version i now use daily for other purposes is 
[in my github](https://github.com/eiro/labo/blob/master/parsing_with_perl/sexpr_parser.pl).

## ISO-5426 from/to UTF-8

I wrote a
[ICU Unicode Charmap](https://github.com/eiro/p5-encode-iso5426/blob/master/iso-5426.ucm)
and tested it using Perl encoding system. It was very fast but we had to deal 
with some unexpected symbols so i didn't release the whole thing.

Now it's pretty clear unexpected symbols come from our ILS extension of the charmap. 
We came to the idea to write a 'ISO-5426-loose-unistra' table but we never took time for it.

## MARC::MIR::Template

[MARC::MIR::Template](https://github.com/eiro/p5-marc-mir-template) works very
well if you don't care about field indicators. I never had to deal with those
indicators so "it worked for me".

Also, there is a known bug but i documented the work around and never got time
to investigate on it. I wrote a test in a suite that can be uncommented in the
case someone fix it. 
