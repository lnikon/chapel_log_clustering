use IO;
use List;
use Assert;
use BlockDist;

// Config vars
config const launchType: string = "serial";
config const printStatistics: bool = false;
config const logLineCount: int = 0;
config const logFilePath: string = "";
config const similarityThreshold: real = 0.5;
config const fixedWeight: real = 0.5;

const Space = {0..logLineCount};
const BlockSpace = Space dmapped Block(boundingBox=Space);
var BA: [BlockSpace] string;

proc minimum(a: int, b: int, c: int) {
  var min = a;
  if a > b {
    min = b;
  }

  if min > c {
    min = c;
  }

  return min;
}

proc levenshteinDistance(a: string, b: string) {
  var m = a.size;
  var n = b.size;

  var distanceSpace = {0..m, 0..n};
  var distanceMatrix: [distanceSpace] int;
  for (i, j) in distanceSpace {
    distanceMatrix[i, j] = 0;
  }

  for j in {1..n} {
    d[0, j] = j;
  }

  var substitutionCost: int = 0;
  for j in {1..n} {
    for i in {1..m} {
      if a[i] == b[j] {
        substitutionCost = 0;
      } else {
        substitutionCost = 1;
      }

      distanceMatrix[i, j] = minimum(d[i-1, j] + 1, d[i, j-1] + 1, d[i-1, j-1] + substitutionCost);
    }
  }

  return distanceMatrix[m, n];
}

proc readLogTokenizedBlockedDistributed(path: string, lineCount: int, printResult: bool = false) {
  assert(path.size != 0);

  var logFile = open(path, iomode.r);
  var readingChannel = logFile.reader();

  var logLine: string;
  var logLineIndex: int = 0;
  while readingChannel.readline(logLine) && logLineIndex != logLineCount {
    if logLine.size == 0 {
      logLineIndex += 1;
      continue;
    }

    BA[logLineIndex] = logLine;
    logLineIndex += 1;
  }

  if printResult {
    writeln(BA);
  }

}

proc readLogTokenized(path: string, lineCount: int, printResult: bool = false) {
  assert(path.size != 0);

  var logFile = open(path, iomode.r);
  var readingChannel = logFile.reader();

  var logMatrix: [0..lineCount] string;
  var logLine: string;
  var logLineIndex: int = 0;
  while readingChannel.readline(logLine) && logLineIndex != logLineCount {
    if logLine.size == 0 {
      logLineIndex += 1;
      continue;
    }

    logMatrix[logLineIndex] = logLine;
    logLineIndex += 1;
  }

  if printResult {
    writeln(logMatrix);
  }

  return logMatrix;
}

proc metric(lhs: string, rhs: string) {
  if lhs == rhs {
    return 1;
  }

  return 0;
}

proc gowerIndexWithFixedWeight(lhs: list[string], rhs: list[string]) {
  assert(lhs.size != 0);
  assert(rhs.size != 0);

  var sum: real = 0.0;
  var len: int = lhs.size;
  if (rhs.size < len) {
    len = rhs.size;
  }

  for idx in 0..#len {
    sum += fixedWeight * metric(lhs[idx], rhs[idx]);
  }

  return sum / lhs.size;
}

record Cluster {
  var logs: list[string];

  proc isSimilarTo(log: string) {
    if logs.isEmpty() {
      return false;
    }

    var lhs: list[string];
    var rhs: list[string];

    for token in log.split(" ") {
      lhs.append(token);
    }

    for token in logs.first().split(" ") {
      rhs.append(token);
    }

    return gowerIndexWithFixedWeight(lhs, rhs) > similarityThreshold;
  }

  proc append(log: string) {
    logs.append(log);
  }

  proc count() {
    return logs.size;
  }

  proc at(ind: int) {
    return logs[ind];
  }

  proc printLogs() {
    writeln(logs);
  }
}

proc clusterSerial() {
  var logMatrix = readLogTokenized(logFilePath, logLineCount);
  var clusters: list[Cluster];
    for log in logMatrix {
        var foundCluster: bool = false;
        for cluster in clusters {
            foundCluster = cluster.isSimilarTo(log);
            if foundCluster {
                cluster.append(log);
                break;
            }
        }

        if !foundCluster {
            var cluster = new Cluster();
            cluster.append(log);
            clusters.append(cluster);
        }
    }

    return clusters;
}

proc clusterDataParallel() {
    var logMatrix = readLogTokenized(logFilePath, logLineCount);
    var clusters: list[Cluster];
    forall log in logMatrix with (ref clusters) {
        var foundCluster: bool = false;
        for cluster in clusters {
            foundCluster = cluster.isSimilarTo(log);
            if foundCluster {
                cluster.append(log);
                break;
            }
        }

        if !foundCluster {
            var cluster = new Cluster();
            cluster.append(log);
            clusters.append(cluster);
        }
    }

    return clusters;
}

proc clusterBlockDistributed() {
    readLogTokenizedBlockedDistributed(logFilePath, logLineCount);
    var clusters: list[Cluster];
    forall logIdx in BlockSpace with (ref clusters) {
        var log = BA[logIdx];
        var foundCluster: bool = false;
        for cluster in clusters {
            foundCluster = cluster.isSimilarTo(log);
            if foundCluster {
                cluster.append(log);
                break;
            }
        }

        if !foundCluster {
            var cluster = new Cluster();
            cluster.append(log);
            clusters.append(cluster);
        }
    }

    return clusters;
}

proc driver() {
    writeln("Log file path: ", logFilePath);
    writeln("Log line count: ", logLineCount);

    var clusters: list[Cluster];
    if launchType == "serial" {
        clusters = clusterSerial();
    } else if launchType == "data_parallel" {
        clusters = clusterDataParallel();
    } else if launchType == "block_distributed" {
        clusters = clusterBlockDistributed();
    } else {
        writeln("Error: Unkown launch type specified: ", launchType);
        return;
    }

    if printStatistics {
        writeln("==================== Statistics ====================");
        writeln("Method: ", launchType);
        writeln("Clusters found: ", clusters.size);
        writeln("Logs in each cluster: ");
        // for cluster in clusters {
        //     writeln(cluster.count());
        //     writeln("Printing several random entries: ");
        //     // write("[ ");
        //     // for i in 0..9 {
        //     //     if i < cluster.count() {
        //     //         writeln(cluster.at(i));
        //     //     }
        //     //     write(", ");
        //     // }
        //     // writeln("]");
        // }
        writeln("====================================================");
    }
}

driver();
