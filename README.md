## Build

This build was tested with Manjaro Linux(5.8.18-1-MANJARO).
To build the program you need to have correctly setup $CHPL_HOME.

Build instruction:

```sh
${CHPL_HOME}/bin/linux64-x86_64/chpl logclustering.chpl
```

## Usage

Command line options:\
[val1|val2|...|valN] - supported values for a option\
[true|false] - value is a boolean
[0.5] - value is a real number\
"str" - value is a string

* --launchType [serial|data_parallel|block_distributed] # Specifier algorithm implementation. Default is 'serial'.
* --printStatistics [true: false] # If true, then prints statistics on found log clusters. Default is false.
* --logLineCount number # Number of lines in the log file. Default is 0.
* --logFilePath "/path/to/log" # Path to the log file. Default is "".
* --similarityThreshold [0.5] # Specifies a fixed threshold threshold to add log into that cluster. Default is 0.5. 
* --fixedWeight [0.5] # Used to calculate weighted sum between log entries. Default is 0.5.
* --nodeCount [4] # Number of computation nodes to used. Default is 4.

To run the algorihm:

```sh
./logclustering --logLineCount 2000 --logFilePath Windows_CBS_Log.log --similarityThreshold 0.4 --launchType=[serial|data_parallel|block_distributed] --printStatistics=[true|false]
```

## Statistics

An example output of a  runned with block-distributed, data-parallel and serial implementations is located in statistics.txt in the root of the current repository.
