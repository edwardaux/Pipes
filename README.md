# Pipes

A looooooong time ago, I used to use a tool on the IBM mainframe called [CMS Pipelines](http://www.vm.ibm.com/pipelines/) that was super useful for processing string records/lines. It was unbelievably powerful in terms of being able to filter and modify records in a stream-like fashion.

This project is a reincarnation of this tool implemented using Swift.

## Overview
Pipes is a tool that passes records (or strings or lines) through multiple stages that can perform actions on the record as it flows through. The world's simplest pipeline looks like:

```
~> pipe "literal hello here | console"
hello there
```

The above pipelines has two stages: `literal` (which produces a record - somewhat like the Unix `echo` command) and `console` (which outputs the record to the screen).

**Important:** Input to the `pipe` command needs to be encapsulated in double quotes lest the `|` character be interpreted by the bash shell as the Unix pipe separator. 

Records (or lines) flow through a pipeline in sequential order. In a typical flow, without specific buffering introduced, a single record will flow all the way from the first stage to the last before the second record will be processed. This makes pipes very efficient in processing large files.  There are some stages that do necessarily introduce buffering (eg. `sort`) in order to perform their function.

**Important:** The record type that is passed between stages is a `String`. All input from files or stdin needs to be representable as a string. This means that Pipes is NOT well suited for processing data that contains binary data like images.

## Examples
### File and console access
The following reads from a file and dumps the content to the console (conceptually the same as `cat /etc/networks`):

```
~> pipe "< /etc/networks | console"
##
# Networks Database
##
loopback	127		loopback-net
```

In a similar way, you can create new files (conceptually the same as `cp /etc/networks /tmp/blah`):

```
~> pipe "< /etc/networks | > /tmp/blah"
~> cat /tmp/blah
##
# Networks Database
##
loopback	127		loopback-net
```

In addition to writing to the console, you can also read from stdin. For example:

```
~> pipe "console | > /tmp/blah"
hello
there
^D
~> cat /tmp/blah
hello
there
~> pipe "console | >> /tmp/blah"
everyone
^D
~> cat /tmp/blah
hello
there
everyone
```

### Running other programs
```
~> pipe "sh echo hi there | cons"
hi there
~> pipe "sh ls /Applications | cons"
1Password 7.app
BBEdit.app
Charles.app
...
```

### Filtering
You can take the first/last few lines (or characters/words/bytes/etc):

```
~> pipe "< /var/log/system.log | take last 3 | cons"
Jan  9 07:34:22 Computer PerfPowerServices[97019]: PerfPowerServices(97019,0x700003b5c000) malloc: malloc_memory_event_handler: stopping stack-logging
Jan  9 07:34:22 Computer PerfPowerServices[97019]: PerfPowerServices(97019,0x700003b5c000) malloc: turning off recording malloc and VM allocation stacks using lite mode
Jan  9 07:34:22 Computer PerfPowerServices[97019]: PerfPowerServices(97019,0x700003c62000) malloc: MallocStackLogging: stack id is invalid. Turning off stack logging
```

Imagine you have a file with the output of `ls -las /Applications`. You can filter records using the `locate` stage:

```
pipe "< input.txt | locate 19.8 /edwardsc/ | cons"
 0 drwxr-xr-x   3 edwardsc  staff     96 17 Nov 07:38 1Password 7.app
 0 drwxrwxr-x@  3 edwardsc  admin     96 29 Oct 10:41 Android Studio.app
 0 drwxrwxr-x   3 edwardsc  staff     96 10 Sep  2019 BBEdit.app
 0 drwxr-xr-x@  3 edwardsc  admin     96  5 Dec  2019 Charles.app
 0 drwxr-xr-x   3 edwardsc  staff     96 26 Nov 17:12 Kaleidoscope.app
 0 drwxr-xr-x   3 edwardsc  staff     96 15 Oct 13:20 Paw.app
 0 drwxr-xr-x   3 edwardsc  staff     96 13 Aug  2019 Reveal.app
```

And you can perform multiple filter actions to refine the output:

```
pipe "< input.txt | locate 19.8 /edwardsc/ | locate 29.5 /staff/ | cons"
 0 drwxr-xr-x   3 edwardsc  staff     96 17 Nov 07:38 1Password 7.app
 0 drwxrwxr-x   3 edwardsc  staff     96 10 Sep  2019 BBEdit.app
 0 drwxr-xr-x   3 edwardsc  staff     96 26 Nov 17:12 Kaleidoscope.app
 0 drwxr-xr-x   3 edwardsc  staff     96 15 Oct 13:20 Paw.app
 0 drwxr-xr-x   3 edwardsc  staff     96 13 Aug  2019 Reveal.app
```

### Reformatting
Imagine you had an input file that looks like:

```
001 John  Smith 555-111-1111
002 Peter Jones 555-222-2222
003 Sally Brown 555-333-3333
```
You could reformat each record to just include the phone numbers:

```
~> pipe "< input.txt | spec 17.12 1 | cons"
555-111-1111
555-222-2222
555-333-3333
```
You could convert the first/last name into CSV and adding a header record (note that assuming people have a single first/last name is generally a [bad idea](https://shinesolutions.com/2018/01/08/falsehoods-programmers-believe-about-names-with-examples/)):

```
~> pipe "< input.txt | spec w2 1 /,/ n w3 n | literal First,Last | cons"
First,Last 
John,Smith
Peter,Jones
Sally,Brown
```
You can reformat based on "fields" separated by a tab, dash, whatever:

```
~> pipe "< input.txt | spec 17.12 1 | spec /(/ 1 fs - f1 n /)/ n f2 nw /./ n f3 n | cons"
(555) 111.1111
(555) 222.2222
(555) 333.3333
```
The above example may need some explanation. The first `spec` stage extracts the phone number itself. The parameters for the second `spec` stage are interpreted as follows:

```
/(/ 1      Outputs the leading parenthesis in column 1
fs -       Sets the "field separator" to be a dash
f1 n       Outputs the first field as the "next" char
/)/ n      Outputs the trailing parenthesis as the "next" char
f2 nw      Outputs the second field as the "next word"
/./ n      Outputs the period as the "next" char
f3 n       Outputs the third field
```
You can change the alignment:

```
~> pipe "< input.txt | spec w2 1.10 right | cons"
      John
     Peter
     Sally
```

### Counting
Counting characters is UTF8-aware.

```
~> pipe "literal abc d 🌍| count bytes chars words lines | cons"
10 7 3 1
```
Counting accumulates across multiple lines and can report the longest/shortest line lengths:

```
~> pipe "literal a|literal bcdef| literal gh | count words lines max min | cons"
3 3 5 1
```
### Sorting
Imagine having the following input:

```
John Smith
Alice Jones
Sally Brown
Peter White
Al Green
Al Brown
John Smith
Sally Brown
```
Sorting can be quite simple:

```
~> pipe "< input.txt | sort | cons"
Al Brown
Al Green
Alice Jones
John Smith
John Smith
Peter White
Sally Brown
Sally Brown
```
Sorting by a particular word (using descending/ascending):

```
~> pipe "< input.txt | sort w2 desc w1 asc | cons"
Peter White
John Smith
John Smith
Alice Jones
Al Green
Al Brown
Sally Brown
Sally Brown
```

Duplicates can be filtered out:

```
~> pipe "< input.txt | sort unique | cons"
Al Brown
Al Green
Alice Jones
John Smith
Peter White
Sally Brown
```
Or indeed counted:

```
~> pipe "< input.txt | sort count | cons"
         1Al Brown
         1Al Green
         1Alice Jones
         2John Smith
         1Peter White
         2Sally Brown
```

### Multi-stream pipelines
Where things get really powerful, though, is when we start using multi-stream pipes. Some stages have the ability to send/receive records from other streams. For example, if `locate` has a secondary stream attached, it will send the non-matched records to the secondary stream where they can be dealt with independently.

For example, consider the following input file:

```
Employee,John Smith
Manager,Alice Jones
Employee,Sally Brown
Employee,Peter White
Manager,Al Green
Manager,Al Brown
```

We could split these records into separate files using something like:

```
~> pipe "(end ?) < input.txt | l: locate 1.7 /Manager/ | > mgr.txt ? l: | > emp.txt"
```
In this case, we're using the newly defined `(end ?)` option to specify that the `?` character signifies the end of the current pipe and the start of a new one. The `l:` label is used to route the secondary output from `locate` into the second pipeline whose only action is to write to `emp.txt`. While the above example merely writes the records into files, there's no reason why additional manipulation could not be specified.

In fact, the following invocation shows an example where the records are split by manager/employee (per above), but each row undergoes its own specific manipulation before being rejoined together again. Specifically, the manager rows have a bonus of $1,000 appended to each row, whereas the employee rows only get $500 appended.

Note that there's also another `f:` label that re-routes the records from the second pipeline back into the `faninany` stage in the first pipeline. NB: there's no significance ascribed to what letters are used for the labels. Readability tends to suggest using the first character of the participating stage (eg. `l=locate, f=faninany`), but it is not required.

```
~> pipe "(end ?) < input.txt | l: locate 1.7 /Manager/ | spec 1-* 1 /,1000/ n | f: faninany | cons ? l: | spec 1-* 1 /,500/ n | f: "
Employee,John Smith,500
Manager,Alice Jones,1000
Employee,Sally Brown,500
Employee,Peter White,500
Manager,Al Green,1000
Manager,Al Brown,1000
```


## Installation
### Executable
The easiest way to install is to use Homebrew. If you already have homebrew installed, you can just run:

```
brew install edwardaux/formulae/pipes
```

Alternatively, if you prefer to install from source, you can download from Github and run the following command which will install into `/usr/local/bin`:

```
make install
```

### Library
While this project is mostly designed to be used as a standalone executable, it is possible to embed as an SPM module by pointing to:

```
https://github.com/edwardaux/Pipes.git
```
Some example code of using the Swift library is as follows:

```
try Pipe()
    .add(Literal("hi there"))
    .add(Console())
    .run()
```
You can additionally write your own stages by subclassing `Stage` and overriding `run()`:

```
class TestStage: Stage {
    override public func run() throws {
        while true {
            // peek for any incoming records
            let record = try peekto()
            // reverse it
            let reversed = String(record.reversed())
            // output to next stage
            try output(reversed)
            // consume input record and unblock previous stage
            _ = try readto()
        }
    }
}

try Pipe()
    .add(Literal("hi there"))
    .add(ReverseStage())
    .add(Console())
    .run()
```

## Change Log
### 1.0
* Initial release
* Supported stages:
    * command
    * cons
    * count
    * diskr
    * diskw
    * diskwa
    * fanin
    * faninany
    * fanout
    * help
    * hole
    * literal
    * lookup
    * locate
    * nlocate
    * sort
    * spec
    * take

### 1.1
* Added  `lookup` stage

### 1.2
* Added `drop` stage
* Added `regex` stage

## Prioritization
While the current release is very stable and has a respectable number of included stages, there are a number of additional features that I plan to add over time. A rough roadmap is as follows:

### Release 2.0
* URLEncode / URLDecode
* 64Encode / 64Decode
* JSON
* Pad
* Split
* Change
* DateConvert
* FrLabel / ToLabel
* Inside / NotInside (see Outside)
* curl

### Release 3.0
*  Stall detection
*  Addpipe
*  Callpipe
*  Beat
*  Between
*  Buffer
*  Chop
*  Cipher
*  Collate
*  Copy
*  Deal
*  Diskback
*  Duplicate
*  Gate
*  GetFiles
*  Hostid
*  Hostname
*  Join
*  Overlay
*  Reverse
*  Stem
*  Strip
*  StrLiteral
*  Timestamp
*  Tokenise
*  Unique
*  Xlate
