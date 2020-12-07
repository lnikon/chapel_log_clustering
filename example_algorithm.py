def compare(cluster, log_line):
    if len(log_line) > len(cluster):
        return 0.5
    return 0.1


def generate_initial_threshold(strategy):
    if strategy == 1:
        return 0.3
    elif strategy == 2:
        return 0.5
    else:
        return 0.9


def cluster_logs(logs):
    clusters = [[]]
    thresholds = []
    log_thresholds = []
    for log_idx, log in enumerate(logs):
        current_cluster = []
        found_cluster = False
        for cluster_idx, cluster in enumerate(clusters):
            current_cluster = cluster
            log_threshold = compare(current_cluster, log)
            if log_threshold > thresholds[cluster_idx]:
                current_cluster.append(log)
                log_thresholds[log_idx] = log_threshold
                found_cluster = True

                # Update threshold for a cluster
                sum_of_thresh = 0
                for log_from_cluster in current_cluster:
                    sum_of_thresh += thresholds[log_from_cluster]

                thresholds[log_from_cluster] = sum_of_thresh / \
                    len(current_cluster)

                break

        if not found_cluster:
            new_threshold = generate_initial_threshold(current_cluster)
            thresholds.append(new_threshold)

            current_cluster.append(log)
            clusters.append(current_cluster)

            log_thresholds[log] = new_threshold
            # Update cluster threshold based after new element
