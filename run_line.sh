#!/bin/sh

echo "Starting compilation..."
${CHPL_HOME}/bin/linux64-x86_64/chpl logclustering.chpl

if [[ $? -eq 0 ]]; then
	echo "Done..."
	echo "Running..."
	./logclustering --logLineCount 2000 --logFilePath Windows_CBS_Log.log --similarityThreshold 0.4 --launchType=block_distributed --printStatistics=true
else
	echo "Compilation Failed..."
fi

