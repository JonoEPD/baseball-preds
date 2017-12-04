# script to stack features for batting/pitching into one vector per player (covers 6 years)
import csv

# import batting features and assign to dict
pitching_dict = {}
volume_features = 21
ratio_features = 18
total_features = volume_features + ratio_features
headers = [] # cache list of headers
with open('pitching.csv') as f:
    pitching = csv.reader(f, delimiter=',')
    headers = next(pitching, None)[2:]
    for row in pitching:
        player_id = row[0]
        year_num = row[1]
        # assign row to dictionary entry keyed by player_id and year #. cast all to float
        pitching_dict[player_id + '_' + str(year_num)] = list(map(float,row[2:]))

# get list of all unique players in dict
pitcher_list = list(set(list(map(lambda x: x[:-2], pitching_dict.keys()))))

# import yearly means for pitching features and assign to dict
with open('pitching_means.csv') as f:
    bya = csv.reader(f, delimiter=',')
    b_headers = next(bya, None)
    for row in bya:
        year = row[0]
        pitching_norms = list(map(float,row))

# build up stacked feature vector for each player
pitching_features = {}
years = list(map(str,[0,1,2,3,4,5]))
for player in pitcher_list:
    x = []
    for year in years:
        features = []
        iden = player + '_' + year
        try:
            features = pitching_dict[iden]
        except KeyError:
            # lookup year from players first if we can't find them
            start_id = player + '_0'
            start_year = pitching_dict[start_id][0]
            year = start_year + int(year)
            features.append(year)
            features.extend([0] * volume_features) # append 0s for 20 aggregate features
            features.extend([-1] * ratio_features) # append -1s for 19 ratio features
        x.extend(features)
    pitching_features[player] = x

# rebuild stacked feature vector w/ relative means
# -1 gets assigned to mean (flags "missing ratio")
pitching_rf = {}
i_count = 0
for player, features in pitching_features.items():
    x = []
    for ynum in range(6):
        offset = (total_features+1)*ynum # get starting index for a year's worth of data
        year = features[offset]
        x.append(year)
        #norms = pitching_norms[str(int(year))]
        for i in range(total_features):
            idx = i + offset + 1
            val = features[idx]
            norm = pitching_norms[i]
            if val < -0.1: # flag -1s
                x.append(norm)
                i_count += 1
            else:
                x.append(val)
    pitching_rf[player] = x

# get list of all column headers
stacked_headers = ['player_id']
for ynum in range(6):
    for header in headers:
        label = str(header) + '-' + str(ynum)
        stacked_headers.append(label)

# write results to csv
with open('stacked_pitching_features.csv','w') as f:
    writer = csv.writer(f, delimiter = ',')
    writer.writerow(stacked_headers)
    for player, features in pitching_rf.items():
        features.insert(0, player) # put player_id at start of feature list
        writer.writerow(features)

